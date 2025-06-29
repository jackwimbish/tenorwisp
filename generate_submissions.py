# ==============================================================================
# SCRIPT: generate_submissions.py
#
# PURPOSE:
# This script reads the user data from 'fake_users.json', and for a specified
# number of users, generates and submits unique topic submissions based on
# predefined themes using the OpenAI API.
#
# PREREQUISITES:
# 1. Run create_fake_users.py first to generate the 'fake_users.json' file.
# 2. Install necessary libraries:
#    pip install firebase-admin openai python-dotenv
#
# 3. Firebase Service Account (uses .env file).
#
# 4. OpenAI API Key:
#    - Get an API key from your OpenAI account dashboard.
#    - Add it to your .env file:
#      OPENAI_API_KEY="your_api_key_here"
#
# USAGE:
# python generate_submissions.py
# ==============================================================================

import os
import json
import random
import time
import firebase_admin
from firebase_admin import credentials, firestore
import openai
from dotenv import load_dotenv

# --- Load environment variables from .env file ---
load_dotenv()

# --- Configuration ---
# Define the topics and how many users should post about each.
# The script will assign users randomly.
SUBMISSION_CONFIG = {
    "Should we preserve 'human-only' spaces and activities in an increasingly automated world?": 11,
    "Would a post-scarcity economy powered by advanced automation be utopian or dystopian?": 9,
    "Recent scientific breakthroughs in human longevity and anti-aging": 8,
    "Will virtual and augmented reality make us more empathetic or more isolated?": 5,
    "The social and psychological impact of AI-powered romantic companions": 4,
    "The simple, uncomplicated joy of pet cats": 2
}
#SUBMISSION_CONFIG = {
#    "Are we becoming less creative as individuals due to algorithm-curated content?": 11,
#    "Will brain-computer interfaces fundamentally change human identity and what it means to be 'you'?": 9,
#    "Should we treat advanced AI systems as tools, partners, or something entirely new?": 8,
#    "Is the decline of physical books and handwriting diminishing our cognitive abilities?": 5,
#    "Should we attempt to communicate with or visit other intelligent species if we discover them?": 4,
#    "The simple, uncomplicated joy of pet dogs": 2
#}

INPUT_USER_FILE = 'fake_users.json'
SUBMISSIONS_LOG_FILE = 'generated_submissions_log.json'

# --- Initialize Firebase Admin SDK ---
if not firebase_admin._apps:
    try:
        print("Initializing Firebase for submission generation script...")
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

# --- Initialize OpenAI API ---
try:
    openai.api_key = os.getenv("OPENAI_API_KEY")
    if not openai.api_key:
        raise ValueError("OPENAI_API_KEY environment variable not found in .env file.")
    print("OpenAI API initialized successfully.")
except Exception as e:
    print(f"Error initializing OpenAI API: {e}")
    exit()


db = firestore.client()

def get_llm_generated_submission(topic):
    """Generates a unique, user-like submission for a given topic using the OpenAI API."""
    system_prompt = "You are a person interested in debating intellectual topics, visiting an online discussion forum. Your task is to write a short submission (1 or 2 sentences) for a discussion topic. These submissions will be private and anonymous, but used to decide on duscussion topics for the entire forum. Make it sound like a real, informal user post. Vary the phrasing and tone slightly. Do not use hashtags or overly formal language. Text before BEGIN_POST represents your own private thoughts. You should express you thoughts after BEGIN_POST as if you were telling someone, unprompted, about an idea you are interested in discussing."
    user_prompt = f"The topic I'm thinking about is: '{topic}' BEGIN_POST"

    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=1.4, # A little more creativity
            max_tokens=100
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"  - LLM generation failed: {e}")
        # Fallback to a simple text if LLM fails
        return f"I was thinking about the topic of {topic}."


def generate_and_submit():
    """Assigns topics to users and generates/submits their topic ideas."""
    # 1. Load the fake users
    try:
        with open(INPUT_USER_FILE, 'r') as f:
            users = json.load(f)
        if not users:
            print("User file is empty. Please run create_fake_users.py first.")
            return
        print(f"Loaded {len(users)} users from {INPUT_USER_FILE}.")
    except FileNotFoundError:
        print(f"Error: {INPUT_USER_FILE} not found. Please run create_fake_users.py first.")
        return

    # Shuffle users to ensure random assignment for each run
    random.shuffle(users)
    user_pool = iter(users) # Use an iterator to easily grab the next available user
    generated_submissions_log = []

    # 2. Loop through the submission configuration
    for topic, count in SUBMISSION_CONFIG.items():
        print(f"\n--- Generating {count} submissions for topic: '{topic}' ---")
        for i in range(count):
            try:
                # Get the next available user
                current_user = next(user_pool)
                uid = current_user['uid']
                username = current_user['username']

                print(f"Processing for user: {username} ({uid})")

                # 3. Generate a unique submission using the LLM
                print("  - Generating text with LLM...")
                submission_text = get_llm_generated_submission(topic)
                print(f"  - Generated text: '{submission_text[:50]}...'")

                # 4. Create a batched write to perform atomic operations
                batch = db.batch()

                # 5. Create the new submission document
                submission_ref = db.collection('submissions').document()
                submission_data = {
                    'author_uid': uid,
                    'submissionText': submission_text,
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'lastEdited': firestore.SERVER_TIMESTAMP,
                    'status': 'live'
                }
                batch.set(submission_ref, submission_data)
                
                # 6. Update the user's document with the live submission ID
                user_ref = db.collection('users').document(uid)
                batch.update(user_ref, {'live_submission_id': submission_ref.id})
                
                # 7. Commit the batch
                batch.commit()
                print(f"  - Atomically created submission and updated user profile.")

                # 8. Log the generated submission for review
                generated_submissions_log.append({
                    'username': username,
                    'uid': uid,
                    'submission_id': submission_ref.id,
                    'generated_text': submission_text
                })

                # Small delay to avoid hitting API rate limits
                time.sleep(1.5)

            except StopIteration:
                print("\nWarning: Ran out of fake users. Not all configured submissions were created.")
                break # Exit the loop
            except Exception as e:
                print(f"An error occurred while processing a submission: {e}")

    # 9. Save the log file at the end
    try:
        with open(SUBMISSIONS_LOG_FILE, 'w') as f:
            json.dump(generated_submissions_log, f, indent=4)
        print(f"\n✅ Successfully saved {len(generated_submissions_log)} submission logs to {SUBMISSIONS_LOG_FILE}.")
    except Exception as e:
        print(f"\n❌ Error saving log file: {e}")

    print("\nAll submissions generated successfully.")


if __name__ == '__main__':
     confirmation = input("This script will generate new submissions in Firestore for multiple users. Are you sure? (y/n): ")
     if confirmation.lower() == 'y':
         generate_and_submit()
     else:
         print("Operation cancelled.")

