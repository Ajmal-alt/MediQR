# MediQR V3 Backend - Dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files first (better layer caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY . .

# Create directories for videos and images
RUN mkdir -p videos images

# Expose port
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]