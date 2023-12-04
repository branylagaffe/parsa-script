#!/usr/bin/env bash
# 
#  _    _ _                  _                                _            _           _   
# | |  | | |                | |                              | |          | |         | |  
# | |  | | |__   ___     ___| |__   __ _ _ __   __ _  ___  __| | __      _| |__   __ _| |_ 
# | |/\| | '_ \ / _ \   / __| '_ \ / _` | '_ \ / _` |/ _ \/ _` | \ \ /\ / / '_ \ / _` | __|
# \  /\  / | | | (_) | | (__| | | | (_| | | | | (_| |  __/ (_| |  \ V  V /| | | | (_| | |_ 
#  \/  \/|_| |_|\___/   \___|_| |_|\__,_|_| |_|\__, |\___|\__,_|   \_/\_/ |_| |_|\__,_|\__|
#                                               __/ |                                      
#                                              |___/                                       
# 
# Created Date: Monday, December 4th 2023, 12:09:00 am
# Author: Bryan `Brany` Perdrizat
# 

# Stop on error
set -e

# Set current working dir to script dir
CWD="$(dirname "$(realpath -- "$0")")"

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file> <output_file>"
    exit 1
fi

# Parse input file argument
input_file=${1}
input_path=$(realpath ${input_file})
input=$(<$input_path)

# Read and parse input file header
repo_path="$(head -1  ${input_path} | tr -d '<>' | awk -F: '{print $1}')"
repo_branch="$(head -1  ${input_path} | tr -d '<>' | awk -F: '{print $2}')"

# Configure output filename
if [ ! -n "${2}" ]; then
    output_file="diff_${repo_branch}.txt"
else
    output_file=${2}
fi

output_path=${CWD}/${output_file}
touch ${output_path}

# Get the number of line in the input file to avoid reading the header
declare -i nb_line
nb_line=$(wc -l ${input_path} | awk -F' ' '{print $1}')-1

# Quiet checkout
git -C ${repo_path} switch -q ${repo_branch}

echo "# ──────────────────────────────────────────────────────────────────────────────" >  "$output_path"
echo "# $(head -1 ${input_path})"                                                       >> "$output_path"
echo "# ──────────────────────────────────────────────────────────────────────────────" >> "$output_path"

# Gather all commits from new authors
for author in $(tail -n${nb_line} ${input_path}); do
    # Get all commits for a specific author
    all_commits="$(git -C ${repo_path} log --author="${author}" --format="%H" --no-merges | sed -e 's/\n/ /g')"

    # Abort iteration if no commit was found
    if [ ! -n "$all_commits" ]; then
        continue
    fi

    # Get modified files for each commit
    modified_files="$(git -C ${repo_path} show --format="%n%as %h %s" --name-only ${all_commits})"

    # File output
    echo "─── ${author} ───────────────────────────────────────────────────────────────────" >> "$output_path"
    echo "${modified_files}" >> "$output_path"
done
