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
    print("3. Generating content for top clusters...")

    # Sort clusters by size to process the most popular topics
    sorted_clusters = sorted(clustered_submissions.items(), key=lambda item: len(item[1]), reverse=True)

    # Process the top 3 clusters (or fewer if there aren't that many)
    for cluster_id, submissions_in_cluster in sorted_clusters[:3]:
        print(f"   - Processing cluster {cluster_id} with {len(submissions_in_cluster)} members...")

        # Consolidate text for the LLM prompt
        consolidated_text = "\\n---\\n".join([sub['text'] for sub in submissions_in_cluster])

        # Build a detailed prompt using the OpenAI Chat Completions format
        system_prompt = "You are a community moderator. Your goal is to synthesize user ideas into engaging discussion topics."
        user_prompt = (
            "Based on the following user thoughts, all centered on a similar theme, perform two tasks:\n"
            "1. Create a single, neutral, open-ended discussion question that captures the core idea.\n"
            "2. Write a short, engaging initial post to kick off the thread, referencing the collective thought.\n\n"
            "The user thoughts are:\n"
            "---\n"
            f"{consolidated_text}\n"
            "---\n\n"
            'Format your entire response as a single, valid JSON object with two keys: "title" and "initial_post".'
        )

        try:
            # Generate content using OpenAI's API
            response = openai.chat.completions.create(
                model="gpt-4.1-2025-04-14",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                response_format={"type": "json_object"}  # Use JSON mode for reliable output
            )

            # The response content is a JSON string, so we parse it.
            response_content = response.choices[0].message.content
            generated_content = json.loads(response_content)
            thread_title = generated_content['title']
            initial_post_text = generated_content['initial_post']

            print(f'     - Generated Title: "{thread_title}"')

            # 4. Publish: Atomically create the new thread and its starter post
            # We will also archive all the submissions used to create this thread.
            print("   - Writing new thread to Firestore and archiving submissions...")
            
            # Start a batched write for atomic operations
            batch = db.batch()

            # Create the new document in `public_threads`
            new_thread_ref = db.collection('public_threads').document()
            batch.set(new_thread_ref, {
                'title': thread_title,
                'generatedAt': firestore.SERVER_TIMESTAMP  # Add timestamp for sorting
            })

            # Create the initial post in the `posts` sub-collection
            initial_post_ref = new_thread_ref.collection('posts').document()
            batch.set(initial_post_ref, {
                'postText': initial_post_text,
                'author_uid': None, # Explicitly null for AI posts
                'author_username': 'Thread Starter',
                'author_photoURL': "https://api.dicebear.com/8.x/bottts/svg", # A generic bot icon
                'createdAt': firestore.SERVER_TIMESTAMP # Add timestamp for sorting
            })

            # 5. Archive: Mark all processed submissions as "archived"
            # and clear the user's live_submission_id
            for sub in submissions_in_cluster:
                sub_ref = db.collection('submissions').document(sub['id'])
                batch.update(sub_ref, {'status': 'archived'})

                # Also update the corresponding user's profile
                user_ref = db.collection('users').document(sub['author_uid'])
                batch.update(user_ref, {'live_submission_id': None})

            # Commit the entire batch of operations
            try:
                batch.commit()
                print(f"   - ✅ Successfully published thread and archived {len(submissions_in_cluster)} submissions.")
            except Exception as e:
                print(f"   - ❌ Error committing batch for cluster {cluster_id}: {e}")
                # If the batch fails, we should continue to the next cluster
                continue

        except (json.JSONDecodeError, KeyError, openai.APIError) as e:
            print(f"     - ❌ Error processing LLM response for cluster {cluster_id}: {e}")
            continue  # Skip to the next cluster if one fails


    return {"status": "success", "message": "Topic generation process completed."} 
