#!/bin/bash
# Setting the target folder name
FOLDER="production_data"

# The "IF" statement checks if the directory (-d) exists
if [ -d "$FOLDER" ]; then
    echo "Alert: $FOLDER already exists. No action taken."
else
    echo "Success: $FOLDER does not exist. Creating it now..."
    mkdir "$FOLDER"
fi
