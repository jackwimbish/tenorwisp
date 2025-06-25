#!/bin/bash
#
# This script configures the Firebase project for the TenorWisp app.
# It generates the required 'google-services.json' file from a template
# and an environment file.
#
# INSTRUCTIONS:
# 1. Make sure you have a 'google-services.json.example' file in 'android/app/'.
# 2. Make sure you have a '.env' file in the root directory with the following content:
#    GOOGLE_SERVICES_API_KEY="your_api_key_here"

set -e

# Define paths
ROOT_DIR=$(git rev-parse --show-toplevel)
TEMPLATE_FILE="$ROOT_DIR/android/app/google-services.json.example"
OUTPUT_FILE="$ROOT_DIR/android/app/google-services.json"
ENV_FILE="$ROOT_DIR/.env"

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

# 4. Check for the template file
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template file not found at '$TEMPLATE_FILE'."
  echo "Please create it from your actual 'google-services.json' file,"
  echo "and replace the api_key with the placeholder 'REPLACE_WITH_YOUR_API_KEY'."
  exit 1
fi

# 5. Generate the google-services.json file
echo "Generating '$OUTPUT_FILE'..."
sed "s/REPLACE_WITH_YOUR_API_KEY/${GOOGLE_SERVICES_API_KEY}/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "✅ '$OUTPUT_FILE' has been generated successfully."
echo "You are all set for the Android build!" 