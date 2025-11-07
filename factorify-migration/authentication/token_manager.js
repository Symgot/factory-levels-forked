const crypto = require('crypto');

class TokenManager {
    constructor(config = {}) {
        this.config = {
            tokenExpiration: config.tokenExpiration || 3600000,
            refreshThreshold: config.refreshThreshold || 300000,
            maxTokensPerUser: config.maxTokensPerUser || 5,
            ...config
        };

        this.tokens = new Map();
        this.userTokens = new Map();
    }

    async initialize() {
        console.log('Initializing Token Manager...');
        this.startCleanup();
        console.log('Token Manager initialized successfully');
    }

    generateToken(userId, metadata = {}) {
        const tokenId = crypto.randomBytes(32).toString('hex');

        const token = {
            id: tokenId,
            userId,
            createdAt: Date.now(),
            expiresAt: Date.now() + this.config.tokenExpiration,
            lastUsed: Date.now(),
            metadata,
            accessCount: 0
        };

        this.tokens.set(tokenId, token);

        if (!this.userTokens.has(userId)) {
            this.userTokens.set(userId, new Set());
        }

        const userTokenSet = this.userTokens.get(userId);
        userTokenSet.add(tokenId);

        if (userTokenSet.size > this.config.maxTokensPerUser) {
            const oldestTokenId = Array.from(userTokenSet)[0];
            this.revokeToken(oldestTokenId);
        }

        console.log(`Generated token ${tokenId} for user ${userId}`);
        return tokenId;
    }

    async validateToken(tokenId) {
        const token = this.tokens.get(tokenId);

        if (!token) {
            return { valid: false, error: 'Token not found' };
        }

        if (token.expiresAt < Date.now()) {
            this.revokeToken(tokenId);
            return { valid: false, error: 'Token expired' };
        }

        token.lastUsed = Date.now();
        token.accessCount++;

        if (this.shouldRefresh(token)) {
            token.expiresAt = Date.now() + this.config.tokenExpiration;
            console.log(`Refreshed token ${tokenId}`);
        }

        return {
            valid: true,
            userId: token.userId,
            metadata: token.metadata,
            expiresIn: token.expiresAt - Date.now()
        };
    }

    shouldRefresh(token) {
        const timeRemaining = token.expiresAt - Date.now();
        return timeRemaining < this.config.refreshThreshold;
    }

    revokeToken(tokenId) {
        const token = this.tokens.get(tokenId);

        if (!token) {
            return false;
        }

        const userTokenSet = this.userTokens.get(token.userId);

        if (userTokenSet) {
            userTokenSet.delete(tokenId);

            if (userTokenSet.size === 0) {
                this.userTokens.delete(token.userId);
            }
        }

        this.tokens.delete(tokenId);

        console.log(`Revoked token ${tokenId} for user ${token.userId}`);
        return true;
    }

    revokeUserTokens(userId) {
        const userTokenSet = this.userTokens.get(userId);

        if (!userTokenSet) {
            return 0;
        }

        let count = 0;

        for (const tokenId of userTokenSet) {
            this.tokens.delete(tokenId);
            count++;
        }

        this.userTokens.delete(userId);

        console.log(`Revoked ${count} tokens for user ${userId}`);
        return count;
    }

    getTokenInfo(tokenId) {
        const token = this.tokens.get(tokenId);

        if (!token) {
            return null;
        }

        return {
            id: token.id,
            userId: token.userId,
            createdAt: new Date(token.createdAt).toISOString(),
            expiresAt: new Date(token.expiresAt).toISOString(),
            lastUsed: new Date(token.lastUsed).toISOString(),
            accessCount: token.accessCount,
            metadata: token.metadata
        };
    }

    getUserTokens(userId) {
        const userTokenSet = this.userTokens.get(userId);

        if (!userTokenSet) {
            return [];
        }

        return Array.from(userTokenSet).map(tokenId => this.getTokenInfo(tokenId)).filter(Boolean);
    }

    startCleanup() {
        this.cleanupInterval = setInterval(() => {
            this.cleanupExpiredTokens();
        }, 60000);

        console.log('Token cleanup task started');
    }

    cleanupExpiredTokens() {
        const now = Date.now();
        let expiredCount = 0;

        for (const [tokenId, token] of this.tokens.entries()) {
            if (token.expiresAt < now) {
                this.revokeToken(tokenId);
                expiredCount++;
            }
        }

        if (expiredCount > 0) {
            console.log(`Cleaned up ${expiredCount} expired tokens`);
        }
    }

    async shutdown() {
        console.log('Shutting down Token Manager...');

        if (this.cleanupInterval) {
            clearInterval(this.cleanupInterval);
        }

        console.log('Token Manager shutdown complete');
    }

    getMetrics() {
        const now = Date.now();
        const tokens = Array.from(this.tokens.values());

        return {
            totalTokens: tokens.length,
            totalUsers: this.userTokens.size,
            expiringSoon: tokens.filter(t => t.expiresAt - now < this.config.refreshThreshold).length,
            averageAccessCount: tokens.length > 0
                ? Math.round(tokens.reduce((sum, t) => sum + t.accessCount, 0) / tokens.length)
                : 0,
            oldestToken: tokens.length > 0
                ? Math.min(...tokens.map(t => t.createdAt))
                : null
        };
    }
}

function validateToken(req, res, next) {
    const authHeader = req.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Missing or invalid authorization header',
            code: 'MISSING_AUTH'
        });
    }

    const token = authHeader.substring(7);
    const tokenManager = req.app.locals.tokenManager;

    tokenManager.validateToken(token).then(result => {
        if (!result.valid) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: result.error,
                code: 'INVALID_TOKEN'
            });
        }

        req.user = {
            id: result.userId,
            metadata: result.metadata
        };

        req.token = {
            id: token,
            expiresIn: result.expiresIn
        };

        next();
    }).catch(error => {
        console.error('Token validation error:', error);

        return res.status(500).json({
            error: 'Internal Server Error',
            message: 'Token validation failed',
            code: 'VALIDATION_ERROR'
        });
    });
}

const tokenManager = new TokenManager();

module.exports = {
    TokenManager,
    validateToken,
    initializeTokenManager: (config) => tokenManager.initialize(config),
    generateToken: (userId, metadata) => tokenManager.generateToken(userId, metadata),
    validateTokenById: (tokenId) => tokenManager.validateToken(tokenId),
    revokeToken: (tokenId) => tokenManager.revokeToken(tokenId),
    revokeUserTokens: (userId) => tokenManager.revokeUserTokens(userId),
    getTokenInfo: (tokenId) => tokenManager.getTokenInfo(tokenId),
    getUserTokens: (userId) => tokenManager.getUserTokens(userId),
    getTokenMetrics: () => tokenManager.getMetrics(),
    shutdownTokenManager: () => tokenManager.shutdown()
};
