# AI-Powered Discussion Platform Development Plan

## Phase 1: The Backend and Trigger Foundation

**Goal:** Establish a secure, triggerable backend service. This phase proves your deployment and administrative control work before adding any complex logic.

### Setup Minimal Backend

- Create a simple Python project using FastAPI
- Implement a single `POST /api/admin/start_generation_round` endpoint
- **Security:** Add simple API Key authentication to this endpoint. It should expect a secret key in the `X-API-Key` header and return a `401 Unauthorized` error if it's missing or wrong
- **Logic:** For now, the endpoint's only job is to print a confirmation message to the server logs (e.g., "Admin trigger received. Starting process...") and return a success JSON response like `{"status": "processing_started"}`

### Deploy to Railway

- Deploy this minimalist FastAPI app to Railway
- Set your secret API Key as an environment variable in the Railway service settings. Do not hardcode it in your Python script

### Create CLI Trigger

- Create a local Python script named `trigger_generation.py`
- Use the `requests` library to make a POST request to your deployed Railway app's endpoint
- The script should read the secret API Key (e.g., from a local `.env` file or another environment variable) and include it in the request headers

### Test and Verify

- Run `python trigger_generation.py` from your local machine
- **Success Check:** You should get a `200 OK` response from your script, and more importantly, see the "Admin trigger received..." message appear in your live Railway deployment logs

*You have now successfully built and secured the "ignition switch" for your application's engine.*

## Phase 2: The Data Model and User Submission Flow

**Goal:** Implement the complete user-facing submission loop, ensuring data is structured correctly and permissions are enforced.

### Setup Firestore Data Model

In your Firebase console, ensure you have these collections:
- `users`: Where each user document will eventually get a `live_submission_id` field
- `submissions`: This will hold all topic submissions

### Implement Security Rules

Deploy the refined Firestore security rules we discussed. Key points:
- A user can only create a submission if they are the author
- A user can only read or update a submission if they are the author AND its status is "live"
- A user can update their own users document (but you can restrict which fields for production)

### Implement Flutter Submission UI

- In your Flutter app, create the UI for submitting a topic idea (e.g., a simple text field and a "Submit" button). This should be in a dedicated "Discussions" or "Topics" section
- When the user presses "Submit," implement the Firestore Batched Write logic in Dart to perform these two operations atomically:
  1. Create a new document in the `submissions` collection with the text, `author_uid`, and `status: "live"`
  2. Update the current user's document in the `users` collection, setting the `live_submission_id` field to the ID of the new submission document

### Test and Verify

- Use your Flutter app to log in as a user and submit a topic
- **Success Check:** In the Firestore console, verify that the new document appears in `submissions` and the `live_submission_id` field is correctly updated on the `users` document
- From the app, try to edit the submission. This should work

*You have now built the complete user-facing part of the core loop and can start collecting data.*

## Phase 3: The Core AI Logic and Archiving

**Goal:** Implement the "magic" in your backend—the analysis, generation, and archiving process.

### Seed the Database

Use the `create_fake_users.py` and `generate_submissions.py` scripts to populate your Firestore with a good amount of realistic, clustered data. This is crucial for testing.

### Flesh out Backend Logic

Modify your `start_generation_round` function in the FastAPI backend:

1. **Fetch:** Use the Firebase Admin SDK to query the `submissions` collection for all documents `where("status", "==", "live")`
2. **Analyze:** Perform the vectorization (sentence-transformers) and clustering (hdbscan) on the fetched data
3. **Generate:** For the top 2-3 clusters, consolidate the text and make API calls to your chosen LLM (e.g., GPT4.1) to generate engaging topic titles
4. **Publish:** Write these new topic titles as documents into a new `public_threads` collection

### Implement Archiving Process

This is the final step in your backend function:

1. Create a Firestore Batched Write
2. Loop through the IDs of all the submissions you just processed. In the batch:
   - Stage an update to set the submission's `status` to "archived"
   - Stage an update to set the corresponding user's `live_submission_id` to `null`
3. Commit the batch

### Test and Verify

- Run your `trigger_generation.py` script
- **Success Check:** Go into the Firestore console. Verify that new documents exist in `public_threads`. Check that the processed submissions are now marked as "archived" and that the `live_submission_id` on the user documents has been cleared

*The core intellectual property of your app is now functional. The system can autonomously create novel content from user input.*

## Phase 4: Closing the Loop and Final Demo Prep

**Goal:** Display the results to the user in the app, completing the full end-to-end user experience for the demo.

### Implement Flutter Display UI

- In the main screen of your "Discussions" section, use a `StreamBuilder` widget to listen for real-time changes to the `public_threads` collection
- Display the results in a simple, clean `ListView`

### Conduct Full End-to-End Test

1. Clear your test collections (`submissions`, `public_threads`)
2. Using your Flutter app, log in as several different fake users and submit topic ideas
3. From your terminal, run `python trigger_generation.py`
4. Watch the UI of your Flutter app. The new, AI-generated threads should appear automatically

---

*This completes the full development cycle for your AI-powered discussion platform.*