# ==============================================================================
# SCRIPT: clear_generated_data.py
#
# PURPOSE:
# This script is a utility for testing. It completely WIPES all documents from
# the 'submissions' and 'public_threads' collections, including all posts
# within each thread. It also resets the 'live_submission_id' on all users.
#
# PREREQUISITES:
# 1. Install necessary libraries:
#    pip install firebase-admin python-dotenv
#
# 2. Firebase Service Account & .env file:
#    - You should already have this set up from the other scripts.
#
# USAGE:
# python clear_generated_data.py
# ==============================================================================

import os
import json
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

# --- Load environment variables from .env file ---
load_dotenv()

# --- Initialize Firebase Admin SDK ---
# This initialization logic is robust for both local and deployed environments.
try:
    print("Initializing Firebase...")
    service_account_json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if service_account_json_str:
        service_account_info = json.loads(service_account_json_str)
        cred = credentials.Certificate(service_account_info)
    else:
        if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
             raise ValueError("GOOGLE_APPLICATION_CREDENTIALS not set for local development.")
        cred = credentials.ApplicationDefault()

    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized successfully.")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    exit()

db = firestore.client()

def delete_collection(coll_ref, batch_size):
    """Recursively deletes a collection in batches."""
    docs = coll_ref.limit(batch_size).stream()
    deleted = 0

    for doc in docs:
        # If the document has subcollections, recursively delete them first
        for sub_coll_ref in doc.reference.collections():
            delete_collection(sub_coll_ref, batch_size)
        
        print(f'   - Deleting doc: {doc.id}')
        doc.reference.delete()
        deleted += 1

    if deleted >= batch_size:
        return delete_collection(coll_ref, batch_size)
    return deleted

def reset_user_submissions():
    """Sets live_submission_id to None for all users who have one."""
    print("\n4. Resetting user submission statuses...")
    users_ref = db.collection('users').where('live_submission_id', '!=', None)
    docs = users_ref.stream()
    
    updated_count = 0
    batch = db.batch()
    for doc in docs:
        print(f"   - Resetting user {doc.id}")
        batch.update(doc.reference, {'live_submission_id': None})
        updated_count += 1
        # Commit every 500 updates
        if updated_count % 500 == 0:
            batch.commit()
            batch = db.batch()

    if updated_count % 500 != 0:
        batch.commit() # Commit any remaining updates
        
    print(f"   - Reset {updated_count} user document(s).")


def main():
    """Main function to clear the collections."""
    print("This script will permanently delete all data from the following collections:")
    print("  - public_threads (and all nested posts)")
    print("  - submissions")
    print("And will reset the 'live_submission_id' on all user profiles.")
    
    confirmation = input("Are you absolutely sure you want to continue? This cannot be undone. (y/n): ")
    if confirmation.lower() != 'y':
        print("Operation cancelled.")
        return

    # --- Delete public_threads ---
    print("\n1. Deleting 'public_threads' collection...")
    threads_ref = db.collection('public_threads')
    deleted_count = delete_collection(threads_ref, 50)
    print(f"   - Deleted {deleted_count} thread(s).")

    # --- Delete submissions ---
    print("\n2. Deleting 'submissions' collection...")
    submissions_ref = db.collection('submissions')
    deleted_count = delete_collection(submissions_ref, 50)
    print(f"   - Deleted {deleted_count} submission(s).")
    
    # --- Reset User Statuses ---
    reset_user_submissions()

    print("\n✅ Cleanup complete.")

if __name__ == '__main__':
    main() 