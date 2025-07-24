#!/bin/bash

# ECR repository details
ECR_REGISTRY="472386928882.dkr.ecr.us-west-2.amazonaws.com"
ECR_REPOSITORY="flyteconsole"
IMAGE_TAG="latest"
REGION="us-west-2"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting build and push process for flyteconsole...${NC}"

# Login to ECR
echo -e "${GREEN}Logging into ECR...${NC}"

# Work around for macOS credential store issues
# First, get the ECR login token
ECR_TOKEN=$(aws ecr get-login-password --region ${REGION})

if [ -z "$ECR_TOKEN" ]; then
    echo -e "${RED}Failed to get ECR login token. Make sure AWS CLI is configured.${NC}"
    exit 1
fi

# Use the token to login, explicitly avoiding credential store
echo "$ECR_TOKEN" | docker login --username AWS --password-stdin ${ECR_REGISTRY} 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to login to ECR. Trying alternative method...${NC}"
    # Alternative: Create a temporary config without credential store
    DOCKER_CONFIG=$(mktemp -d)
    echo '{"auths":{}}' > "$DOCKER_CONFIG/config.json"
    echo "$ECR_TOKEN" | DOCKER_CONFIG="$DOCKER_CONFIG" docker login --username AWS --password-stdin ${ECR_REGISTRY}

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to login to ECR even with alternative method.${NC}"
        rm -rf "$DOCKER_CONFIG"
        exit 1
    fi

    # Export the temporary config for subsequent commands
    export DOCKER_CONFIG="$DOCKER_CONFIG"
    echo -e "${GREEN}Successfully logged in using alternative method.${NC}"
else
    echo -e "${GREEN}Successfully logged into ECR.${NC}"
fi

# Build the Docker image
echo -e "${GREEN}Building Docker image...${NC}"
docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Docker image.${NC}"
    [ -n "$DOCKER_CONFIG" ] && [ "$DOCKER_CONFIG" != "$HOME/.docker" ] && rm -rf "$DOCKER_CONFIG"
    exit 1
fi

# Tag the image for ECR
echo -e "${GREEN}Tagging image for ECR...${NC}"
docker tag ${ECR_REPOSITORY}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}

# Push the image to ECR
echo -e "${GREEN}Pushing image to ECR...${NC}"
docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to push image to ECR.${NC}"
    [ -n "$DOCKER_CONFIG" ] && [ "$DOCKER_CONFIG" != "$HOME/.docker" ] && rm -rf "$DOCKER_CONFIG"
    exit 1
fi

# Clean up temporary Docker config if we created one
[ -n "$DOCKER_CONFIG" ] && [ "$DOCKER_CONFIG" != "$HOME/.docker" ] && rm -rf "$DOCKER_CONFIG"

echo -e "${GREEN}Successfully pushed ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}${NC}"
echo -e "${GREEN}Build and push completed!${NC}"
