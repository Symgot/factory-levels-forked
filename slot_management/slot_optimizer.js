/**
 * Slot Optimizer - GitHub Runner Slot Management & Optimization
 * Phase 9: Workflow Integration & Distributed Runner Orchestration
 * 
 * Reference: https://docs.github.com/actions/using-github-hosted-runners/about-github-hosted-runners
 * Reference: https://docs.github.com/actions/learn-github-actions/usage-limits-billing-and-administration
 */

const { Octokit } = require('@octokit/rest');
const winston = require('winston');
const cron = require('node-cron');

class SlotOptimizer {
    constructor(options = {}) {
        this.options = {
            maxSlots: options.maxSlots || 10,
            targetUtilization: options.targetUtilization || 0.95,
            minUtilization: options.minUtilization || 0.70,
            pollingInterval: options.pollingInterval || 30000,
            costPerMinute: options.costPerMinute || 0.008,
            ...options
        };

        this.octokit = new Octokit({
            auth: options.githubToken || process.env.GITHUB_TOKEN
        });

        this.logger = winston.createLogger({
            level: 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            ),
            transports: [
                new winston.transports.Console(),
                new winston.transports.File({ filename: 'slot-optimizer.log' })
            ]
        });

        this.state = {
            availableSlots: this.options.maxSlots,
            usedSlots: 0,
            queuedJobs: 0,
            runningJobs: [],
            slotHistory: [],
            lastUpdate: null
        };

        this.metrics = {
            totalJobsExecuted: 0,
            totalRunnerMinutesUsed: 0,
            totalCost: 0,
            averageSlotUtilization: 0,
            peakSlotUsage: 0,
            utilizationHistory: []
        };
    }

    async initialize() {
        this.logger.info('Initializing Slot Optimizer', {
            maxSlots: this.options.maxSlots,
            targetUtilization: this.options.targetUtilization
        });

        cron.schedule('*/30 * * * * *', () => this.updateSlotStatus());
        cron.schedule('0 * * * *', () => this.generateUtilizationReport());

        await this.updateSlotStatus();

        this.logger.info('Slot Optimizer initialized successfully');
    }

    async updateSlotStatus() {
        try {
            const [owner, repo] = (process.env.GITHUB_REPOSITORY || 'owner/repo').split('/');

            const workflowRuns = await this.octokit.rest.actions.listWorkflowRunsForRepo({
                owner,
                repo,
                status: 'in_progress',
                per_page: 100
            });

            const runningJobs = workflowRuns.data.workflow_runs || [];
            const usedSlots = runningJobs.length;
            const availableSlots = this.options.maxSlots - usedSlots;
            const utilization = usedSlots / this.options.maxSlots;

            this.state = {
                ...this.state,
                availableSlots,
                usedSlots,
                runningJobs: runningJobs.map(run => ({
                    id: run.id,
                    name: run.name,
                    startedAt: run.created_at
                })),
                lastUpdate: Date.now()
            };

            this.metrics.utilizationHistory.push({
                timestamp: Date.now(),
                utilization,
                usedSlots,
                availableSlots
            });

            if (this.metrics.utilizationHistory.length > 1000) {
                this.metrics.utilizationHistory.shift();
            }

            if (usedSlots > this.metrics.peakSlotUsage) {
                this.metrics.peakSlotUsage = usedSlots;
            }

            this.logger.info('Slot status updated', {
                availableSlots,
                usedSlots,
                utilization: `${(utilization * 100).toFixed(2)}%`,
                target: `${(this.options.targetUtilization * 100).toFixed(2)}%`
            });

            if (utilization > this.options.targetUtilization) {
                this.logger.warn('Slot utilization above target', {
                    current: `${(utilization * 100).toFixed(2)}%`,
                    target: `${(this.options.targetUtilization * 100).toFixed(2)}%`
                });
            } else if (utilization < this.options.minUtilization && usedSlots > 0) {
                this.logger.info('Slot utilization below minimum', {
                    current: `${(utilization * 100).toFixed(2)}%`,
                    minimum: `${(this.options.minUtilization * 100).toFixed(2)}%`,
                    suggestion: 'Consider reducing parallel jobs or bundling tasks'
                });
            }

        } catch (error) {
            this.logger.error('Failed to update slot status', {
                error: error.message
            });
        }
    }

    calculateOptimalSlotAllocation(pendingJobs, estimatedJobTime) {
        const avgJobTime = estimatedJobTime || 180000;
        const parallelCapacity = this.state.availableSlots;

        if (pendingJobs <= parallelCapacity) {
            return {
                allocation: pendingJobs,
                utilizationTarget: (pendingJobs / this.options.maxSlots * 100).toFixed(2) + '%',
                estimatedTime: `${(avgJobTime / 60000).toFixed(2)}min`,
                efficiency: 'optimal'
            };
        }

        const batches = Math.ceil(pendingJobs / parallelCapacity);
        const totalTime = batches * avgJobTime;

        return {
            allocation: parallelCapacity,
            batches,
            utilizationTarget: `${(this.options.targetUtilization * 100).toFixed(2)}%`,
            estimatedTime: `${(totalTime / 60000).toFixed(2)}min`,
            efficiency: batches <= 3 ? 'good' : 'moderate'
        };
    }

    predictSlotDemand(historicalData, futureMinutes = 60) {
        if (!historicalData || historicalData.length === 0) {
            return {
                predicted: this.options.maxSlots * 0.5,
                confidence: 'low',
                recommendation: 'Insufficient historical data'
            };
        }

        const recentData = historicalData.slice(-10);
        const avgUtilization = recentData.reduce((sum, d) => sum + d.utilization, 0) / recentData.length;
        const predictedSlots = Math.ceil(this.options.maxSlots * avgUtilization);

        let confidence = 'medium';
        if (recentData.length >= 10) confidence = 'high';
        else if (recentData.length < 5) confidence = 'low';

        return {
            predicted: predictedSlots,
            confidence,
            avgUtilization: `${(avgUtilization * 100).toFixed(2)}%`,
            recommendation: predictedSlots >= this.options.maxSlots * 0.9 
                ? 'High demand expected - consider increasing max slots'
                : 'Normal demand expected'
        };
    }

    optimizeJobBundling(jobs, targetBundleSize = 3) {
        if (jobs.length <= this.options.maxSlots) {
            return {
                bundles: jobs.map(j => [j]),
                bundlingApplied: false,
                slotSavings: 0
            };
        }

        const bundles = [];
        const sorted = [...jobs].sort((a, b) => 
            (a.estimatedTime || 60000) - (b.estimatedTime || 60000)
        );

        for (let i = 0; i < sorted.length; i += targetBundleSize) {
            bundles.push(sorted.slice(i, i + targetBundleSize));
        }

        const slotSavings = jobs.length - bundles.length;

        return {
            bundles,
            bundlingApplied: true,
            slotSavings,
            efficiencyGain: `${((slotSavings / jobs.length) * 100).toFixed(2)}%`
        };
    }

    calculateCostEfficiency() {
        const avgUtilization = this.metrics.utilizationHistory.length > 0
            ? this.metrics.utilizationHistory.reduce((sum, m) => sum + m.utilization, 0) / this.metrics.utilizationHistory.length
            : 0;

        const totalCost = this.metrics.totalRunnerMinutesUsed * this.options.costPerMinute;
        const potentialMaxCost = this.metrics.totalJobsExecuted * 5 * this.options.costPerMinute;
        const costSavings = potentialMaxCost - totalCost;
        const efficiencyRating = avgUtilization >= 0.85 ? 'excellent' :
                                avgUtilization >= 0.70 ? 'good' :
                                avgUtilization >= 0.50 ? 'fair' : 'poor';

        return {
            totalRunnerMinutes: this.metrics.totalRunnerMinutesUsed,
            totalCost: `$${totalCost.toFixed(2)}`,
            avgUtilization: `${(avgUtilization * 100).toFixed(2)}%`,
            costPerJob: this.metrics.totalJobsExecuted > 0
                ? `$${(totalCost / this.metrics.totalJobsExecuted).toFixed(4)}`
                : '$0',
            estimatedSavings: `$${costSavings.toFixed(2)}`,
            efficiencyRating
        };
    }

    async generateUtilizationReport() {
        const report = {
            timestamp: new Date().toISOString(),
            slots: {
                max: this.options.maxSlots,
                currentlyUsed: this.state.usedSlots,
                available: this.state.availableSlots,
                peakUsage: this.metrics.peakSlotUsage
            },
            utilization: {
                current: `${((this.state.usedSlots / this.options.maxSlots) * 100).toFixed(2)}%`,
                target: `${(this.options.targetUtilization * 100).toFixed(2)}%`,
                average: this.metrics.utilizationHistory.length > 0
                    ? `${((this.metrics.utilizationHistory.reduce((sum, m) => sum + m.utilization, 0) / this.metrics.utilizationHistory.length) * 100).toFixed(2)}%`
                    : '0%'
            },
            jobs: {
                totalExecuted: this.metrics.totalJobsExecuted,
                currentlyRunning: this.state.runningJobs.length,
                queued: this.state.queuedJobs
            },
            costEfficiency: this.calculateCostEfficiency(),
            recommendations: this.generateRecommendations()
        };

        this.logger.info('Slot utilization report generated', report);
        return report;
    }

    generateRecommendations() {
        const recommendations = [];
        const avgUtilization = this.metrics.utilizationHistory.length > 0
            ? this.metrics.utilizationHistory.reduce((sum, m) => sum + m.utilization, 0) / this.metrics.utilizationHistory.length
            : 0;

        if (avgUtilization < this.options.minUtilization) {
            recommendations.push({
                type: 'underutilization',
                message: 'Average slot utilization is below minimum threshold',
                action: 'Consider reducing max_parallel or bundling jobs'
            });
        }

        if (avgUtilization > this.options.targetUtilization) {
            recommendations.push({
                type: 'overutilization',
                message: 'Average slot utilization exceeds target',
                action: 'Consider increasing max_parallel slots if budget allows'
            });
        }

        if (this.metrics.peakSlotUsage >= this.options.maxSlots) {
            recommendations.push({
                type: 'capacity',
                message: 'Peak usage reached maximum slot capacity',
                action: 'Monitor for queued jobs and consider capacity planning'
            });
        }

        if (recommendations.length === 0) {
            recommendations.push({
                type: 'optimal',
                message: 'Slot utilization is within optimal range',
                action: 'Continue monitoring'
            });
        }

        return recommendations;
    }

    getSlotStatistics() {
        return {
            state: this.state,
            metrics: {
                ...this.metrics,
                avgUtilization: this.metrics.utilizationHistory.length > 0
                    ? `${((this.metrics.utilizationHistory.reduce((sum, m) => sum + m.utilization, 0) / this.metrics.utilizationHistory.length) * 100).toFixed(2)}%`
                    : '0%'
            },
            costEfficiency: this.calculateCostEfficiency()
        };
    }

    async recordJobExecution(jobId, runnerMinutes) {
        this.metrics.totalJobsExecuted++;
        this.metrics.totalRunnerMinutesUsed += runnerMinutes;
        this.metrics.totalCost = this.metrics.totalRunnerMinutesUsed * this.options.costPerMinute;

        this.logger.info('Job execution recorded', {
            jobId,
            runnerMinutes,
            totalCost: `$${this.metrics.totalCost.toFixed(2)}`
        });
    }
}

module.exports = { SlotOptimizer };
