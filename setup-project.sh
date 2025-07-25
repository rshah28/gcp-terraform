#!/bin/bash

# GCP Terraform Project Setup Script
# This script helps you replace placeholders with your actual project ID

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GCP Terraform Project Setup${NC}"
echo "=================================="

# Check if project ID is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide your GCP Project ID${NC}"
    echo "Usage: $0 <YOUR_PROJECT_ID>"
    echo "Example: $0 my-awesome-project-123"
    exit 1
fi

PROJECT_ID=$1

echo -e "${YELLOW}Replacing placeholders with project ID: ${PROJECT_ID}${NC}"
echo

# Files to update
FILES=(
    "gke-standard/main.tf"
    "gke-autopilot/main.tf"
    "gke-standard/variables.tf"
    "gke-autopilot/variables.tf"
)

# Replace placeholders in each file
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}Updating ${file}...${NC}"
        
        # Replace <YOUR_PROJECT_ID> with actual project ID
        sed -i.bak "s/<YOUR_PROJECT_ID>/${PROJECT_ID}/g" "$file"
        
        # Remove backup files
        rm -f "${file}.bak"
        
        echo -e "${GREEN}✓ Updated ${file}${NC}"
    else
        echo -e "${RED}✗ File not found: ${file}${NC}"
    fi
done

echo
echo -e "${GREEN}Setup complete!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Complete the prerequisites in README.md"
echo "2. Create your Terraform service account"
echo "3. Create your GCS bucket for state storage"
echo "4. Run: terraform init && terraform plan"
echo
echo -e "${YELLOW}Note:${NC} You may also want to update the Cloud Shell IP in the main.tf files"
echo "for secure cluster access." 