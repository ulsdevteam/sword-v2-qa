#!/bin/bash

# Function to log HTTP headers and response body
log_error() {
    echo "Error: $1"
    echo "HTTP Headers: $2"
    echo "Response Body: $3"
}

# Validate the input and endpoint
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <SWORDv2_endpoint> <API_key>"
    exit 1
fi

ENDPOINT="$1"
API_KEY="$2"
INPUT_DIR="input"

# Request the SWORD v2 service document
response=$(curl -s -D - -H "Api-key: $API_KEY" "$ENDPOINT/service-document" -o response_body.txt)
status_code=$(echo "$response" | grep HTTP | awk '{print $2}')

if [ "$status_code" -ne 200 ]; then
    log_error "Failed to retrieve service document" "$response" "$(cat response_body.txt)"
    exit 1
fi

# Parse the service document to find collections
collections=$(xmllint --xpath "//collection/@href" response_body.txt)

# Loop through each collection
for collection in $collections; do
    collection_url=$(echo $collection | tr -d '"')

    # Check for deposits in the input directory
    for deposit_dir in "$INPUT_DIR"/*; do
        if [ -d "$deposit_dir" ]; then
            metadata_file="$deposit_dir/metadata.xml"
            deposit_files_dir="$deposit_dir/files"

            # Deposit the metadata.xml file
            metadata_response=$(curl -s -D - -H "Api-key: $API_KEY" -H "Content-Type: application/xml" --data @"$metadata_file" "$collection_url" -o metadata_response_body.txt)
            metadata_status_code=$(echo "$metadata_response" | grep HTTP | awk '{print $2}')

            if [ "$metadata_status_code" -ne 201 ]; then
                log_error "Failed to deposit metadata" "$metadata_response" "$(cat metadata_response_body.txt)"
                continue
            fi

            # Get the edit URI from the response
            edit_uri=$(xmllint --xpath "//entry/link[@rel='edit']/@href" metadata_response_body.txt | tr -d '"')

            # Loop through deposit files and add them to the edit URI
            for deposit_file in "$deposit_files_dir"/*; do
                file_response=$(curl -s -D - -H "Api-key: $API_KEY" -H "Content-Disposition: attachment; filename=$(basename "$deposit_file")" --data-binary @"$deposit_file" "$edit_uri" -o file_response_body.txt)
                file_status_code=$(echo "$file_response" | grep HTTP | awk '{print $2}')

                if [ "$file_status_code" -ne 200 ]; then
                    log_error "Failed to deposit file: $(basename "$deposit_file")" "$file_response" "$(cat file_response_body.txt)"
                fi
            done
        fi
    done
done

echo "Script finished successfully."
