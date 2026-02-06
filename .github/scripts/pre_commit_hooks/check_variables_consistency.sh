#!/usr/bin/env bash
# Check consistency between root variables.tf and example variables.tf files
# This hook ensures that when variables.tf is modified, the differences are
# visible and can be reviewed for potential updates to example configurations.

set -e

# Disable git pager to prevent hanging
export GIT_PAGER=cat

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Track if we found any variables.tf files
found_root_vars=0
found_example_vars=0
has_differences=0

# Find root variables.tf
ROOT_VARS="./variables.tf"

# Check if root variables.tf is in the staged files
for file in "$@"; do
  if [[ "$file" == "variables.tf" ]] || [[ "$file" == "./variables.tf" ]]; then
    found_root_vars=1
    break
  fi
done

# Find all example variables.tf files
EXAMPLE_VARS_FILES=()
for file in "$@"; do
  if [[ "$file" == examples/*/variables.tf ]]; then
    EXAMPLE_VARS_FILES+=("$file")
    found_example_vars=1
  fi
done

# If no variables.tf files are being modified, exit successfully
if [[ $found_root_vars -eq 0 ]] && [[ $found_example_vars -eq 0 ]]; then
  exit 0
fi

echo -e "${YELLOW}Checking variables.tf consistency...${NC}"
echo

# If root variables.tf is modified, show diff against each example
if [[ $found_root_vars -eq 1 ]]; then
  # Find all example directories
  for example_vars in examples/*/variables.tf; do
    if [[ -f "$example_vars" ]]; then
      echo -e "${YELLOW}Comparing root variables.tf with $example_vars${NC}"
      echo "-------------------------------------------"
      
      # Use git diff to show differences (if files are different)
      if ! diff -q "$ROOT_VARS" "$example_vars" > /dev/null 2>&1; then
        git diff --no-index --color=always "$ROOT_VARS" "$example_vars" || true
        has_differences=1
        echo
      else
        echo -e "${GREEN}✓ Files are identical${NC}"
        echo
      fi
    fi
  done
fi

# If any example variables.tf is modified, show diff against root
if [[ $found_example_vars -eq 1 ]]; then
  for example_vars in "${EXAMPLE_VARS_FILES[@]}"; do
    if [[ -f "$ROOT_VARS" ]]; then
      echo -e "${YELLOW}Comparing $example_vars with root variables.tf${NC}"
      echo "-------------------------------------------"
      
      if ! diff -q "$ROOT_VARS" "$example_vars" > /dev/null 2>&1; then
        git diff --no-index --color=always "$ROOT_VARS" "$example_vars" || true
        has_differences=1
        echo
      else
        echo -e "${GREEN}✓ Files are identical${NC}"
        echo
      fi
    fi
  done
fi

# Informational message - this is not a failure, just awareness
if [[ $has_differences -eq 1 ]]; then
  echo -e "${YELLOW}ℹ  Variables differences detected between root and examples.${NC}"
  echo -e "${YELLOW}   Review the changes above to determine if example variables need updating.${NC}"
  echo
fi

# Always exit successfully - this is informational only
exit 0
