# Factorio Mod Validator - Production Docker Image
# Phase 8: Multi-stage Build with Security Hardening
# Reference: https://docs.docker.com/develop/dev-best-practices/
# Reference: https://docs.docker.com/develop/devops-docker/multistage-build/

# Stage 1: Build stage
FROM node:20-alpine AS builder

LABEL maintainer="Factory Levels Team"
LABEL description="Factorio Mod Validation System - Build Stage"

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Set working directory
WORKDIR /app

# Copy package files
COPY backend_api/package*.json ./backend_api/
COPY lsp_server/package*.json ./lsp_server/
COPY ml_pattern_recognition/package*.json ./ml_pattern_recognition/
COPY performance_optimizer/package*.json ./performance_optimizer/
COPY advanced_obfuscation/package*.json ./advanced_obfuscation/
COPY enterprise_monitoring/package*.json ./enterprise_monitoring/

# Install dependencies
RUN cd backend_api && npm ci --only=production && \
    cd ../lsp_server && npm ci --only=production && \
    cd ../ml_pattern_recognition && npm ci --only=production && \
    cd ../performance_optimizer && npm ci --only=production && \
    cd ../advanced_obfuscation && npm ci --only=production && \
    cd ../enterprise_monitoring && npm ci --only=production

# Stage 2: Production stage
FROM node:20-alpine

LABEL maintainer="Factory Levels Team"
LABEL description="Factorio Mod Validation System - Production"
LABEL version="8.0.0"

# Security: Create non-root user
RUN addgroup -g 1001 -S validator && \
    adduser -u 1001 -S validator -G validator

# Install runtime dependencies only
RUN apk add --no-cache \
    tini \
    dumb-init

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=validator:validator backend_api ./backend_api
COPY --chown=validator:validator lsp_server ./lsp_server
COPY --chown=validator:validator ml_pattern_recognition ./ml_pattern_recognition
COPY --chown=validator:validator performance_optimizer ./performance_optimizer
COPY --chown=validator:validator advanced_obfuscation ./advanced_obfuscation
COPY --chown=validator:validator enterprise_monitoring ./enterprise_monitoring
COPY --chown=validator:validator tests ./tests

# Copy node_modules from builder
COPY --from=builder --chown=validator:validator /app/backend_api/node_modules ./backend_api/node_modules
COPY --from=builder --chown=validator:validator /app/lsp_server/node_modules ./lsp_server/node_modules
COPY --from=builder --chown=validator:validator /app/ml_pattern_recognition/node_modules ./ml_pattern_recognition/node_modules
COPY --from=builder --chown=validator:validator /app/performance_optimizer/node_modules ./performance_optimizer/node_modules
COPY --from=builder --chown=validator:validator /app/advanced_obfuscation/node_modules ./advanced_obfuscation/node_modules
COPY --from=builder --chown=validator:validator /app/enterprise_monitoring/node_modules ./enterprise_monitoring/node_modules

# Create directories
RUN mkdir -p /app/uploads /app/logs /app/models && \
    chown -R validator:validator /app

# Switch to non-root user
USER validator

# Expose ports
EXPOSE 3001 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001/api/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); })"

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start application
CMD ["sh", "-c", "node enterprise_monitoring/monitoring.js & node backend_api/server.js"]
