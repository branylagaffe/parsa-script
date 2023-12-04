#!/usr/bin/env bash

# Quit on first error
set -e

# Set current working dir to script dir
CWD="$(dirname "$(realpath -- "$0")")"
echo ">> CWD: ${CWD}"

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <source git_dir:branch> <target git_dir:branch>"
    exit 1
fi

# Parse arguement
# Split <repos dir>:<branch> into two different variable
src_repo=$(echo ${1} | awk -F':' '{ print $1 }')
src_branch=$(echo ${1} | awk -F':' '{ print $2 }')
target_repo=$(echo ${2} | awk -F':' '{ print $1 }')
target_branch=$(echo ${2} | awk -F':' '{ print $2 }')

src_dir=$(realpath ${src_repo})
target_dir=$(realpath ${target_repo})

file=${3}

# Output the parsed variable
echo ">> SRC: ${src_repo}:${src_branch}"
echo ">> TARGET: ${target_repo}:${target_branch}"
echo ">> OUTPUT: ${file}"

# Pull directory if branch is missing
git -C ${src_dir} switch -q ${src_branch}
git -C ${target_dir} switch -q ${target_branch}

# Output uniq author list for both source and target repository
src_author=$(git -C ${src_dir} log --format="%ae" ${src_branch} | sort -u)
target_author=$(git -C ${target_dir} log --format="%ae" ${target_branch} | sort -u)

# Create diff between source and target repository | get the new addition | and remove the '>' char
new_authors=$(diff <(echo "$src_author") <(echo "$target_author") | egrep "^>" | sed 's/> //g')

echo -e ">> NEW: ${new_authors}" | tr '\n' ' '

# Output the author onto a file
echo "<${target_dir}:${target_branch}>" > "$file"
echo "$(echo "${new_authors}" | sort -u)" >> "$file"