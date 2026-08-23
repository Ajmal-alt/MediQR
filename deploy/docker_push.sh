#!/bin/bash
# ============================================
# MediQR V3 - Docker Build & Push Script
# ============================================
# Usage:
#   1. Login to Docker Hub:  docker login
#   2. Run:  bash deploy/docker_push.sh YOUR_DOCKER_USERNAME
# ============================================

set -e

DOCKER_USERNAME=$1
IMAGE_NAME="mediqr-backend"
TAG="v3.0.0"

if [ -z "$DOCKER_USERNAME" ]; then
  echo "Error: Please provide your Docker Hub username"
  echo "Usage: bash deploy/docker_push.sh YOUR_DOCKER_USERNAME"
  exit 1
fi

echo "=========================================="
echo " Building MediQR Backend Docker Image"
echo "=========================================="

# Build the image
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:$TAG ./backend
docker tag $DOCKER_USERNAME/$IMAGE_NAME:$TAG $DOCKER_USERNAME/$IMAGE_NAME:latest

echo ""
echo "=========================================="
echo " Pushing to Docker Hub"
echo "=========================================="

# Push to Docker Hub
docker push $DOCKER_USERNAME/$IMAGE_NAME:$TAG
docker push $DOCKER_USERNAME/$IMAGE_NAME:latest

echo ""
echo "=========================================="
echo " Success! Image pushed to Docker Hub"
echo "=========================================="
echo ""
echo "Image: $DOCKER_USERNAME/$IMAGE_NAME:$TAG"
echo ""
echo "To pull on EC2:"
echo "  docker pull $DOCKER_USERNAME/$IMAGE_NAME:$TAG"
echo ""