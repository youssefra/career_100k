#!/bin/bash
echo "Checking System Memory..."
free -h
echo "---------------------------"
echo "Checking Top 3 CPU Consuming Processes:"
ps aux --sort=-%cpu | head -n 4
