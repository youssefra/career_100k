#!/bin/bash
echo "--- STORAGE REPORT ---"
# Show only the main disk usage
df -h | grep '^/dev/'

echo "--- TOP 3 LARGEST FILES IN HOME ---"
# Sort files by size and show top 3
du -ah ~ | sort -rh | head -n 3
