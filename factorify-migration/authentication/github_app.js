const { App } = require('@octokit/app');
const { Octokit } = require('@octokit/rest');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

class GitHubAppAuth {
    constructor(config = {}) {
        this.config = {
            appId: config.appId || process.env.GITHUB_APP_ID,
            privateKeyPath: config.privateKeyPath || process.env.GITHUB_APP_PRIVATE_KEY_PATH,
            privateKey: config.privateKey || process.env.GITHUB_APP_PRIVATE_KEY,
            webhookSecret: config.webhookSecret || process.env.GITHUB_WEBHOOK_SECRET,
            ...config
        };

        this.app = null;
        this.installations = new Map();
        this.tokens = new Map();
    }

    async initialize() {
        console.log('Initializing GitHub App Authentication...');

        if (!this.config.appId) {
            throw new Error('GitHub App ID is required (GITHUB_APP_ID)');
        }

        let privateKey = this.config.privateKey;

        if (!privateKey && this.config.privateKeyPath) {
            try {
                privateKey = fs.readFileSync(this.config.privateKeyPath, 'utf8');
            } catch (error) {
                throw new Error(`Failed to read private key from ${this.config.privateKeyPath}: ${error.message}`);
            }
        }

        if (!privateKey) {
            throw new Error('GitHub App private key is required (GITHUB_APP_PRIVATE_KEY or GITHUB_APP_PRIVATE_KEY_PATH)');
        }

        this.app = new App({
            appId: this.config.appId,
            privateKey: privateKey,
            webhooks: {
                secret: this.config.webhookSecret
            }
        });

        console.log('GitHub App Authentication initialized successfully');
    }

    async getInstallationToken(installationId) {
        const cached = this.tokens.get(installationId);

        if (cached && cached.expiresAt > Date.now() + 60000) {
            return cached.token;
        }

        try {
            const octokit = await this.app.getInstallationOctokit(installationId);
            const { data: installation } = await octokit.apps.getAuthenticated();

            const token = await octokit.auth({
                type: 'installation',
                installationId: installationId
            });

            this.tokens.set(installationId, {
                token: token.token,
                expiresAt: new Date(token.expiresAt).getTime()
            });

            console.log(`Generated installation token for installation ${installationId}`);
            return token.token;

        } catch (error) {
            console.error(`Failed to get installation token for ${installationId}:`, error.message);
            throw error;
        }
    }

    async getInstallationForRepository(owner, repo) {
        try {
            const jwt = this.app.getSignedJsonWebToken();
            const octokit = new Octokit({ auth: jwt });

            const { data: installation } = await octokit.apps.getRepoInstallation({
                owner,
                repo
            });

            this.installations.set(`${owner}/${repo}`, installation);

            console.log(`Found installation ${installation.id} for ${owner}/${repo}`);
            return installation;

        } catch (error) {
            console.error(`Failed to find installation for ${owner}/${repo}:`, error.message);
            throw error;
        }
    }

    async getRepositoryOctokit(owner, repo) {
        const installation = await this.getInstallationForRepository(owner, repo);
        const token = await this.getInstallationToken(installation.id);

        return new Octokit({ auth: token });
    }

    async getAllInstallations() {
        try {
            const jwt = this.app.getSignedJsonWebToken();
            const octokit = new Octokit({ auth: jwt });

            const { data: installations } = await octokit.apps.listInstallations();

            for (const installation of installations) {
                this.installations.set(installation.id, installation);
            }

            console.log(`Found ${installations.length} installations`);
            return installations;

        } catch (error) {
            console.error('Failed to list installations:', error.message);
            throw error;
        }
    }

    generateJWT(expiresIn = 600) {
        const now = Math.floor(Date.now() / 1000);

        const payload = {
            iat: now,
            exp: now + expiresIn,
            iss: this.config.appId
        };

        return jwt.sign(payload, this.config.privateKey, { algorithm: 'RS256' });
    }

    verifyWebhookSignature(payload, signature) {
        if (!this.config.webhookSecret) {
            console.warn('Webhook secret not configured, skipping verification');
            return true;
        }

        return this.app.webhooks.verify(payload, signature);
    }

    clearTokenCache(installationId = null) {
        if (installationId) {
            this.tokens.delete(installationId);
            console.log(`Cleared token cache for installation ${installationId}`);
        } else {
            this.tokens.clear();
            console.log('Cleared all token cache');
        }
    }

    getMetrics() {
        return {
            cachedTokens: this.tokens.size,
            cachedInstallations: this.installations.size,
            appId: this.config.appId
        };
    }
}

const githubAppAuth = new GitHubAppAuth();

module.exports = {
    GitHubAppAuth,
    initialize: (config) => githubAppAuth.initialize(config),
    getInstallationToken: (installationId) => githubAppAuth.getInstallationToken(installationId),
    getInstallationForRepository: (owner, repo) => githubAppAuth.getInstallationForRepository(owner, repo),
    getRepositoryOctokit: (owner, repo) => githubAppAuth.getRepositoryOctokit(owner, repo),
    getAllInstallations: () => githubAppAuth.getAllInstallations(),
    generateJWT: (expiresIn) => githubAppAuth.generateJWT(expiresIn),
    verifyWebhookSignature: (payload, signature) => githubAppAuth.verifyWebhookSignature(payload, signature),
    clearTokenCache: (installationId) => githubAppAuth.clearTokenCache(installationId),
    getAuthMetrics: () => githubAppAuth.getMetrics()
};
