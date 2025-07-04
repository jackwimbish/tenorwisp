# TenorWisp

TenorWisp is a mobile application, built with Flutter, that explores new forms of social interaction. It combines two core experiences:

1.  **Direct Messaging:** A real-time, media-rich chat system where users can exchange messages, photos, and videos with friends.
2.  **AI-Powered Discussions:** An innovative social discussion platform designed to foster more authentic conversations. The system privately collects anonymous topic ideas from users, uses AI to analyze them, and generates new public discussion threads based on the collective thought of the community.

The project features a hybrid backend architecture, using **Firebase** for real-time services (Auth, Firestore, Storage, Cloud Functions) and a separate **Python/FastAPI** service hosted on **Railway** for all heavy-lifting AI/ML processing.

## How to Build and Run

### 1. Environment Variables

Before running any part of the application, create a file named `.env` in the root of the project. This file stores the necessary secrets and configuration settings. You can use the following as a template:

```
# --- Firebase Admin SDK Authentication ---
# Choose ONE method. Path is recommended for local dev.
GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/serviceAccountKey.json"
FIREBASE_SERVICE_ACCOUNT_JSON=""

# --- Firebase Frontend Configuration ---
# Used by the script to generate platform-specific config files.
GOOGLE_SERVICES_API_KEY="your_base64_encoded_google_services_api_key_here"

# --- OpenAI API Key ---
# Used by the backend and data generation scripts.
OPENAI_API_KEY="sk-..."

# --- Backend Security ---
# A secret key shared between the backend and the trigger script.
BACKEND_SECRET_KEY="a_very_strong_and_secret_key"

# --- Local Development & Testing ---
# Set to "true" to target your local server with trigger_generation.py
USE_DEV_SERVER="true"
```

### 2. Configure Firebase

Before you can build the app, you need to configure its connection to Firebase. This involves creating a `.env` file with your secret Google Services API key.

1.  **Create a `.env` file**

    In the root directory of the project, create a file named `.env`. Add the following line to it, replacing `"your_api_key_here"` with your actual Google Services API key:

    ```
    GOOGLE_SERVICES_API_KEY="your_api_key_here"
    ```

2.  **Run the configuration script**

    This script generates the `google-services.json` and `lib/firebase_options.dart` files needed for the app to connect to your Firebase project.

    First, make the script executable:
    ```sh
    chmod +x scripts/configure_firebase.sh
    ```

    Then, run the script:
    ```sh
    ./scripts/configure_firebase.sh
    ```

### 3. Run the Flutter App (Frontend)

Once Firebase is configured, you can run the Flutter application.
If you don't already have it installed, you'll need the Flutter CLI: On mac: `brew install flutter` or use the [official installation](https://docs.flutter.dev/get-started/install)

Then you can proceed with the following:

1.  **Get Dependencies:**
    Navigate to the project's root directory and run the following command to fetch all the necessary Flutter packages:
    ```sh
    flutter pub get
    ```

2.  **Run the App:**
    Make sure you have a device connected or an emulator running. Then, use the Flutter CLI to launch the app:
    ```sh
    flutter run
    ```
    Alternatively, you can run the app directly from your IDE (like VS Code or Android Studio) if you have the Flutter plugin installed.

### 4. Run the Backend (Python AI Service)

The backend service is responsible for all AI-powered analysis and content generation. While it's deployed on Railway for production use, you can run it locally for development and testing.

1.  **Set up the Python Environment:**
    Navigate to the project's root directory. Create a virtual environment and install the required Python libraries from the `requirements.txt` file.

    ```sh
    # Create and activate the virtual environment
    python3 -m venv backend/venv
    source backend/venv/bin/activate
    
    # Install dependencies
    pip install -r backend/requirements.txt
    ```
    *Note: You only need to create the virtual environment once.*

2.  **Run the Local Development Server:**
    Once your environment is set up and activated, you can start the local FastAPI server using Uvicorn.

    ```sh
    uvicorn backend.main:app --reload
    ```
    The `--reload` flag enables hot-reloading, so the server will restart automatically when you make changes to the code.

### 5. Test the AI Content Pipeline

With the backend server running, you can use the provided Python scripts to test the entire content generation pipeline from your terminal.

1.  **Clear Existing Data (Optional):**
    This script removes all previously generated submissions and public threads from Firestore, giving you a clean slate.

    ```sh
    python clear_generated_data.py
    ```

2.  **Generate Fake Submissions:**
    This script populates your database with realistic, clustered topic ideas from your fake users.

    ```sh
    python generate_submissions.py
    ```

3.  **Trigger AI Topic Generation:**
    This script makes a secure API call to your backend (either local or deployed) to start the analysis and generate the new public discussion threads.
    
    ```sh
    python trigger_generation.py
    ```
    *Note: To target your local server, set the `USE_DEV_SERVER` environment variable (e.g., `export USE_DEV_SERVER=true`). To target the deployed production server on Railway, make sure this variable is unset.*

    After running this, you should see the new threads appear in the app.
