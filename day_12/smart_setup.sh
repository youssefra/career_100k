#!/bin/bash
# Setting up Variables
CURRENT_USER=$(whoami)
PROJECT="Mars-Mission-2026"

echo "Hello $CURRENT_USER!"
echo "Creating your project folder: $PROJECT"
mkdir -p "$PROJECT"
echo "Initializing Status File..."
echo "Project $PROJECT is ACTIVE for user $CURRENT_USER" > "$PROJECT/status.txt"
ls -R "$PROJECT"
