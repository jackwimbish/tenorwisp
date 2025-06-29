# TenorWisp

TenorWisp is a mobile application, built with Flutter, that explores new forms of social interaction. It combines two core experiences:

1.  **Direct Messaging:** A real-time, media-rich chat system where users can exchange messages, photos, and videos with friends.
2.  **AI-Powered Discussions:** An innovative social discussion platform designed to foster more authentic conversations. The system privately collects anonymous topic ideas from users, uses AI to analyze them, and generates new public discussion threads based on the collective thought of the community.

The project features a hybrid backend architecture, using **Firebase** for real-time services (Auth, Firestore, Storage, Cloud Functions) and a separate **Python/FastAPI** service hosted on **Railway** for all heavy-lifting AI/ML processing.

## How to Build and Run

### 1. Configure Firebase

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

### 2. Run the Flutter App (Frontend)

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

### 3. Run the Backend

The backend service currently deployed on Railway, so there is no need to run it locally to test the app. If you still want to run it locally:

Set up a virtualenv and install Python libraries:
`python -m venv venv`
`source venv/bin/activate`
`pip install -r backend/requirements.txt`

Then to run a local development server:
`uvicorn backend.main:app`

In different terminal window, to test the AI topic generation functionality you can do the following:

Clear the current threads and proposed topic submissions (optional)
`python clear_generated_data.py`

Generate and submit some fake topic ideas for the users:
`python generate_submissions.py`

Now you can trigger the AI thread generation process:
`python trigger_generation.py`
