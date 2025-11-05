/**
 * Worker Thread for Performance Optimizer
 * Handles parallel parsing tasks
 */

const { parentPort } = require('worker_threads');

// Import worker task handler
const { parseWorkerTask } = require('./performance_engine');

// Listen for messages from main thread
if (parentPort) {
    parentPort.on('message', async (taskData) => {
        try {
            const result = parseWorkerTask(taskData);
            parentPort.postMessage({ success: true, result });
        } catch (error) {
            parentPort.postMessage({ success: false, error: error.message });
        }
    });
}

// Export for Piscina
module.exports = parseWorkerTask;
