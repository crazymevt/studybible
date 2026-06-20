#!/bin/bash
set -e

echo "Starting automated release process..."

# Get latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
  echo "No previous tags found. Collecting all commits..."
  COMMITS=$(git log --pretty=format:"%s")
else
  echo "Collecting commits since tag: $LATEST_TAG..."
  COMMITS=$(git log ${LATEST_TAG}..HEAD --pretty=format:"%s")
fi

echo "--- Commits for Changelog ---"
echo "$COMMITS"
echo "-----------------------------"

# Run dart script, pass commits via stdin, capture new version
NEW_VERSION=$(echo "$COMMITS" | dart scripts/update_version.dart)

if [ $? -ne 0 ]; then
  echo "Failed to calculate new version."
  exit 1
fi

echo "Successfully updated files for version: $NEW_VERSION"

# Add and commit changes
git add pubspec.yaml lib/app/version.dart assets/changelog.json
git commit -m "chore: release $NEW_VERSION"

# Create tag
git tag "$NEW_VERSION" -m "Release $NEW_VERSION"

echo "✅ Release $NEW_VERSION completed and tagged successfully!"
echo "Run 'git push && git push --tags' to sync with your remote repository."
