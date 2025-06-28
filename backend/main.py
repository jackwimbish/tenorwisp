import os
import json
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
import openai
from sentence_transformers import SentenceTransformer
import hdbscan
import numpy as np

# Load environment variables from a .env file (for local development)
load_dotenv()

# --- Firebase Admin SDK Initialization ---
try:
    print("Initializing Firebase...")
    service_account_json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if service_account_json_str:
        # Production: From environment variable on Railway
        print("   - Using service account from environment variable.")
        service_account_info = json.loads(service_account_json_str)
        cred = credentials.Certificate(service_account_info)
    else:
        # Development: From local file path in .env
        print("   - Using service account from local file path (GOOGLE_APPLICATION_CREDENTIALS).")
        # This automatically finds the credentials from the GOOGLE_APPLICATION_CREDENTIALS
        # environment variable loaded by load_dotenv().
        if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
             raise ValueError("GOOGLE_APPLICATION_CREDENTIALS not set for local development.")
        cred = credentials.ApplicationDefault()

    firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized successfully.")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    # Exit if Firebase fails to initialize, as it's critical
    exit()

# --- AI Model Initialization ---
# Load models once when the server starts to avoid reloading on every request
vectorizer = None
try:
    print("Loading Sentence Transformer model...")
    vectorizer = SentenceTransformer('all-MiniLM-L6-v2')
    print("✅ Model loaded.")

    print("Initializing OpenAI API...")
    openai.api_key = os.getenv("OPENAI_API_KEY")
    if not openai.api_key:
        raise ValueError("OPENAI_API_KEY environment variable not set.")
    print("✅ OpenAI API initialized.")
except Exception as e:
    print(f"❌ Error during model initialization: {e}")
    # We can choose to exit or let the app run without AI models
    # For this app, the models are critical, so we'll print the error and continue
    # The endpoint logic will handle the case where the vectorizer is None.
    pass


# --- App Configuration ---
app = FastAPI(
    title="AI Topic Generator API",
    description="Backend service for processing submissions and generating topics.",
    version="0.1.0",
)

# --- Security: API Key Authentication ---
API_KEY_NAME = "X-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

# This is where we'll get the actual API key from our environment variables
# On Railway, you will set this in the service variables.
SECRET_KEY = os.getenv("BACKEND_SECRET_KEY", "default_secret_for_local_dev")

async def get_api_key(api_key: str = Depends(api_key_header)):
    """Dependency function to validate the API key."""
    if api_key == SECRET_KEY:
        return api_key
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API Key",
        )

# --- API Endpoints ---
@app.get("/")
def read_root():
    """Root endpoint to check if the server is running."""
    return {"status": "Server is running"}

# THIS IS OUR MAIN ENDPOINT FOR THE DEMO
@app.post("/api/admin/start_generation_round", dependencies=[Depends(get_api_key)])
async def trigger_generation_round():
    """
    An admin-only endpoint to manually trigger the topic generation process.
    """
    print("✅ Admin trigger received! Starting topic generation process...")

    if not vectorizer:
        print("❌ AI models not loaded. Aborting process.")
        raise HTTPException(status_code=500, detail="AI models are not available.")

    # 1. Fetch live submissions from Firestore
    db = firestore.client()
    submissions_to_process = []

    try:
        print("1. Fetching live submissions from Firestore...")
        live_submissions_ref = db.collection('submissions').where('status', '==', 'live')
        docs = live_submissions_ref.stream()

        for doc in docs:
            doc_data = doc.to_dict()
            # Basic validation to ensure the submission has the required data
            if doc_data.get("submissionText") and doc_data.get("author_uid"):
                submissions_to_process.append({
                    "id": doc.id,
                    "text": doc_data.get("submissionText"),
                    "author_uid": doc_data.get("author_uid")
                })

        if not submissions_to_process:
            print("   - No live submissions found. Exiting process.")
            return {"status": "success", "message": "No live submissions to process."}

        print(f"   - Found {len(submissions_to_process)} submissions to process.")

    except Exception as e:
        print(f"❌ Error fetching submissions: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch from Firestore.")


    # 2. Analyze: Vectorize submissions and cluster them
    print("2. Analyzing submissions...")
    try:
        # Extract just the text for vectorization
        texts = [sub['text'] for sub in submissions_to_process]

        # Vectorize the text
        print("   - Vectorizing texts...")
        embeddings = vectorizer.encode(texts)

        # Cluster the embeddings
        # min_cluster_size is a key parameter to tune. A smaller value finds more, smaller topics.
        print("   - Clustering vectors...")
        clusterer = hdbscan.HDBSCAN(min_cluster_size=3, metric='euclidean', gen_min_span_tree=True)
        cluster_labels = clusterer.fit_predict(embeddings)

        # Group submissions by their new cluster label
        clustered_submissions = {}
        for i, label in enumerate(cluster_labels):
            if label == -1:
                continue  # Ignore noise points
            if label not in clustered_submissions:
                clustered_submissions[label] = []
            clustered_submissions[label].append(submissions_to_process[i])
        
        if not clustered_submissions:
            print("   - Analysis complete, but no significant clusters were found. Exiting.")
            return {"status": "success", "message": "Analysis complete, but no clusters were formed."}

        print(f"   - Identified {len(clustered_submissions)} clusters (excluding noise).")

    except Exception as e:
        print(f"❌ Error during AI analysis: {e}")
        raise HTTPException(status_code=500, detail="An error occurred during AI analysis.")

    # 3. Generate: For top clusters, use LLM to create thread title and post
    # 4. Publish & Archive: Write new threads and archive old submissions atomically

    return {"status": "success", "message": "Topic generation process completed."} 