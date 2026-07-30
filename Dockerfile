# Multi-stage build for Node.js TypeScript application

# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json ./
COPY package-lock.json ./
COPY tsconfig.json ./
COPY .npmrc /root/.npmrc

# ENV NPM_CONFIG_USERCONFIG=/root/.npmrc
# ENV NPM_CONFIG_REGISTRY='Nexus registry URL'
# ENV NPM_CONFIG_STRICT_SSL=false

# Install all dependencies (including dev dependencies)
RUN npm install --ignore-scripts

# Copy source code
COPY src ./src

# Build the application (using docker-specific script that skips linting/tests)
RUN npm run build:docker

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json ./
COPY package-lock.json ./
COPY .npmrc /root/.npmrc

# ENV NPM_CONFIG_USERCONFIG=/root/.npmrc
# ENV NPM_CONFIG_REGISTRY='Nexus registry URL'
# ENV NPM_CONFIG_STRICT_SSL=false

# Copy dependencies and built app from builder stage
RUN npm install --only=production --ignore-scripts
COPY --from=builder /app/dist ./dist

# Create a non-root user to run the app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /app

USER nodejs

# Expose the port the app runs on
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {r.statusCode === 200 ? process.exit(0) : process.exit(1)})"

# Start the application
CMD ["node", "dist/server.js"]