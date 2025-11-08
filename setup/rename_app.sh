#!/bin/bash

# Script to rename the Phoenix app from "phenom" to your custom app name
# Usage: ./rename_app.sh your_app_name

set -e

if [ $# -eq 0 ]; then
    echo "Usage: ./rename_app.sh your_app_name"
    echo "Example: ./rename_app.sh my_awesome_app"
    exit 1
fi

NEW_APP_NAME=$1
NEW_APP_NAME_LOWER=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]')
NEW_APP_NAME_CAMEL=$(echo "$NEW_APP_NAME" | sed -r 's/(^|_)([a-z])/\U\2/g')

OLD_APP_NAME="phenom"
OLD_APP_NAME_CAMEL="Phenom"

echo "Renaming app from '$OLD_APP_NAME' to '$NEW_APP_NAME_LOWER'"
echo "CamelCase: '$OLD_APP_NAME_CAMEL' to '$NEW_APP_NAME_CAMEL'"
echo ""

# Confirm with user
read -p "This will modify files in your project. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Starting rename process..."

# Get list of files to process (respecting .gitignore)
if command -v git &> /dev/null && [ -d .git ]; then
    echo "Using git to find tracked files..."
    FILES=$(git ls-files)
else
    echo "Git not found, using find with basic exclusions..."
    FILES=$(find . -type f \
        -not -path "./.git/*" \
        -not -path "./_build/*" \
        -not -path "./deps/*")
fi

# Replace in file contents
echo "Replacing text in files..."
for file in $FILES; do
    if [ -f "$file" ]; then
        # Skip binary files
        if file "$file" | grep -q text; then
            # Replace lowercase versions
            sed -i.bak "s/$OLD_APP_NAME/$NEW_APP_NAME_LOWER/g" "$file"
            # Replace CamelCase versions
            sed -i.bak "s/$OLD_APP_NAME_CAMEL/$NEW_APP_NAME_CAMEL/g" "$file"
            # Remove backup files
            rm -f "$file.bak"
        fi
    fi
done

# Rename directories (only in tracked directories)
echo "Renaming directories..."
if command -v git &> /dev/null && [ -d .git ]; then
    git ls-files | xargs -n1 dirname | sort -u | grep "$OLD_APP_NAME" | while read dir; do
        new_dir=$(echo "$dir" | sed "s/$OLD_APP_NAME/$NEW_APP_NAME_LOWER/g")
        if [ -d "$dir" ] && [ "$dir" != "$new_dir" ]; then
            echo "Renaming directory: $dir -> $new_dir"
            mv "$dir" "$new_dir"
        fi
    done
else
    find . -depth -type d -name "*$OLD_APP_NAME*" \
        -not -path "./.git/*" \
        -not -path "./_build/*" \
        -not -path "./deps/*" | while read dir; do
        new_dir=$(echo "$dir" | sed "s/$OLD_APP_NAME/$NEW_APP_NAME_LOWER/g")
        if [ "$dir" != "$new_dir" ]; then
            echo "Renaming directory: $dir -> $new_dir"
            mv "$dir" "$new_dir"
        fi
    done
fi

# Rename files
echo "Renaming files..."
if command -v git &> /dev/null && [ -d .git ]; then
    git ls-files | grep "$OLD_APP_NAME" | while read file; do
        new_file=$(echo "$file" | sed "s/$OLD_APP_NAME/$NEW_APP_NAME_LOWER/g")
        if [ -f "$file" ] && [ "$file" != "$new_file" ]; then
            echo "Renaming file: $file -> $new_file"
            mkdir -p "$(dirname "$new_file")"
            mv "$file" "$new_file"
        fi
    done
else
    find . -type f -name "*$OLD_APP_NAME*" \
        -not -path "./.git/*" \
        -not -path "./_build/*" \
        -not -path "./deps/*" | while read file; do
        new_file=$(echo "$file" | sed "s/$OLD_APP_NAME/$NEW_APP_NAME_LOWER/g")
        if [ "$file" != "$new_file" ]; then
            echo "Renaming file: $file -> $new_file"
            mv "$file" "$new_file"
        fi
    done
fi

echo ""
echo "Rename complete!"
echo ""
echo "Next steps:"
echo "1. Review the changes with: git diff"
echo "2. Update your .env file if needed"
echo "3. Clean and rebuild: mix deps.clean --all && mix deps.get"
echo "4. Run tests: mix test"
echo "5. Update database: mix ecto.drop && mix ecto.setup"
echo ""
echo "Don't forget to update:"
echo "- Any external service configurations"
echo "- CI/CD pipelines"
echo "- Documentation"
