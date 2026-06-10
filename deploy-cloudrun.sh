#!/bin/bash

# Interactive Google Cloud Run Deployment Script
# YouTube MCP Server Deployment Helper

cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║   YouTube MCP Server - Google Cloud Run Deployment         ║
╚════════════════════════════════════════════════════════════╝

EOF

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to get validated input
get_input() {
    local prompt="$1"
    local default="$2"
    local validation="$3"
    local input

    while true; do
        if [ -z "$default" ]; then
            echo -ne "${YELLOW}${prompt} : ${NC}"
        else
            echo -ne "${YELLOW}${prompt} [${default}]: ${NC}"
        fi

        read -r input

        # Use default if empty
        if [ -z "$input" ]; then
            input="$default"
        fi

        # Check if input is empty
        if [ -z "$input" ]; then
            echo -e "${RED}  ❌ This field is required${NC}"
            continue
        fi

        # Validate if validation function provided
        if [ -n "$validation" ]; then
            if ! eval "$validation '$input'"; then
                continue
            fi
        fi

        echo "$input"
        return 0
    done
}

# Validation functions
validate_api_key() {
    if [ ${#1} -lt 20 ]; then
        echo -e "${RED}  ❌ API Key should be longer (typically 39 characters)${NC}"
        return 1
    fi
    return 0
}

validate_channel_id() {
    if ! [[ "$1" =~ ^UC[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}  ❌ Channel ID should start with 'UC' followed by alphanumeric characters${NC}"
        return 1
    fi
    return 0
}

validate_region_choice() {
    if ! [[ "$1" =~ ^[1-5]$ ]]; then
        echo -e "${RED}  ❌ Please select 1-5${NC}"
        return 1
    fi
    return 0
}

validate_memory() {
    if ! [[ "$1" =~ ^(256Mi|512Mi|1Gi|2Gi|4Gi)$ ]]; then
        echo -e "${RED}  ❌ Must be one of: 256Mi, 512Mi, 1Gi, 2Gi, 4Gi${NC}"
        return 1
    fi
    return 0
}

validate_cpu() {
    if ! [[ "$1" =~ ^[1248]$ ]]; then
        echo -e "${RED}  ❌ Must be 1, 2, 4, or 8${NC}"
        return 1
    fi
    return 0
}

validate_timeout() {
    if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -gt 3600 ]; then
        echo -e "${RED}  ❌ Must be a number between 1 and 3600${NC}"
        return 1
    fi
    return 0
}

# Gather configuration
echo -e "${GREEN}Please provide the following information:${NC}"
echo ""

# YouTube API Key
API_KEY=$(get_input "YouTube API Key" "" "validate_api_key")

# Channel ID
CHANNEL_ID=$(get_input "YouTube Channel ID (e.g., UC_xxxxx)" "" "validate_channel_id")

# GCP Project
PROJECT=$(get_input "GCP Project ID" "emerging-tech-nation")

# Service Name
SERVICE_NAME=$(get_input "Cloud Run Service Name" "youtube-mcp-server")

# Region
echo ""
echo -e "${CYAN}Available regions:${NC}"
echo "  1. us-central1 (N. California) - Default, low latency"
echo "  2. us-west1 (Oregon)"
echo "  3. europe-west1 (Belgium)"
echo "  4. asia-northeast1 (Tokyo)"
echo "  5. australia-southeast1 (Sydney)"
echo ""

REGION_CHOICE=$(get_input "Select region (1-5)" "1" "validate_region_choice")

case $REGION_CHOICE in
    1) REGION="us-central1" ;;
    2) REGION="us-west1" ;;
    3) REGION="europe-west1" ;;
    4) REGION="asia-northeast1" ;;
    5) REGION="australia-southeast1" ;;
esac

# Memory
MEMORY=$(get_input "Memory allocation (e.g., 512Mi, 1Gi, 2Gi)" "512Mi" "validate_memory")

# CPU
CPU=$(get_input "CPU allocation (1, 2, 4, or 8)" "1" "validate_cpu")

# Timeout
TIMEOUT=$(get_input "Request timeout in seconds (max 3600)" "3600" "validate_timeout")

# Allow unauthenticated
echo ""
echo -ne "${YELLOW}Allow unauthenticated requests? (y/n) [y]: ${NC}"
read -r ALLOW_UNAUTHENTICATED
ALLOW_UNAUTHENTICATED=${ALLOW_UNAUTHENTICATED:-y}

# Summary
echo ""
cat << EOF
╔════════════════════════════════════════════════════════════╗
║                    DEPLOYMENT SUMMARY                     ║
╚════════════════════════════════════════════════════════════╝

  Service Name:      $SERVICE_NAME
  GCP Project:       $PROJECT
  Region:            $REGION
  Memory:            $MEMORY
  CPU:               $CPU
  Timeout:           $TIMEOUT seconds
  Public Access:     $([ "$ALLOW_UNAUTHENTICATED" = "y" ] && echo "Yes" || echo "No")
  Image:             gcr.io/$PROJECT/$SERVICE_NAME:latest

  API Key will be set as environment variable
  Channel ID will be set as environment variable

EOF

# Confirm deployment
echo -ne "${YELLOW}Proceed with deployment? (y/n) [y]: ${NC}"
read -r CONFIRM
CONFIRM=${CONFIRM:-y}

if [ "$CONFIRM" != "y" ]; then
    echo ""
    echo -e "${RED}Deployment cancelled.${NC}"
    exit 0
fi

# Build deployment command
echo ""
echo -e "${GREEN}Building and executing deployment command...${NC}"
echo ""

# Build command array
CMD=(
    "gcloud" "run" "deploy" "$SERVICE_NAME"
    "--image" "gcr.io/$PROJECT/$SERVICE_NAME:latest"
    "--platform" "managed"
    "--region" "$REGION"
    "--memory" "$MEMORY"
    "--cpu" "$CPU"
    "--timeout" "$TIMEOUT"
    "--set-env-vars" "YOUTUBE_API_KEY=$API_KEY,CHANNEL_ID=$CHANNEL_ID"
)

if [ "$ALLOW_UNAUTHENTICATED" = "y" ]; then
    CMD+=("--allow-unauthenticated")
fi

CMD+=("--project" "$PROJECT")

# Execute deployment
"${CMD[@]}"

if [ $? -eq 0 ]; then
    echo ""
    cat << EOF
╔════════════════════════════════════════════════════════════╗
║         ✅ DEPLOYMENT SUCCESSFUL!                         ║
╚════════════════════════════════════════════════════════════╝

EOF
    echo -e "${YELLOW}Getting your service URL...${NC}"
    echo ""

    gcloud run services describe "$SERVICE_NAME" \
        --region "$REGION" \
        --project "$PROJECT" \
        --format='value(status.url)'

    echo ""
    echo -e "${CYAN}Test your service:${NC}"
    echo -e "  ${WHITE}curl https://<your-service-url>/health${NC}"
    echo ""
    echo -e "${CYAN}View logs:${NC}"
    echo -e "  ${WHITE}gcloud run logs read $SERVICE_NAME --region $REGION --project $PROJECT --limit 50${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Deployment failed. Check the error above.${NC}"
    exit 1
fi
