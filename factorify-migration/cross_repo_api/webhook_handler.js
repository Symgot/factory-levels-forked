const express = require('express');
const crypto = require('crypto');
const { enqueueJob } = require('../distributed_orchestration/queue_manager');

const router = express.Router();

const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || '';

router.post('/api/v1/webhook/github', async (req, res) => {
    try {
        const signature = req.headers['x-hub-signature-256'];
        const event = req.headers['x-github-event'];
        const delivery = req.headers['x-github-delivery'];

        if (!verifySignature(req.body, signature)) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid webhook signature',
                code: 'INVALID_SIGNATURE'
            });
        }

        console.log(`Webhook received: ${event} (${delivery})`);

        switch (event) {
            case 'push':
                await handlePushEvent(req.body);
                break;
            case 'pull_request':
                await handlePullRequestEvent(req.body);
                break;
            case 'workflow_run':
                await handleWorkflowRunEvent(req.body);
                break;
            case 'repository':
                await handleRepositoryEvent(req.body);
                break;
            default:
                console.log(`Unhandled event type: ${event}`);
        }

        res.status(200).json({
            status: 'received',
            event,
            delivery
        });

    } catch (error) {
        console.error('Webhook processing error:', error);
        res.status(500).json({
            error: 'Internal Server Error',
            message: error.message,
            code: 'WEBHOOK_ERROR'
        });
    }
});

function verifySignature(payload, signature) {
    if (!WEBHOOK_SECRET) {
        console.warn('GITHUB_WEBHOOK_SECRET not configured, skipping verification');
        return true;
    }

    if (!signature) {
        return false;
    }

    const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
    const digest = 'sha256=' + hmac.update(JSON.stringify(payload)).digest('hex');

    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

async function handlePushEvent(payload) {
    const { repository, ref, commits, pusher } = payload;

    console.log(`Push to ${repository.full_name} on ${ref} by ${pusher.name}`);

    const luaFiles = commits.flatMap(commit =>
        commit.added.concat(commit.modified).filter(file => file.endsWith('.lua'))
    );

    if (luaFiles.length > 0) {
        await enqueueJob({
            id: `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            type: 'auto_analysis',
            priority: 'normal',
            data: {
                event: 'push',
                repository: repository.full_name,
                ref,
                files: luaFiles,
                pusher: pusher.name,
                timestamp: new Date().toISOString()
            }
        });
    }
}

async function handlePullRequestEvent(payload) {
    const { action, pull_request, repository } = payload;

    console.log(`PR ${action}: ${repository.full_name}#${pull_request.number}`);

    if (action === 'opened' || action === 'synchronize') {
        await enqueueJob({
            id: `pr_${pull_request.number}_${Date.now()}`,
            type: 'pr_analysis',
            priority: 'high',
            data: {
                event: 'pull_request',
                action,
                repository: repository.full_name,
                prNumber: pull_request.number,
                prTitle: pull_request.title,
                author: pull_request.user.login,
                headRef: pull_request.head.ref,
                baseRef: pull_request.base.ref,
                timestamp: new Date().toISOString()
            }
        });
    }
}

async function handleWorkflowRunEvent(payload) {
    const { action, workflow_run, repository } = payload;

    console.log(`Workflow ${action}: ${repository.full_name}/${workflow_run.name}`);

    if (action === 'completed') {
        await enqueueJob({
            id: `workflow_${workflow_run.id}`,
            type: 'workflow_notification',
            priority: 'low',
            data: {
                event: 'workflow_run',
                action,
                repository: repository.full_name,
                workflowName: workflow_run.name,
                conclusion: workflow_run.conclusion,
                runId: workflow_run.id,
                duration: calculateDuration(workflow_run.created_at, workflow_run.updated_at),
                timestamp: new Date().toISOString()
            }
        });
    }
}

async function handleRepositoryEvent(payload) {
    const { action, repository } = payload;

    console.log(`Repository ${action}: ${repository.full_name}`);

    if (action === 'created') {
        await enqueueJob({
            id: `repo_${repository.id}`,
            type: 'repo_setup',
            priority: 'normal',
            data: {
                event: 'repository',
                action,
                repository: repository.full_name,
                owner: repository.owner.login,
                isPrivate: repository.private,
                timestamp: new Date().toISOString()
            }
        });
    }
}

function calculateDuration(startTime, endTime) {
    const start = new Date(startTime).getTime();
    const end = new Date(endTime).getTime();
    return Math.round((end - start) / 1000);
}

router.get('/api/v1/webhook/test', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Webhook endpoint is active',
        timestamp: new Date().toISOString()
    });
});

module.exports = router;
