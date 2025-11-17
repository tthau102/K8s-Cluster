#!/bin/bash

# Get current branch
branch=$(git rev-parse --abbrev-ref HEAD)
datenow=$(date +%d/%m/%y-%H:%M:%S)

# Show current status
echo "=== Git Push Script ==="
echo "Branch: $branch"
echo "Commit message: $datenow"
echo ""
echo "Remote repositories:"
git remote -v | grep push


echo ""
echo "-----------------"
echo "Auto-confirm mode"
echo "-----------------"

echo "Press ENTER 2 times to confirm (or any key to cancel):"
for i in 1 2; do
  read -n 1 -s key
  [[ -n "$key" ]] && echo "Cancelled" && exit 0
  echo "$i/2"
done
echo "Confirmed!"


echo ""
echo "------------------------------------------"
# Perform git operations
git add .
git commit -m "$datenow"

# Push to each remote
for remote in $(git remote); do
    echo ""
    echo "------------------------------------------"
    echo "→ Pushing to $remote/$branch..."
    if git push $remote $branch --force; then
        echo "✓ Successfully pushed to $remote/$branch"
    else
        echo "✗ Failed to push to $remote/$branch"
    fi
done

echo ""
echo "=== Push completed ==="