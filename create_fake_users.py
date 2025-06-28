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
NUM_USERS_TO_CREATE = 30
OUTPUT_FILE = 'fake_users.json'

# --- Initialize Firebase Admin SDK ---
try:
    # This automatically finds the credentials from the GOOGLE_APPLICATION_CREDENTIALS
    # environment variable loaded by load_dotenv().
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred)
    print("Firebase Admin SDK initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")
    print("Please ensure you have created a .env file and set the GOOGLE_APPLICATION_CREDENTIALS variable correctly.")
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
            display_name = fake.name()

            # 1. Create user in Firebase Authentication
            user = auth.create_user(
                email=email,
                password=password,
                display_name=display_name
            )
            print(f"Successfully created user: {user.uid} ({email})")

            # 2. Create a corresponding document in the 'users' collection in Firestore
            user_doc_ref = db.collection('users').document(user.uid)
            user_doc_ref.set({
                'displayName': display_name,
                'email': email,
                'live_submission_id': None  # Initialize as null
            })
            print(f"  - Created Firestore document for user {user.uid}")

            # 3. Store details for later use
            users_data.append({
                'uid': user.uid,
                'email': email,
                'password': password,
                'displayName': display_name
            })

        except Exception as e:
            print(f"Error creating user {i+1}: {e}")

    # 4. Save the created user data to a JSON file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(users_data, f, indent=4)

    print(f"\nProcess complete. Saved {len(users_data)} user details to {OUTPUT_FILE}")

if __name__ == '__main__':
    create_users()

