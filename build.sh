#!/bin/bash

# DeepSpaceDaily Build Script
# This script builds the DeepSpaceDaily project for the iOS Simulator

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "${YELLOW}Starting build for DeepSpaceDaily...${NC}"

# Navigate to project directory (in case script is run from elsewhere)
cd "$(dirname "$0")"

# Build the project
echo "${YELLOW}Building project...${NC}"
xcodebuild -scheme DeepSpaceDaily -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "${GREEN}Build succeeded!${NC}"
    exit 0
else
    echo "${RED}Build failed!${NC}"
    exit 1
fi 