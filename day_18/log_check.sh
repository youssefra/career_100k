#!/bin/bash
echo "Searching for ERRORS in the last 50 system events..."
journalctl -n 50 | grep -i "error" || echo "No errors found. System is healthy!"

echo "Checking last 5 successful logins:"
last -n 5
