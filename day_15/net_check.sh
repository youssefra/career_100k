#!/bin/bash
MY_IP=$(hostname -I | awk '{print $1}')
echo "Scanning System Networking..."
echo "Your Local IP is: $MY_IP"
echo "Checking if Port 22 (SSH) is active..."
ss -tl | grep 22
