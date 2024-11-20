import os
from datetime import datetime

def get_file_creation_time(file_path):
    try:
        return datetime.fromtimestamp(os.path.getctime(file_path)).strftime('%Y-%m-%d %H:%M:%S')
    except Exception as e:
        print(f"Error getting creation time for {file_path}: {e}")
        return None

def parse_existing_header(lines):
    header_info = {}
    categories = []
    current_key = None

    for line in lines:
        stripped_line = line.strip()
        if stripped_line == "---":
            continue
        parts = stripped_line.split(':', 1)
        if len(parts) == 2:
            key = parts[0].strip()
            value = parts[1].strip()
            if key == "categories":
                if value:  # Check if value is not an empty string
                    categories.append(value)
                current_key = "categories"
            else:
                if current_key == "categories":
                    header_info[current_key] = categories
                header_info[key] = value
                current_key = key
        elif current_key == "categories":
            if stripped_line.startswith("-"):
                categories.append(stripped_line.lstrip('-').strip())
            else:
                if current_key == "categories":
                    header_info[current_key] = categories
                current_key = None
        else:
            current_key = None

    if current_key == "categories":
        header_info[current_key] = categories

    return header_info

def construct_header_lines(header_info):
    header_lines = ["---\n"]
    for key, value in header_info.items():
        if key == "categories":
            header_lines.append("categories:\n")
            for category in value:
                header_lines.append(f"  - {category}\n")  # Use spaces for indentation
        else:
            header_lines.append(f"{key}: {value}\n")
    header_lines.append("---\n")
    return header_lines

def process_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return

    # Find the second "---" line to determine the end of the header
    second_dash_index = -1
    dash_count = 0
    for i, line in enumerate(lines):
        if line.strip() == "---":
            dash_count += 1
            if dash_count == 2:
                second_dash_index = i
                break

    if second_dash_index != -1:
        header_lines = lines[1:second_dash_index]
        original_content_start = second_dash_index + 1
    else:
        header_lines = []
        original_content_start = 0

    existing_header = parse_existing_header(header_lines)

    # Extract necessary information
    file_name = os.path.splitext(os.path.basename(file_path))[0]
    creation_date = get_file_creation_time(file_path)
    modification_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    if creation_date is None:
        return

    # Prepare new header content
    new_header = {
        "title": file_name,
        "date": creation_date,
        "update": modification_date,
        "toc": True  # Default toc value
    }

    # Update header with existing values if present
    new_header.update(existing_header)

    # Ensure all required keys are present
    if "categories" not in new_header or not new_header["categories"]:
        new_header["categories"] = ["general"]

    if "toc" in new_header and isinstance(new_header["toc"], str):
        new_header["toc"] = new_header["toc"].lower() in ['true', '1', 'yes']

    # Convert boolean toc value to string
    if isinstance(new_header["toc"], bool):
        new_header["toc"] = str(new_header["toc"]).lower()

    # Construct new header lines
    new_header_lines = construct_header_lines(new_header)

    # Combine new header with original content
    new_content = new_header_lines + lines[original_content_start:]

    # Write back to the file without changing the modification time
    try:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(new_content)
        
        # Restore the original modification time
        access_time = os.path.getatime(file_path)
        os.utime(file_path, (access_time, os.path.getmtime(file_path)))
    except Exception as e:
        print(f"Error writing to file {file_path}: {e}")

def main():
    directory = "./source/_posts/"
    try:
        for filename in os.listdir(directory):
            if filename.endswith(".md") or filename.endswith(".txt"):
                file_path = os.path.join(directory, filename)
                process_file(file_path)
    except Exception as e:
        print(f"Error listing files in directory {directory}: {e}")

if __name__ == "__main__":
    main()