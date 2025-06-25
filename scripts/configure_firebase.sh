#!/bin/bash
#
# This script configures the Firebase project for the TenorWisp app.
# It generates the required 'google-services.json' and 'firebase_options.dart'
# files from templates and an environment file.
#
# INSTRUCTIONS:
# 1. Make sure you have the following template files:
#    - 'android/app/google-services.json.example'
#    - 'lib/firebase_options.dart.example'
# 2. Make sure you have a '.env' file in the root directory with the following content:
#    GOOGLE_SERVICES_API_KEY="your_api_key_here"

set -e

# Define paths
ROOT_DIR=$(git rev-parse --show-toplevel)
ENV_FILE="$ROOT_DIR/.env"

# Google Services paths
GS_TEMPLATE_FILE="$ROOT_DIR/android/app/google-services.json.example"
GS_OUTPUT_FILE="$ROOT_DIR/android/app/google-services.json"

# Firebase Options paths
FO_TEMPLATE_FILE="$ROOT_DIR/lib/firebase_options.dart.example"
FO_OUTPUT_FILE="$ROOT_DIR/lib/firebase_options.dart"


# 1. Check for .env file
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: '.env' file not found in the root directory."
  echo "Please create it and add your GOOGLE_SERVICES_API_KEY."
  exit 1
fi

# 2. Source environment variables
source "$ENV_FILE"

# 3. Check for the API key in the environment
if [ -z "$GOOGLE_SERVICES_API_KEY" ]; then
  echo "Error: GOOGLE_SERVICES_API_KEY is not set in your '.env' file."
  exit 1
fi

# 4. Generate google-services.json
if [ ! -f "$GS_TEMPLATE_FILE" ]; then
  echo "Warning: Template file not found at '$GS_TEMPLATE_FILE'."
  echo "Skipping generation of 'google-services.json'."
else
  echo "Generating '$GS_OUTPUT_FILE'..."
  sed "s/REPLACE_WITH_YOUR_API_KEY/${GOOGLE_SERVICES_API_KEY}/g" "$GS_TEMPLATE_FILE" > "$GS_OUTPUT_FILE"
  echo "✅ '$GS_OUTPUT_FILE' has been generated successfully."
fi

# 5. Generate firebase_options.dart
if [ ! -f "$FO_TEMPLATE_FILE" ]; then
  echo "Warning: Template file not found at '$FO_TEMPLATE_FILE'."
  echo "Skipping generation of 'firebase_options.dart'."
else
  echo "Generating '$FO_OUTPUT_FILE'..."
  sed "s/REPLACE_WITH_YOUR_API_KEY/${GOOGLE_SERVICES_API_KEY}/g" "$FO_TEMPLATE_FILE" > "$FO_OUTPUT_FILE"
  echo "✅ '$FO_OUTPUT_FILE' has been generated successfully."
fi


echo "Firebase configuration is complete!" 