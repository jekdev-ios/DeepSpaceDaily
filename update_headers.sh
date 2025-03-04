#!/bin/bash

# Script to add standard headers to Swift files
# Format:
# //
# //  filename.swift
# //  DeepSpaceDaily
# //
# //  Created by admin on 29/02/25.
# //

# Find all Swift files in the project
find . -name "*.swift" | while read -r file; do
    # Get the filename without path
    filename=$(basename "$file")
    
    # Skip files in Pods directory if they exist
    if [[ "$file" == *"/Pods/"* ]]; then
        echo "Skipping $file (in Pods directory)"
        continue
    fi
    
    # Skip files in .build directory if they exist
    if [[ "$file" == *"/.build/"* ]]; then
        echo "Skipping $file (in .build directory)"
        continue
    fi
    
    # Check if the file already has a header (looking for the pattern "// Created by")
    if grep -q "//  Created by" "$file"; then
        echo "Skipping $file (already has a header)"
        continue
    fi
    
    echo "Adding header to $file"
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Write the header to the temporary file
    cat > "$temp_file" << EOF
//
//  $filename
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

EOF
    
    # Append the original file content to the temporary file
    cat "$file" >> "$temp_file"
    
    # Replace the original file with the temporary file
    mv "$temp_file" "$file"
    
    echo "Header added to $file"
done

echo "Header update completed!" 