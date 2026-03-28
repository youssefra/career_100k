#!/bin/bash
TARGET="8.8.8.8" # This is Google's Public DNS

echo "Checking connection to $TARGET..."
if ping -c 1 $TARGET &> /dev/null; then
    echo "SUCCESS: Server is ALIVE."
else
    echo "FAILURE: Server is DOWN or UNREACHABLE."
fi
