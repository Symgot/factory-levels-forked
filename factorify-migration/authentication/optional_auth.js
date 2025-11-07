const { Octokit } = require('@octokit/rest');
const githubApp = require('./github_app');

class OptionalAuth {
    constructor(config = {}) {
        this.config = {
            enabled: config.enabled !== undefined ? config.enabled : process.env.AUTH_ENABLED === 'true',
            githubToken: config.githubToken || process.env.GITHUB_TOKEN,
            githubAppConfig: config.githubAppConfig || {},
            ...config
        };

        this.authMode = this.config.enabled ? 'github_app' : 'public';
        this.initialized = false;
    }

    async initialize() {
        if (this.initialized) {
            console.log('Optional authentication already initialized');
            return;
        }

        if (this.config.enabled) {
            console.log('Initializing GitHub App authentication...');
            try {
                await githubApp.initialize(this.config.githubAppConfig);
                this.authMode = 'github_app';
                console.log('✅ GitHub App authentication enabled');
            } catch (error) {
                console.warn('GitHub App authentication failed, falling back to token or public:', error.message);
                this.authMode = this.config.githubToken ? 'token' : 'public';
            }
        } else {
            if (this.config.githubToken) {
                console.log('Using GitHub token authentication (public API with token)');
                this.authMode = 'token';
            } else {
                console.log('Using public GitHub API (no authentication)');
                this.authMode = 'public';
            }
        }

        this.initialized = true;
        console.log(`✅ Authentication mode: ${this.authMode}`);
    }

    async getOctokit(owner = null, repo = null) {
        if (!this.initialized) {
            await this.initialize();
        }

        switch (this.authMode) {
            case 'github_app':
                if (owner && repo) {
                    return await githubApp.getRepositoryOctokit(owner, repo);
                }
                throw new Error('GitHub App mode requires owner and repo parameters');

            case 'token':
                return new Octokit({ auth: this.config.githubToken });

            case 'public':
                return new Octokit();

            default:
                throw new Error(`Unknown auth mode: ${this.authMode}`);
        }
    }

    isEnabled() {
        return this.config.enabled;
    }

    getAuthMode() {
        return this.authMode;
    }

    getMetrics() {
        const metrics = {
            enabled: this.config.enabled,
            mode: this.authMode,
            initialized: this.initialized
        };

        if (this.authMode === 'github_app') {
            metrics.githubApp = githubApp.getAuthMetrics();
        }

        return metrics;
    }

    async verifyAccess(owner, repo) {
        try {
            const octokit = await this.getOctokit(owner, repo);
            const { data } = await octokit.repos.get({ owner, repo });
            return {
                success: true,
                repository: data.full_name,
                permissions: data.permissions || {}
            };
        } catch (error) {
            return {
                success: false,
                error: error.message
            };
        }
    }
}

const optionalAuth = new OptionalAuth();

module.exports = {
    OptionalAuth,
    initialize: (config) => optionalAuth.initialize(config),
    getOctokit: (owner, repo) => optionalAuth.getOctokit(owner, repo),
    isEnabled: () => optionalAuth.isEnabled(),
    getAuthMode: () => optionalAuth.getAuthMode(),
    getMetrics: () => optionalAuth.getMetrics(),
    verifyAccess: (owner, repo) => optionalAuth.verifyAccess(owner, repo)
};
