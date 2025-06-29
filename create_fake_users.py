# ==============================================================================
# SCRIPT 1: create_fake_users.py
#
# PURPOSE:
# This script creates a specified number of fake users in Firebase Authentication
# and also creates a corresponding document for each user in your Firestore
# 'users' collection. It then saves the user details to a JSON file.
#
# PREREQUISITES:
# 1. Install necessary libraries:
#    pip install firebase-admin faker python-dotenv
#
# 2. Firebase Service Account & .env file:
#    - Go to your Firebase Project Settings -> Service accounts.
#    - Click "Generate new private key" and download the JSON file.
#    - Create a file named ".env" in the same directory as this script.
#    - Add the following line to your .env file, replacing the path:
#      GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/serviceAccountKey.json"
#
# USAGE:
# python create_fake_users.py
# ==============================================================================

import os
import json
import firebase_admin
from firebase_admin import credentials, auth, firestore
from faker import Faker
from dotenv import load_dotenv

# --- Load environment variables from .env file ---
load_dotenv()

# --- Configuration ---
NUM_USERS_TO_CREATE = 50
OUTPUT_FILE = 'fake_users.json'

# --- Initialize Firebase Admin SDK ---
try:
    print("Initializing Firebase for user creation script...")
    service_account_json_str = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if service_account_json_str:
        # Production-style: From environment variable
        print("   - Using service account from environment variable.")
        service_account_info = json.loads(service_account_json_str)
        cred = credentials.Certificate(service_account_info)
    else:
        # Development-style: From local file path in .env
        print("   - Using service account from local file path (GOOGLE_APPLICATION_CREDENTIALS).")
        if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
             raise ValueError("GOOGLE_APPLICATION_CREDENTIALS not set for local development.")
        cred = credentials.ApplicationDefault()

    firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized successfully.")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    exit()

db = firestore.client()
fake = Faker()

def create_users():
    """Creates fake users in Firebase Auth and Firestore."""
    users_data = []
    print(f"Starting creation of {NUM_USERS_TO_CREATE} fake users...")

    for i in range(NUM_USERS_TO_CREATE):
        try:
            email = fake.unique.email()
            password = fake.password(length=12, special_chars=True, digits=True, upper_case=True, lower_case=True)
            username = fake.user_name()

            # 1. Create user in Firebase Authentication
            user = auth.create_user(
                email=email,
                password=password,
                display_name=username
            )
            print(f"Successfully created user: {user.uid} ({email})")

            # 2. Use a batched write to create both Firestore documents atomically
            batch = db.batch()
            
            # Create the main user document in the 'users' collection
            user_doc_ref = db.collection('users').document(user.uid)
            batch.set(user_doc_ref, {
                'username': username,
                'email': email,
                'live_submission_id': None,
                'photoURL': f"https://api.dicebear.com/8.x/adventurer/svg?seed={username}",
                'friends': [],
                'friendRequestsSent': [],
                'friendRequestsReceived': []
            })

            # Create the username uniqueness document in the 'usernames' collection
            username_ref = db.collection('usernames').document(username.lower())
            batch.set(username_ref, {'uid': user.uid})
            
            # Commit the atomic batch
            batch.commit()
            print(f"  - Created Firestore documents for user {user.uid}")

            # 3. Store details for later use
            users_data.append({
                'uid': user.uid,
                'email': email,
                'password': password,
                'username': username
            })

        except Exception as e:
            print(f"Error creating user {i+1}: {e}")

    # 4. Save the created user data to a JSON file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(users_data, f, indent=4)

    print(f"\nProcess complete. Saved {len(users_data)} user details to {OUTPUT_FILE}")

if __name__ == '__main__':
    create_users()

