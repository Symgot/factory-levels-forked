/**
 * Matrix Strategy Generator - Intelligent Parallel Job Configuration
 * Phase 9: Workflow Integration & Distributed Runner Orchestration
 * 
 * Reference: https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/running-variations-of-jobs-in-a-workflow
 */

const _ = require('lodash');
const winston = require('winston');
const fs = require('fs').promises;
const path = require('path');

class MatrixGenerator {
    constructor(options = {}) {
        this.options = {
            maxParallelJobs: options.maxParallelJobs || 10,
            chunkSize: options.chunkSize || 5,
            ...options
        };

        this.logger = winston.createLogger({
            level: 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            ),
            transports: [
                new winston.transports.Console()
            ]
        });
    }

    generateModMatrix(mods, versions, platforms) {
        const modChunks = _.chunk(mods, this.options.chunkSize);
        
        const matrix = {
            include: []
        };

        modChunks.forEach((chunk, chunkIndex) => {
            versions.forEach(version => {
                platforms.forEach(platform => {
                    matrix.include.push({
                        chunk_id: chunkIndex,
                        mods: chunk,
                        factorio_version: version,
                        platform: platform,
                        node_version: this.getNodeVersionForPlatform(platform)
                    });
                });
            });
        });

        this.logger.info('Mod matrix generated', {
            totalMods: mods.length,
            chunks: modChunks.length,
            matrixSize: matrix.include.length,
            maxParallel: this.options.maxParallelJobs
        });

        return this.optimizeMatrix(matrix);
    }

    generateVersionMatrix(versions, nodeVersions, platforms) {
        const matrix = {
            factorio_version: versions,
            node_version: nodeVersions,
            os: platforms.filter(p => p.includes('ubuntu')),
            include: []
        };

        platforms.filter(p => !p.includes('ubuntu')).forEach(platform => {
            matrix.include.push({
                os: platform,
                node_version: nodeVersions[Math.floor(nodeVersions.length / 2)],
                factorio_version: versions[0]
            });
        });

        this.logger.info('Version matrix generated', {
            versions: versions.length,
            nodeVersions: nodeVersions.length,
            platforms: platforms.length,
            includeConfigs: matrix.include.length
        });

        return matrix;
    }

    generateComponentMatrix(components, configurations) {
        const matrix = {
            component: components,
            ...configurations,
            include: []
        };

        const priorityComponents = ['ml_pattern_recognition', 'performance_optimizer'];
        const secondaryComponents = components.filter(c => !priorityComponents.includes(c));

        priorityComponents.forEach(component => {
            ['ubuntu-latest', 'windows-latest', 'macos-latest'].forEach(os => {
                matrix.include.push({
                    component,
                    os,
                    node_version: '20',
                    priority: 'high'
                });
            });
        });

        this.logger.info('Component matrix generated', {
            components: components.length,
            priorityComponents: priorityComponents.length,
            totalConfigs: matrix.include.length
        });

        return matrix;
    }

    generateTestChunks(testFiles, chunkSize = null) {
        const size = chunkSize || this.options.chunkSize;
        const chunks = _.chunk(testFiles, size);
        
        const matrix = {
            chunk: chunks.map((files, index) => ({
                id: index,
                files: files,
                count: files.length
            }))
        };

        this.logger.info('Test chunks generated', {
            totalTests: testFiles.length,
            chunks: chunks.length,
            chunkSize: size
        });

        return matrix;
    }

    optimizeMatrix(matrix) {
        if (!matrix.include || matrix.include.length === 0) {
            return matrix;
        }

        const totalJobs = matrix.include.length;
        
        if (totalJobs <= this.options.maxParallelJobs) {
            return matrix;
        }

        const prioritized = this.prioritizeMatrixJobs(matrix.include);
        
        const optimized = {
            ...matrix,
            include: prioritized
        };

        this.logger.info('Matrix optimized', {
            originalSize: totalJobs,
            optimizedSize: prioritized.length,
            maxParallel: this.options.maxParallelJobs
        });

        return optimized;
    }

    prioritizeMatrixJobs(jobs) {
        const scored = jobs.map(job => ({
            ...job,
            score: this.calculateJobScore(job)
        }));

        scored.sort((a, b) => b.score - a.score);

        return scored;
    }

    calculateJobScore(job) {
        let score = 0;

        if (job.priority === 'critical') score += 1000;
        else if (job.priority === 'high') score += 500;
        else if (job.priority === 'normal') score += 100;

        if (job.factorio_version && job.factorio_version.includes('2.0.72')) {
            score += 50;
        }

        if (job.platform === 'ubuntu-latest' || job.os === 'ubuntu-latest') {
            score += 30;
        }

        if (job.node_version === '20') {
            score += 20;
        }

        if (job.component && ['ml_pattern_recognition', 'performance_optimizer'].includes(job.component)) {
            score += 40;
        }

        return score;
    }

    async generateDynamicMatrix(repositoryPath) {
        const mods = await this.discoverMods(repositoryPath);
        const testFiles = await this.discoverTestFiles(repositoryPath);
        const components = await this.discoverComponents(repositoryPath);

        const matrix = {
            mods: mods.map(m => m.name),
            test_files: testFiles,
            components: components,
            factorio_versions: ['2.0.72', '2.0.71', '2.0.70'],
            node_versions: ['18', '20', '22'],
            platforms: ['ubuntu-latest', 'windows-latest', 'macos-latest']
        };

        this.logger.info('Dynamic matrix generated from repository', {
            mods: matrix.mods.length,
            testFiles: matrix.test_files.length,
            components: matrix.components.length
        });

        return matrix;
    }

    async discoverMods(repositoryPath) {
        try {
            const testDir = path.join(repositoryPath, 'tests');
            const files = await fs.readdir(testDir);
            
            const modFiles = files.filter(f => 
                f.startsWith('test_') && f.endsWith('.lua')
            );

            return modFiles.map(f => ({
                name: f.replace('test_', '').replace('.lua', ''),
                path: path.join(testDir, f)
            }));
        } catch (error) {
            this.logger.warn('Could not discover mods', { error: error.message });
            return [];
        }
    }

    async discoverTestFiles(repositoryPath) {
        try {
            const testDir = path.join(repositoryPath, 'tests');
            const files = await fs.readdir(testDir);
            
            return files.filter(f => 
                f.startsWith('test_') && f.endsWith('.lua')
            ).map(f => path.join('tests', f));
        } catch (error) {
            this.logger.warn('Could not discover test files', { error: error.message });
            return [];
        }
    }

    async discoverComponents(repositoryPath) {
        try {
            const entries = await fs.readdir(repositoryPath, { withFileTypes: true });
            
            const components = entries
                .filter(entry => entry.isDirectory())
                .map(entry => entry.name)
                .filter(name => 
                    name.includes('_') && 
                    !name.startsWith('.') &&
                    !['tests', 'docs', 'node_modules'].includes(name)
                );

            return components;
        } catch (error) {
            this.logger.warn('Could not discover components', { error: error.message });
            return [];
        }
    }

    generateBalancedMatrix(items, maxParallel) {
        const chunksCount = Math.min(
            Math.ceil(items.length / this.options.chunkSize),
            maxParallel
        );

        const balancedChunkSize = Math.ceil(items.length / chunksCount);
        const chunks = _.chunk(items, balancedChunkSize);

        return {
            chunks: chunks.map((chunk, index) => ({
                id: index,
                items: chunk,
                count: chunk.length
            })),
            metadata: {
                totalItems: items.length,
                chunksCount: chunks.length,
                avgChunkSize: balancedChunkSize,
                maxParallel
            }
        };
    }

    getNodeVersionForPlatform(platform) {
        const mapping = {
            'ubuntu-latest': '20',
            'windows-latest': '20',
            'macos-latest': '20',
            'ubuntu-22.04': '18',
            'ubuntu-20.04': '18'
        };

        return mapping[platform] || '20';
    }

    estimateExecutionTime(matrixSize, avgJobTime) {
        const parallelBatches = Math.ceil(matrixSize / this.options.maxParallelJobs);
        const estimatedTime = parallelBatches * avgJobTime;

        return {
            matrixSize,
            maxParallel: this.options.maxParallelJobs,
            parallelBatches,
            avgJobTime: `${avgJobTime}ms`,
            estimatedTotalTime: `${estimatedTime}ms`,
            estimatedTotalTimeMinutes: `${(estimatedTime / 60000).toFixed(2)}min`
        };
    }
}

module.exports = { MatrixGenerator };
