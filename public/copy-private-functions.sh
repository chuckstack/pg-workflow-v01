#!/bin/bash

set -e

################################################
# Script description:
#
# This script converts a file with SQL CREATE FUNCTION statements from a private schema
# into a file with CREATE FUNCTION statements for a public schema. It preserves the function
# comments, adds a prefix to the function name (e.g., api_), and saves the newly created file
# to the current directory of the script (not the directory of the file passed in).
#
# The script does the following:
#
# 1. It checks if an input file is provided as a command-line argument. If not, it displays
#    the usage message and exits.
#
# 2. It sets the input file name based on the provided argument and generates the output file
#    name by appending "_api" to the input file name (without the extension).
#
# 3. It reads the input file line by line using a `while` loop.
#
# 4. For each line, it checks if the line starts with "CREATE FUNCTION":
#    - If it does, it extracts the function name using `awk` and stores it in a variable.
#    - It creates the public function statement by replacing the private function name with
#      the public function name (adding the "api_" prefix) and referring to the private
#      function in the function body.
#    - It writes the public function statement to the output file.
#
# 5. If the line starts with "COMMENT ON FUNCTION":
#    - It extracts the comment in quotes using `sed`.
#    - It adds the "api_" prefix to the function name.
#    - It rebuilds the comment line using the extracted comment and the modified function name.
#    - It writes the modified comment to the output file.
#    - It adds an empty line after the comment in the output file.
#
# 6. Finally, it displays a success message indicating that the public functions have been
#    created in the output file.
################################################

# Check if the input file is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

# load the script name and path into variables and change to the current directory
TEST_SCRIPTNAME=$(readlink -f "$0")
TEST_SCRIPTPATH=$(dirname "$TEST_SCRIPTNAME")
TEST_SCRIPTBASENAME=$(basename "$0")
cd $TEST_SCRIPTPATH

# load the input file name and path into variables
TEST_TARGETNAME=$(readlink -f "$1")
TEST_TARGETPATH=$(dirname "$TEST_TARGETNAME")
TEST_TARGETBASENAME=$(basename "$1")

input_file=$1
script_dir=$TEST_SCRIPTPATH
output_file="$script_dir/${TEST_TARGETBASENAME%.*}_api.sql"

rm -f $output_file

# Process each line of the input file
while IFS= read -r line; do
  # Check if the line starts with "CREATE FUNCTION" and is not indented
  if [[ $line =~ ^CREATE\ FUNCTION ]] && [[ $line != *" "* ]]; then
    # Extract the function name
    function_name=$(echo "$line" | awk '{print $3}')
    public_function_name=$(echo "$function_name" | sed 's/stack_\(wf_\)\?/api_/')

    # Create the public function statement
    public_function_statement=$(cat <<EOF
CREATE FUNCTION $public_function_name
RETURNS text AS
\$BODY\$
BEGIN
  RETURN wf_private.$function_name;
END;
\$BODY\$
LANGUAGE plpgsql
SECURITY DEFINER;
EOF
)

    # Write the public function statement to the output file
    echo "$public_function_statement" >> "$output_file"
  elif [[ $line =~ ^COMMENT\ ON\ FUNCTION ]]; then
    # Extract the comment in quotes
    comment=$(echo "$line" | sed -n "s/.*'\(.*\)'.*/\1/p")

    # Add the "api_" prefix to the function name
    public_function_name=$(echo "$function_name" | sed 's/stack_\(wf_\)\?/api_/')

    # Rebuild the comment line
    comment_line="COMMENT ON FUNCTION $public_function_name IS '$comment';"

    # Write the modified comment to the output file
    echo "$comment_line" >> "$output_file"

    # Add an empty line after the comment
    echo "" >> "$output_file"
  fi
done < "$input_file"

echo "Public functions created successfully in $output_file"
