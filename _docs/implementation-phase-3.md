### **Goal: Implement the backend's data processing pipeline.**

By the end of this phase, your manually-triggered backend will be able to read all live user submissions, understand them, generate new public threads from them, and clean up by archiving the processed data.

### **Prerequisites**

* Phase 1 and Phase 2 are complete.  
* Your create_fake_users.py and generate_submissions.py scripts are ready for seeding your database with test data.  
* You have an **OpenAI API key**.

### **Step 1: Enhance the Backend Environment**

First, we need to add all the necessary AI/ML libraries to your backend's requirements.

**A. Update backend/requirements.txt**

Add the new libraries for data processing and AI.

# Web server  
fastapi  
uvicorn  
python-dotenv

# Firebase  
firebase-admin

# AI & Data Processing  
sentence-transformers  
hdbscan  
numpy  
openai

**B. Update Railway Variables**

Go to your service's "Variables" tab on Railway and add the API key for the LLM.

* **Name:** OPENAI_API_KEY  
* **Value:** Paste your actual OpenAI API key.

### **Step 2: Structure the Main Processing Logic**

Now, we'll flesh out the trigger_generation_round function in backend/main.py. This provides a clear structure for the steps we'll implement.

# backend/main.py

# ... (imports from Phase 1)  
import firebase_admin  
from firebase_admin import firestore  
import openai  # <-- CHANGE  
from sentence_transformers import SentenceTransformer  
import hdbscan  
import numpy as np

# ... (FastAPI app setup and API Key security from Phase 1)

# --- AI Model Initialization ---  
# Load models once when the server starts to avoid reloading on every request  
try:  
    print("Loading Sentence Transformer model...")  
    vectorizer = SentenceTransformer('all-MiniLM-L6-v2')  
    print("✅ Model loaded.")

    print("Initializing OpenAI API...")  
    openai.api_key = os.getenv("OPENAI_API_KEY") # <-- CHANGE  
    if not openai.api_key:  
        raise ValueError("OPENAI_API_KEY environment variable not set.")  
    print("✅ OpenAI API initialized.")  
except Exception as e:  
    print(f"❌ Error during model initialization: {e}")  
    vectorizer = None

# ...

@app.post("/api/admin/start_generation_round", dependencies=[Depends(get_api_key)])  
async def trigger_generation_round():  
    print("✅ Admin trigger received! Starting topic generation process...")  
      
    # 1. Fetch live submissions from Firestore  
    # 2. Analyze: Vectorize submissions and cluster them  
    # 3. Generate: For top clusters, use LLM to create thread title and post  
    # 4. Publish & Archive: Write new threads and archive old submissions atomically

    return {"status": "success", "message": "Topic generation process completed."}

### **Step 3: Implement Data Fetching**

Let's add the code to get our raw material from Firestore.

# Inside trigger_generation_round() function...

db = firestore.client()  
submissions_to_process = []  
docs_to_archive = {} # {doc_id: author_uid}

try:  
    print("1. Fetching live submissions from Firestore...")  
    live_submissions_ref = db.collection('submissions').where('status', '==', 'live')  
    docs = live_submissions_ref.stream()

    for doc in docs:  
        doc_data = doc.to_dict()  
        submissions_to_process.append({  
            "id": doc.id,  
            "text": doc_data.get("submissionText"),  
            "author_uid": doc_data.get("author_uid")  
        })  
      
    if not submissions_to_process:  
        print("No live submissions found. Exiting process.")  
        return {"status": "success", "message": "No live submissions to process."}

    print(f"   - Found {len(submissions_to_process)} submissions to process.")

except Exception as e:  
    print(f"❌ Error fetching submissions: {e}")  
    raise HTTPException(status_code=500, detail="Failed to fetch from Firestore.")

### **Step 4: Implement AI Analysis (Vectorize & Cluster)**

This is where we identify the core themes.

# Inside trigger_generation_round(), after fetching...

print("2. Analyzing submissions...")  
# Extract just the text for vectorization  
texts = [sub['text'] for sub in submissions_to_process]

# Vectorize the text  
print("   - Vectorizing texts...")  
embeddings = vectorizer.encode(texts)

# Cluster the embeddings  
# min_cluster_size is a key parameter to tune. A smaller value finds more, smaller topics.  
print("   - Clustering vectors...")  
clusterer = hdbscan.HDBSCAN(min_cluster_size=3, metric='euclidean')  
cluster_labels = clusterer.fit_predict(embeddings)

# Group submissions by their new cluster label  
clustered_submissions = {}  
for i, label in enumerate(cluster_labels):  
    if label == -1:  
        continue # Ignore noise points  
    if label not in clustered_submissions:  
        clustered_submissions[label] = []  
    clustered_submissions[label].append(submissions_to_process[i])

print(f"   - Identified {len(clustered_submissions)} clusters (excluding noise).")

### **Step 5: Implement Content Generation**

For each major cluster, we'll ask the OpenAI API to create our thread content.

# Inside trigger_generation_round(), after clustering...

print("3. Generating content for top clusters...")

# Sort clusters by size to process the most popular topics  
sorted_clusters = sorted(clustered_submissions.items(), key=lambda item: len(item[1]), reverse=True)

# Process the top 3 clusters (or fewer if there aren't that many)  
for cluster_id, submissions_in_cluster in sorted_clusters[:3]:  
    print(f"   - Processing cluster {cluster_id} with {len(submissions_in_cluster)} members...")  
      
    # Consolidate text for the LLM prompt  
    consolidated_text = "n---n".join([sub['text'] for sub in submissions_in_cluster])  
      
    # Build a detailed prompt using the OpenAI Chat Completions format  
    system_prompt = "You are a community moderator. Your goal is to synthesize user ideas into engaging discussion topics."  
    user_prompt = f"""  
    Based on the following user thoughts, all centered on a similar theme, perform two tasks:  
    1. Create a single, neutral, open-ended discussion question that captures the core idea.  
    2. Write a short, engaging initial post to kick off the thread, referencing the collective thought.

    The user thoughts are:  
    ---  
    {consolidated_text}  
    ---

    Format your entire response as a single, valid JSON object with two keys: "title" and "initial_post".  
    """

    try:  
        # Generate content using OpenAI's API  
        response = openai.chat.completions.create(  
            model="gpt-4.1-2025-04-14",  
            messages=[  
                {"role": "system", "content": system_prompt},  
                {"role": "user", "content": user_prompt}  
            ],  
            response_format={"type": "json_object"} # Use JSON mode for reliable output  
        )  
          
        # The response content is a JSON string, so we parse it.  
        response_content = response.choices[0].message.content  
        generated_content = json.loads(response_content)  
        thread_title = generated_content['title']  
        initial_post_text = generated_content['initial_post']  
          
        # We'll handle publishing in the next step  
        print(f"     - Generated Title: {thread_title}")

        # ... LOGIC FOR STEP 6 WILL GO HERE ...  
          
    except (json.JSONDecodeError, KeyError, openai.APIError) as e:  
        print(f"     - ❌ Error processing LLM response for cluster {cluster_id}: {e}")  
        continue # Skip to the next cluster if one fails

### **Step 6: Implement Publishing and Archiving (The Atomic Write)**

This is the final, critical step. We use a **batched write** to ensure all database changes happen together or not at all.

# This code goes INSIDE the loop from Step 5, right after generating content.

print("4. Publishing new thread and archiving submissions...")  
batch = db.batch()

# A. Create the new public thread document  
new_thread_ref = db.collection('public_threads').document()  
batch.set(new_thread_ref, {  
    'title': thread_title,  
    'generatedAt': firestore.SERVER_TIMESTAMP,  
    'cluster_topic': f"Cluster {cluster_id}" # Simple identifier for now  
})

# B. Create the initial AI-generated post in the sub-collection  
initial_post_ref = new_thread_ref.collection('posts').document()  
batch.set(initial_post_ref, {  
    'postText': initial_post_text,  
    'author_uid': None,  
    'author_username': "Thread Starter",  
    'author_photoURL': "url/to/your/default_ai_icon.svg",  
    'createdAt': firestore.SERVER_TIMESTAMP  
})

# C. Loop through the submissions in THIS cluster to archive them  
for submission in submissions_in_cluster:  
    sub_ref = db.collection('submissions').document(submission['id'])  
    batch.update(sub_ref, {'status': 'archived'})  
      
    # Also update the corresponding user's profile  
    user_ref = db.collection('users').document(submission['author_uid'])  
    batch.update(user_ref, {'live_submission_id': None})

# D. Commit the entire batch of operations  
try:  
    batch.commit()  
    print(f"   - ✅ Successfully published thread and archived {len(submissions_in_cluster)} submissions.")  
except Exception as e:  
    print(f"   - ❌ Error committing batch for cluster {cluster_id}: {e}")

### **Step 7: Verification and Testing**

1. Use your seeder scripts (create_fake_users.py, generate_submissions.py) to populate your database with "live" submissions.  
2. Run your CLI trigger script (trigger_generation.py).  
3. Check the Railway logs to monitor the process.  
4. **Check Firestore:**  
   * **public_threads collection:** Are there 2-3 new documents with titles and timestamps?  
   * **posts sub-collection:** Does each new thread have an initial post document?  
   * **submissions collection:** Have the status fields of the processed documents been changed to "archived"?  
   * **users collection:** Have the live_submission_id fields for the participating users been set back to null?

If all of these are true, Phase 3 is complete and your app's core engine is fully functional.
