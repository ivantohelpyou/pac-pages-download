#!/bin/bash

# Enable exit on error
set -e

# Change History:
# 1. Added a -verbose flag to enable verbose output.
# 2. Added an -overwrite or -o flag to handle overwriting existing folders.
# 3. Adjusted the script to handle 1-based indexing as displayed by pac powerpages list.
# 4. Converted the 1-based index to a 0-based index for internal processing.
# 5. Sanitized the friendly name to create a safe folder name by removing or replacing special characters.
# 6. Added error handling to check if the folder already existed and prompt for confirmation if the -overwrite flag was not set.
# 7. Ensured the script exited gracefully if the user chose not to overwrite the existing folder.
# 8. Ensured the correct usage of the --websiteid flag and --modelVersion 2 in the pac powerpages download command.
# 9. Added logic to create a deployment profile folder and YAML file if it doesn't already exist.
# 10. Added logic to generate dynamic GUIDs for adx_sitesettingid values using Python.
# 11. Included Webapi/error/innererror setting only if no profile is provided, assuming dev/test environments.
# 12. Ensured the deployment profile folder is created inside the actual folder containing the downloaded portal content.

# Check for verbose and overwrite flags
VERBOSE=false
OVERWRITE=false
PROFILE=""
while [[ "$1" == -* ]]; do
    case "$1" in
        -verbose) VERBOSE=true ;;
        -o|-overwrite) OVERWRITE=true ;;
        -profile) PROFILE="$2"; shift ;;
    esac
    shift
done

# Enable debugging if verbose flag is set
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Function to generate UUID using Python
generate_uuid() {
    python -c 'import uuid; print(uuid.uuid4())'
}

# Authenticate to the Power Platform environment if not already authenticated
if pac auth list | grep -q "mixtape-dev"; then
    echo "Already authenticated to the mixtape-dev environment."
else
    pac auth create --environment mixtape-dev
fi

# List current authentication profiles
pac auth list

# List Power Pages
pac powerpages list

# Capture the output of `pac powerpages list` into an array
mapfile -t powerpages_list < <(pac powerpages list | awk '/^[[:space:]]*\[[0-9]+\]/ {print $2, $3, $4, $5, $6, $7, $8, $9, $10}')

# Print the array for verification
for i in "${!powerpages_list[@]}"; do
    echo "$((i+1)): ${powerpages_list[$i]}"
done

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "No index provided. Showing the list of Power Pages."
else
    index=$(( $1 - 1 ))  # Convert 1-based index to 0-based index
    if [[ $index =~ ^[0-9]+$ ]] && [ $index -ge 0 ] && [ $index -lt ${#powerpages_list[@]} ]; then
        # Extract the WebSiteId-GUID and friendly name from the selected entry
        selected_page=${powerpages_list[$index]}
        website_id=$(echo "$selected_page" | awk '{print $1}')
        friendly_name=$(echo "$selected_page" | awk '{print substr($0, index($0,$2))}')

        # Sanitize the friendly name to create a safe folder name
        sanitized_friendly_name=$(echo "$friendly_name" | tr -cd '[:alnum:]_-')

        # Create a new folder in the current directory using the sanitized friendly name
        folder_name="powerpage_${sanitized_friendly_name}"

        # Check if the folder already exists
        if [ -d "$folder_name" ]; then
            if [ "$OVERWRITE" = true ]; then
                echo "Overwriting existing folder $folder_name..."
                rm -rf "$folder_name"
            else
                read -p "Folder $folder_name already exists. Overwrite? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -rf "$folder_name"
                else
                    echo "Aborting download."
                    exit 1
                fi
            fi
        fi

        mkdir -p "$folder_name"

        # Download the selected Power Page
        echo "Downloading website with ID $website_id into folder $folder_name..."
        pac powerpages download --path "$folder_name" --websiteid "$website_id" --modelVersion 2
        echo "Downloaded Power Page to $folder_name"

        # Determine the actual folder name created by the download command
        actual_folder_name=$(find "$folder_name" -mindepth 1 -maxdepth 1 -type d)

        # Generate dynamic GUIDs for adx_sitesettingid using Python
        webapi_new_invoiceline_enabled_id=$(generate_uuid)
        webapi_new_invoiceline_fields_id=$(generate_uuid)
        webapi_error_innererror_id=$(generate_uuid)

        # Check if deployment profile exists, if not create it with dynamic GUIDs
        profile_folder="$actual_folder_name/deployment-profiles"
        profile_file="$profile_folder/${PROFILE}.deployment.yml"
        if [ -n "$PROFILE" ] && [ ! -f "$profile_file" ]; then
            echo "Creating deployment profile $profile_file..."
            mkdir -p "$profile_folder"
            cat <<EOL > "$profile_file"
# Deployment profile for $PROFILE environment
adx_sitesetting:
  - adx_sitesettingid: $webapi_new_invoiceline_enabled_id
    adx_value: true
    adx_name: Webapi/new_invoiceline/enabled
  - adx_sitesettingid: $webapi_new_invoiceline_fields_id
    adx_value: *
    adx_name: Webapi/new_invoiceline/fields
EOL
            # Include Webapi/error/innererror setting only if no profile is provided
            if [ -z "$PROFILE" ]; then
                cat <<EOL >> "$profile_file"
  - adx_sitesettingid: $webapi_error_innererror_id
    adx_value: true
    adx_name: Webapi/error/innererror
EOL
            fi
            echo "Created deployment profile $profile_file"
        fi
    else
        echo "Invalid index provided. Please provide a valid index number."
    fi
fi

