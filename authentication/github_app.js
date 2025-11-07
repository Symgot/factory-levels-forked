const { App } = require('@octokit/app');
const { Octokit } = require('@octokit/rest');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

/**
 * GitHubAppAuth - Optional GitHub App authentication
 * Feature flag: ENABLE_GITHUB_APP_AUTH
 * Works with or without GitHub App credentials
 */
class GitHubAppAuth {
    constructor(config = {}) {
        // Check if GitHub App authentication is enabled
        this.enabled = process.env.ENABLE_GITHUB_APP_AUTH === 'true';
        
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
        
        if (!this.enabled) {
            console.log('[GitHubAppAuth] GitHub App authentication DISABLED - using public access mode');
        }
    }

    async initialize() {
        if (!this.enabled) {
            console.log('[GitHubAppAuth] Skipping initialization - authentication disabled');
            return {
                success: true,
                mode: 'public',
                message: 'GitHub App authentication is disabled'
            };
        }

        console.log('[GitHubAppAuth] Initializing GitHub App Authentication...');

        if (!this.config.appId) {
            console.warn('[GitHubAppAuth] GitHub App ID not provided - falling back to public mode');
            this.enabled = false;
            return {
                success: true,
                mode: 'public',
                message: 'Falling back to public access mode'
            };
        }

        let privateKey = this.config.privateKey;

        if (!privateKey && this.config.privateKeyPath) {
            try {
                privateKey = fs.readFileSync(this.config.privateKeyPath, 'utf8');
            } catch (error) {
                console.warn(`[GitHubAppAuth] Failed to read private key: ${error.message}`);
                this.enabled = false;
                return {
                    success: true,
                    mode: 'public',
                    message: 'Falling back to public access mode'
                };
            }
        }

        if (!privateKey) {
            console.warn('[GitHubAppAuth] GitHub App private key not provided - falling back to public mode');
            this.enabled = false;
            return {
                success: true,
                mode: 'public',
                message: 'Falling back to public access mode'
            };
        }

        try {
            this.app = new App({
                appId: this.config.appId,
                privateKey: privateKey,
                webhooks: {
                    secret: this.config.webhookSecret
                }
            });

            console.log('[GitHubAppAuth] GitHub App initialized successfully');
            return {
                success: true,
                mode: 'authenticated',
                appId: this.config.appId
            };
        } catch (error) {
            console.error(`[GitHubAppAuth] Failed to initialize GitHub App: ${error.message}`);
            this.enabled = false;
            return {
                success: true,
                mode: 'public',
                message: 'Falling back to public access mode',
                error: error.message
            };
        }
    }

    async getInstallationToken(installationId) {
        if (!this.enabled) {
            console.log('[GitHubAppAuth] Authentication disabled, returning null token');
            return null;
        }

        if (!this.app) {
            console.warn('[GitHubAppAuth] App not initialized, falling back to null token');
            return null;
        }

        const cachedToken = this.tokens.get(installationId);
        if (cachedToken && this.isTokenValid(cachedToken)) {
            return cachedToken.token;
        }

        try {
            const octokit = await this.app.getInstallationOctokit(installationId);
            const { data } = await octokit.rest.apps.createInstallationAccessToken({
                installation_id: installationId
            });

            const tokenData = {
                token: data.token,
                expiresAt: new Date(data.expires_at),
                installationId: installationId
            };

            this.tokens.set(installationId, tokenData);
            console.log(`[GitHubAppAuth] Generated installation token for installation ${installationId}`);

            return data.token;
        } catch (error) {
            console.error(`[GitHubAppAuth] Failed to get installation token: ${error.message}`);
            return null;
        }
    }

    isTokenValid(tokenData) {
        if (!tokenData || !tokenData.expiresAt) {
            return false;
        }

        const now = new Date();
        const expiresAt = new Date(tokenData.expiresAt);
        const bufferTime = 5 * 60 * 1000;

        return expiresAt.getTime() - now.getTime() > bufferTime;
    }

    async listInstallations() {
        if (!this.enabled || !this.app) {
            return {
                success: true,
                mode: 'public',
                installations: []
            };
        }

        try {
            const { data } = await this.app.octokit.rest.apps.listInstallations();
            
            for (const installation of data) {
                this.installations.set(installation.id, {
                    id: installation.id,
                    account: installation.account,
                    repositorySelection: installation.repository_selection,
                    permissions: installation.permissions
                });
            }

            return {
                success: true,
                mode: 'authenticated',
                installations: data.map(i => ({
                    id: i.id,
                    account: i.account.login,
                    type: i.account.type
                }))
            };
        } catch (error) {
            console.error(`[GitHubAppAuth] Failed to list installations: ${error.message}`);
            return {
                success: false,
                mode: 'authenticated',
                error: error.message,
                installations: []
            };
        }
    }

    async getInstallationByRepository(owner, repo) {
        if (!this.enabled || !this.app) {
            return null;
        }

        try {
            const { data } = await this.app.octokit.rest.apps.getRepoInstallation({
                owner: owner,
                repo: repo
            });

            return data.id;
        } catch (error) {
            console.error(`[GitHubAppAuth] Failed to get installation for ${owner}/${repo}: ${error.message}`);
            return null;
        }
    }

    async authenticatedOctokit(installationId, personalToken = null) {
        if (!this.enabled) {
            if (personalToken) {
                console.log('[GitHubAppAuth] Using personal access token (public mode)');
                return new Octokit({ auth: personalToken });
            }
            console.log('[GitHubAppAuth] Creating unauthenticated Octokit (public mode)');
            return new Octokit();
        }

        const token = await this.getInstallationToken(installationId);
        if (!token) {
            if (personalToken) {
                console.log('[GitHubAppAuth] Falling back to personal access token');
                return new Octokit({ auth: personalToken });
            }
            console.log('[GitHubAppAuth] Falling back to unauthenticated Octokit');
            return new Octokit();
        }

        return new Octokit({ auth: token });
    }

    getAuthMode() {
        return this.enabled ? 'authenticated' : 'public';
    }

    isEnabled() {
        return this.enabled;
    }

    clearCache() {
        this.tokens.clear();
        this.installations.clear();
        console.log('[GitHubAppAuth] Token cache cleared');
    }
}

module.exports = GitHubAppAuth;
