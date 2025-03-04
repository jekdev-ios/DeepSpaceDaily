#!/bin/bash

# Define paths
CERT_PATH="DeepSpaceDaily/Resources/Certificates/spaceflightnewsapi.net.pem"
PROJECT_PATH="DeepSpaceDaily.xcodeproj"

# Check if certificate exists
if [ ! -f "$CERT_PATH" ]; then
    echo "Certificate not found at $CERT_PATH"
    exit 1
fi

# Create a Resources group in the project if it doesn't exist
mkdir -p DeepSpaceDaily/Resources

# Add the certificate to the project
echo "Adding certificate to Xcode project..."
echo "Please manually add the certificate to your Xcode project:"
echo "1. Open your Xcode project"
echo "2. Right-click on the DeepSpaceDaily group in the Project Navigator"
echo "3. Select 'Add Files to \"DeepSpaceDaily\"...'"
echo "4. Navigate to $CERT_PATH and select it"
echo "5. Make sure 'Copy items if needed' is checked"
echo "6. Click 'Add'"
echo ""
echo "Certificate path: $(pwd)/$CERT_PATH"

# Make the certificate file readable
chmod 644 "$CERT_PATH"

echo "Done!" 