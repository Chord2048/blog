#!/bin/bash

# Function to get file creation time
get_file_creation_time() {
    local file_path="$1"
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        stat -c %y "$file_path" | cut -d' ' -f1,2
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # For Windows using Git Bash or WSL, use the following command
        stat -c %y "$file_path" | cut -d' ' -f1,2
    else
        echo "File creation time retrieval not supported on this OS."
        return 1
    fi
}

# Function to parse existing header
parse_existing_header() {
    local lines=("$@")
    local header_info=""
    local categories=()
    local current_key=""

    for line in "${lines[@]}"; do
        stripped_line=$(echo "$line" | xargs)
        if [[ "$stripped_line" == "---" ]]; then
            continue
        fi
        IFS=':' read -r key value <<< "$stripped_line"
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        if [[ "$key" == "categories" ]]; then
            if [[ -n "$value" ]]; then
                categories+=("$value")
            fi
            current_key="categories"
        else
            if [[ "$current_key" == "categories" ]]; then
                header_info+="categories=${categories[*]};"
            fi
            header_info+="$key=$value;"
            current_key="$key"
        fi
    done

    if [[ "$current_key" == "categories" ]]; then
        header_info+="categories=${categories[*]};"
    fi

    echo "$header_info"
}

# Function to construct header lines
construct_header_lines() {
    local header_info="$1"
    local header_lines=("---")

    IFS=';' read -ra pairs <<< "$header_info"
    for pair in "${pairs[@]}"; do
        IFS='=' read -r key value <<< "$pair"
        if [[ "$key" == "categories" ]]; then
            header_lines+=("categories:")
            IFS=' ' read -ra cats <<< "$value"
            for cat in "${cats[@]}"; do
                header_lines+=("\t-$cat")
            done
        else
            header_lines+=("$key: $value")
        fi
    done
    header_lines+=("---")

    printf "%s\n" "${header_lines[@]}"
}

# Main function to process files
process_files() {
    local directory="./source/_posts/"
    local files=("$directory"/*.md "$directory"/*.txt)

    for file in "${files[@]}"; do
        if [[ ! -e "$file" ]]; then
            echo "No .md or .txt files found in $directory"
            break
        fi

        mapfile -t lines < "$file"

        # Find the second "---" line to determine the end of the header
        second_dash_index=-1
        dash_count=0
        for i in "${!lines[@]}"; do
            if [[ "${lines[$i]}" == "---" ]]; then
                ((dash_count++))
                if ((dash_count == 2)); then
                    second_dash_index=$i
                    break
                fi
            fi
        done

        if ((second_dash_index != -1)); then
            header_lines=("${lines[@]:1:$second_dash_index-1}")
            original_content_start=$((second_dash_index + 1))
        else
            header_lines=()
            original_content_start=0
        fi

        header_info=$(parse_existing_header "${header_lines[@]}")

        # Extract necessary information
        file_name=$(basename -- "$file" | sed 's/\.[^.]*$//')
        creation_date=$(get_file_creation_time "$file")
        modification_date=$(date +"%Y-%m-%d %H:%M:%S")

        if [[ -z "$creation_date" ]]; then
            continue
        fi

        # Prepare new header content
        new_header="title=$file_name;date=$creation_date;update=$modification_date;categories=-general;toc=false;$header_info"

        # Update header with existing values if present
        IFS=';' read -ra pairs <<< "$new_header"
        declare -A updated_header
        for pair in "${pairs[@]}"; do
            IFS='=' read -r key value <<< "$pair"
            updated_header["$key"]="$value"
        done

        # Ensure all required keys are present
        if [[ -z "${updated_header[categories]}" ]]; then
            updated_header[categories]="-general"
        fi

        if [[ "${updated_header[toc]}" =~ ^(true|1|yes)$ ]]; then
            updated_header[toc]="true"
        else
            updated_header[toc]="false"
        fi

        # Construct new header lines
        new_header_lines=$(construct_header_lines "$(declare -p updated_header)")

        # Combine new header with original content
        new_content=($new_header_lines "${lines[@]:$original_content_start}")

        # Write back to the file without changing the modification time
        access_time=$(stat -c %X "$file")
        printf "%s\n" "${new_content[@]}" > "$file"
        touch -a -m -t "$(date -d @${access_time} +%Y%m%d%H%M.%S)" "$file"
    done
}

# Run the main function
process_files

# Step 2: Git pull
echo "Executing git pull..."
git pull

# Step 3: Get hostname and timestamp
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Commit message
COMMIT_MESSAGE="${HOSTNAME}_${TIMESTAMP}"

# Step 4: Git commit
echo "Executing git commit with message: $COMMIT_MESSAGE..."
git commit -a -m "$COMMIT_MESSAGE"

# Step 5: Git push
echo "Executing git push..."
git push