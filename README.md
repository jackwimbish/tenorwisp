# tenorwisp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Setup

This project uses Firebase for its backend services. To configure your local environment, you need to provide your own Firebase project configuration.

### Android Setup

1.  **Create `google-services.json.example`**

    In the `android/app/` directory, create a file named `google-services.json.example`. Copy the contents of your actual `google-services.json` file (which you can download from your Firebase project console) into this new file.

    Then, find the `api_key` field and replace its value with the placeholder `REPLACE_WITH_YOUR_API_KEY`. The result should look something like this:

    ```json
    // ... other json properties
    "api_key": [
      {
        "current_key": "REPLACE_WITH_YOUR_API_KEY"
      }
    ],
    // ... other json properties
    ```

2.  **Create a `.env` file**

    In the root directory of the project, create a file named `.env`. This file will hold your secret API key. Add the following line to it, replacing `"your_api_key_here"` with your actual Firebase API key:

    ```
    GOOGLE_SERVICES_API_KEY="your_api_key_here"
    ```

3.  **Run the configuration script**

    The script will generate the `google-services.json` file needed to build the Android app.

    First, make the script executable:
    ```sh
    chmod +x scripts/configure_firebase.sh
    ```

    Then, run the script:
    ```sh
    ./scripts/configure_firebase.sh
    ```

    After running the script, you should see a new `android/app/google-services.json` file, and you'll be ready to build the app.
