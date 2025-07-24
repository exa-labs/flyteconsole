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
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to login to ECR. Make sure AWS CLI is configured.${NC}"
    exit 1
fi

# Build the Docker image
echo -e "${GREEN}Building Docker image...${NC}"
docker build -t ${ECR_REPOSITORY}:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Docker image.${NC}"
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
    exit 1
fi

echo -e "${GREEN}Successfully pushed ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}${NC}"
echo -e "${GREEN}Build and push completed!${NC}"