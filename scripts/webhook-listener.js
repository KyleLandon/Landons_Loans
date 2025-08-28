#!/usr/bin/env node

/**
 * GitHub Webhook Listener for Landon's Loans Auto-Update
 * Listens for GitHub push events and triggers update script
 */

const http = require('http');
const crypto = require('crypto');
const { exec } = require('child_process');
const fs = require('fs');

// Configuration
const CONFIG = {
    port: process.env.WEBHOOK_PORT || 3000,
    secret: process.env.GITHUB_SECRET || 'your-webhook-secret',
    updateScript: '/opt/fivem/scripts/update-hook.sh',
    logFile: '/var/log/webhook-listener.log'
};

// Logging function
function log(message) {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] ${message}\n`;
    console.log(logMessage.trim());
    fs.appendFileSync(CONFIG.logFile, logMessage);
}

// Verify GitHub webhook signature
function verifySignature(payload, signature) {
    const expectedSignature = crypto
        .createHmac('sha256', CONFIG.secret)
        .update(payload)
        .digest('hex');
    
    return crypto.timingSafeEqual(
        Buffer.from(`sha256=${expectedSignature}`),
        Buffer.from(signature)
    );
}

// Execute update script
function executeUpdate() {
    log('Executing update script...');
    
    exec(`bash ${CONFIG.updateScript}`, (error, stdout, stderr) => {
        if (error) {
            log(`Update failed: ${error.message}`);
            return;
        }
        
        if (stderr) {
            log(`Update stderr: ${stderr}`);
        }
        
        log(`Update output: ${stdout}`);
        log('Update completed successfully');
    });
}

// HTTP server
const server = http.createServer((req, res) => {
    if (req.method !== 'POST') {
        res.writeHead(405, { 'Content-Type': 'text/plain' });
        res.end('Method Not Allowed');
        return;
    }
    
    let body = '';
    req.on('data', chunk => {
        body += chunk.toString();
    });
    
    req.on('end', () => {
        try {
            // Verify signature if secret is configured
            if (CONFIG.secret !== 'your-webhook-secret') {
                const signature = req.headers['x-hub-signature-256'];
                if (!signature || !verifySignature(body, signature)) {
                    log('Invalid webhook signature');
                    res.writeHead(401, { 'Content-Type': 'text/plain' });
                    res.end('Unauthorized');
                    return;
                }
            }
            
            const payload = JSON.parse(body);
            
            // Check if this is a push to main branch
            if (payload.ref === 'refs/heads/main') {
                log(`Received push to main branch from ${payload.pusher.name}`);
                log(`Commits: ${payload.commits.length}`);
                
                // Execute update
                executeUpdate();
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    status: 'success',
                    message: 'Update triggered successfully'
                }));
            } else {
                log(`Ignoring push to ${payload.ref}`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    status: 'ignored',
                    message: 'Not main branch'
                }));
            }
            
        } catch (error) {
            log(`Error processing webhook: ${error.message}`);
            res.writeHead(400, { 'Content-Type': 'text/plain' });
            res.end('Bad Request');
        }
    });
});

// Start server
server.listen(CONFIG.port, () => {
    log(`Webhook listener started on port ${CONFIG.port}`);
    log(`Update script: ${CONFIG.updateScript}`);
    log(`Log file: ${CONFIG.logFile}`);
});

// Handle graceful shutdown
process.on('SIGINT', () => {
    log('Webhook listener shutting down...');
    server.close(() => {
        process.exit(0);
    });
});
