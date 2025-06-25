# tenorwisp

A social app in Flutter.

## HOW TO BUILD

Before you can build and run the app, you need to configure the Firebase connection. This involves creating two template files and a `.env` file with your secret API key.


1.  **Create a `.env` file**

    In the root directory of the project, create a file named `.env`. This file will hold your secret API key. Add the following line to it, replacing `"your_api_key_here"` with your actual Google Services API key:

    ```
    GOOGLE_SERVICES_API_KEY="your_api_key_here"
    ```

2.  **Run the configuration script**

    The script will generate the `google-services.json` and `lib/firebase_options.dart` files needed to build the app.

    First, make sure the script is executable:
    ```sh
    chmod +x scripts/configure_firebase.sh
    ```

    Then, run the script:
    ```sh
    ./scripts/configure_firebase.sh
    ```

    After running the script, the necessary Firebase config files will be in place, and you'll be ready to build the app.


Currently, the app only targets Android. Once you have done the above steps to prepare the repo, you can build and run it using VSCode or a compatible editor with the Flutter plugin, or with th Flutter CLI.
