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

### 3. Run the AI Service (Backend)

The backend service is not required for the messaging features to work, but it is necessary for the AI topic generation. For instructions on running the Python backend locally or triggering the deployed service, please see `_docs/implementation-phase-1.md`.
