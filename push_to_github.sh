#!/bin/bash
# push_to_github.sh
# Interactive script: init git, create .gitignore, initial commit, add remote, push, optional tag & GH release.
set -e

DEFAULT_REMOTE="git@github.com:mochamaddhera21/mahasiswamahang.git"

prompt() {
  # $1 = prompt, $2 = default (optional)
  if [ -n "$2" ]; then
    read -p "$1 [$2]: " ans
    ans="${ans:-$2}"
  else
    read -p "$1: " ans
  fi
  echo "$ans"
}

confirm() {
  # $1 prompt
  while true; do
    read -p "$1 (y/n): " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

echo "== Push to GitHub helper =="
echo "Current directory: $(pwd)"
PROJECT_DIR="$(pwd)"

# Ask/confirm project dir
if confirm "Use this directory as project root?"; then
  :
else
  NEW_DIR=$(prompt "Enter project directory path" "$PROJECT_DIR")
  if [ -d "$NEW_DIR" ]; then
    cd "$NEW_DIR"
  else
    echo "Directory not found: $NEW_DIR"
    exit 1
  fi
fi

# Check SSH connection to GitHub (warn but continue)
echo "Checking SSH access to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "SSH to GitHub OK."
else
  echo "Warning: SSH test did not confirm authentication. If you see 'Permission denied (publickey)', ensure your SSH key is added to GitHub."
  if confirm "Continue anyway?"; then
    :
  else
    echo "Abort. Configure SSH key and try again."
    exit 1
  fi
fi

# Create .gitignore if missing
if [ -f .gitignore ]; then
  echo ".gitignore exists. Skipping creation."
else
  echo "Creating .gitignore..."
  cat > .gitignore <<'EOF'
node_modules
dist
.env
uploads
magang-backend.zip
.DS_Store
npm-debug.log
EOF
  git add .gitignore 2>/dev/null || true
fi

# Initialize git if needed
if [ -d .git ]; then
  echo "Git repo already initialized."
else
  echo "Initializing git repository..."
  git init
fi

# Add all and commit (if there are changes)
git add .
if git diff --staged --quiet; then
  echo "No changes to commit."
else
  COMMIT_MSG=$(prompt "Commit message" "Initial commit: magang backend MVP")
  git commit -m "$COMMIT_MSG"
fi

# Ensure branch main
git branch -M main 2>/dev/null || true

# Remote handling
REMOTE_URL=$(prompt "Remote Git SSH URL" "$DEFAULT_REMOTE")

if git remote | grep -q "^origin$"; then
  EXISTING_URL=$(git remote get-url origin)
  echo "Existing remote 'origin' -> $EXISTING_URL"
  if [ "$EXISTING_URL" != "$REMOTE_URL" ]; then
    if confirm "Replace existing 'origin' ($EXISTING_URL) with $REMOTE_URL?"; then
      git remote remove origin
      git remote add origin "$REMOTE_URL"
      echo "Replaced remote origin."
    else
      echo "Keeping existing origin."
    fi
  else
    echo "Remote origin already set to given URL."
  fi
else
  git remote add origin "$REMOTE_URL"
  echo "Added remote origin -> $REMOTE_URL"
fi

# Push to origin main
echo "Pushing to origin main..."
if git ls-remote --exit-code origin main >/dev/null 2>&1; then
  echo "Remote branch main exists. Attempting to pull latest and rebase."
  git pull --rebase origin main || true
fi

git push -u origin main

echo "Push finished."

# Optional: create tag
if confirm "Create annotated tag (e.g. v0.1.0)?"; then
  TAG_NAME=$(prompt "Tag name" "v0.1.0")
  git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
  git push origin "$TAG_NAME"
  echo "Tag $TAG_NAME created and pushed."
  TAG_CREATED=true
else
  TAG_CREATED=false
fi

# Optional: create GitHub release via gh (if installed) and upload zip asset if present
if command -v gh >/dev/null 2>&1; then
  if confirm "Use GitHub CLI to create a release for tag?"; then
    if [ "$TAG_CREATED" != "true" ]; then
      # ask which tag to use
      TAG_SEL=$(prompt "Tag to release (must exist)" "v0.1.0")
    else
      TAG_SEL="$TAG_NAME"
    fi
    RELEASE_TITLE=$(prompt "Release title" "$TAG_SEL")
    RELEASE_NOTES=$(prompt "Release notes (short)" "Initial release")
    # Check for zip asset in parent dir
    ZIP_ASSET="../magang-backend.zip"
    if [ -f "$ZIP_ASSET" ]; then
      echo "Creating release $TAG_SEL and uploading asset $ZIP_ASSET ..."
      gh release create "$TAG_SEL" "$ZIP_ASSET" -t "$RELEASE_TITLE" -n "$RELEASE_NOTES"
    else
      echo "Creating release $TAG_SEL (no asset found)."
      gh release create "$TAG_SEL" -t "$RELEASE_TITLE" -n "$RELEASE_NOTES"
    fi
    echo "Release created via gh."
  fi
else
  echo "gh CLI not found. Skipping GitHub release step."
fi

echo "All done. Verify on GitHub: $REMOTE_URL"
echo "Useful commands:"
echo "  git status"
echo "  git log --oneline -n 5"
echo "  git remote -v"

# end of script
