/**
 * Backend API Server for Factorio Mod Validation
 * Phase 7: Production-Ready System
 * 
 * Reference: https://expressjs.com/en/4x/api.html
 * Reference: https://jwt.io/introduction/
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { exec } = require('child_process');
const util = require('util');

const app = express();
const execPromise = util.promisify(exec);

// ============================================================================
// CONFIGURATION
// ============================================================================

// Validate required environment variables in production
if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
    console.error('ERROR: JWT_SECRET environment variable must be set in production');
    process.exit(1);
}

const CONFIG = {
    PORT: process.env.PORT || 3001,
    JWT_SECRET: process.env.JWT_SECRET || 'dev-secret-DO-NOT-USE-IN-PRODUCTION',
    JWT_EXPIRES_IN: '24h',
    UPLOAD_DIR: process.env.UPLOAD_DIR || './uploads',
    MAX_FILE_SIZE: 50 * 1024 * 1024, // 50MB
    LUA_VALIDATOR_PATH: process.env.LUA_VALIDATOR_PATH || '../tests/validation_engine.lua',
    ALLOWED_ORIGINS: (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(','),
    RATE_LIMIT_WINDOW: 15 * 60 * 1000, // 15 minutes
    RATE_LIMIT_MAX_REQUESTS: 100
};

// ============================================================================
// MIDDLEWARE SETUP
// ============================================================================

// Security middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        }
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
}));

// CORS configuration
app.use(cors({
    origin: function (origin, callback) {
        if (!origin || CONFIG.ALLOWED_ORIGINS.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
    windowMs: CONFIG.RATE_LIMIT_WINDOW,
    max: CONFIG.RATE_LIMIT_MAX_REQUESTS,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

app.use('/api/', limiter);

// ============================================================================
// FILE UPLOAD CONFIGURATION
// ============================================================================

const storage = multer.diskStorage({
    destination: async function (req, file, cb) {
        const uploadDir = CONFIG.UPLOAD_DIR;
        try {
            await fs.mkdir(uploadDir, { recursive: true });
            cb(null, uploadDir);
        } catch (error) {
            cb(error, null);
        }
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = function (req, file, cb) {
    const allowedExtensions = ['.lua', '.zip'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    if (allowedExtensions.includes(ext)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only .lua and .zip files are allowed.'), false);
    }
};

const upload = multer({
    storage: storage,
    limits: {
        fileSize: CONFIG.MAX_FILE_SIZE
    },
    fileFilter: fileFilter
});

// ============================================================================
// AUTHENTICATION MIDDLEWARE
// ============================================================================

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }
    
    jwt.verify(token, CONFIG.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token' });
        }
        req.user = user;
        next();
    });
};

// ============================================================================
// FILE PATH VALIDATION
// ============================================================================

/**
 * Validates and sanitizes file paths to prevent path traversal attacks
 * @param {string} userPath - Path from user input (e.g., req.file.path)
 * @param {string} baseDir - Base directory that path must be within
 * @returns {string|null} Sanitized absolute path, or null if invalid
 */
function validateFilePath(userPath, baseDir) {
    try {
        const resolvedBase = path.resolve(baseDir);
        const resolvedPath = path.resolve(userPath);
        
        // Check path is within base directory
        if (!resolvedPath.startsWith(resolvedBase + path.sep) && resolvedPath !== resolvedBase) {
            return null;
        }
        
        // Additional checks
        if (resolvedPath.includes('..')) {
            return null;
        }
        
        return resolvedPath;
    } catch (error) {
        return null;
    }
}

// ============================================================================
// IN-MEMORY DATA STORES (Replace with database in production)
// ============================================================================

const users = new Map();
const validationHistory = new Map();
const apiKeys = new Map();

// Default admin user (for development only)
// In production, create admin via registration or environment variable
const defaultAdminPassword = process.env.ADMIN_PASSWORD 
    ? bcrypt.hashSync(process.env.ADMIN_PASSWORD, 10)
    : bcrypt.hashSync('CHANGE-ME-' + Date.now(), 10);

if (process.env.NODE_ENV !== 'production') {
    users.set('admin', {
        username: 'admin',
        password: defaultAdminPassword,
        email: 'admin@example.com',
        role: 'admin',
        created_at: new Date().toISOString()
    });
    console.log('⚠️  Development mode: Default admin user created');
}

// ============================================================================
// VALIDATION FUNCTIONS
// ============================================================================

async function validateLuaFile(filePath) {
    try {
        const validatorPath = path.resolve(__dirname, CONFIG.LUA_VALIDATOR_PATH);
        
        // Security: Use spawn with array arguments to prevent command injection
        const { spawn } = require('child_process');
        
        return new Promise((resolve, reject) => {
            const luaProcess = spawn('lua', [validatorPath, filePath]);
            let stdout = '';
            let stderr = '';
            
            luaProcess.stdout.on('data', (data) => {
                stdout += data.toString();
            });
            
            luaProcess.stderr.on('data', (data) => {
                stderr += data.toString();
            });
            
            luaProcess.on('close', (code) => {
                resolve({
                    success: true,
                    valid: code === 0 && !stderr,
                    output: stdout,
                    errors: stderr || null
                });
            });
            
            luaProcess.on('error', (error) => {
                resolve({
                    success: false,
                    error: error.message
                });
            });
        });
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

async function validateZipArchive(filePath) {
    try {
        const validatorPath = path.resolve(__dirname, CONFIG.LUA_VALIDATOR_PATH);
        
        // Security: Use spawn with array arguments to prevent command injection
        const { spawn } = require('child_process');
        
        return new Promise((resolve, reject) => {
            const luaProcess = spawn('lua', [validatorPath, '--archive', filePath]);
            let stdout = '';
            let stderr = '';
            
            luaProcess.stdout.on('data', (data) => {
                stdout += data.toString();
            });
            
            luaProcess.stderr.on('data', (data) => {
                stderr += data.toString();
            });
            
            luaProcess.on('close', (code) => {
                resolve({
                    success: true,
                    valid: code === 0 && !stderr,
                    output: stdout,
                    errors: stderr || null
                });
            });
            
            luaProcess.on('error', (error) => {
                resolve({
                    success: false,
                    error: error.message
                });
            });
        });
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

function saveValidationResult(username, result) {
    if (!validationHistory.has(username)) {
        validationHistory.set(username, []);
    }
    
    const history = validationHistory.get(username);
    history.push({
        ...result,
        timestamp: new Date().toISOString()
    });
    
    // Keep only last 100 results
    if (history.length > 100) {
        history.shift();
    }
}

// ============================================================================
// API ROUTES
// ============================================================================

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '7.0.0'
    });
});

// API documentation
app.get('/api/docs', (req, res) => {
    res.json({
        version: '7.0.0',
        endpoints: {
            auth: {
                'POST /api/auth/register': 'Register new user',
                'POST /api/auth/login': 'Login and get JWT token',
                'GET /api/auth/profile': 'Get user profile (requires auth)'
            },
            validation: {
                'POST /api/validate/file': 'Validate single .lua file (requires auth)',
                'POST /api/validate/archive': 'Validate .zip mod archive (requires auth)',
                'GET /api/validate/history': 'Get validation history (requires auth)'
            },
            admin: {
                'GET /api/admin/users': 'List all users (requires admin)',
                'DELETE /api/admin/users/:username': 'Delete user (requires admin)'
            }
        }
    });
});

// ============================================================================
// AUTHENTICATION ROUTES
// ============================================================================

// Register new user
app.post('/api/auth/register', async (req, res) => {
    try {
        const { username, password, email } = req.body;
        
        if (!username || !password || !email) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        if (users.has(username)) {
            return res.status(409).json({ error: 'Username already exists' });
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        
        users.set(username, {
            username,
            password: hashedPassword,
            email,
            role: 'user',
            created_at: new Date().toISOString()
        });
        
        res.status(201).json({
            message: 'User registered successfully',
            username
        });
    } catch (error) {
        res.status(500).json({ error: 'Registration failed', details: error.message });
    }
});

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        if (!username || !password) {
            return res.status(400).json({ error: 'Missing credentials' });
        }
        
        const user = users.get(username);
        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const token = jwt.sign(
            { username: user.username, role: user.role },
            CONFIG.JWT_SECRET,
            { expiresIn: CONFIG.JWT_EXPIRES_IN }
        );
        
        res.json({
            message: 'Login successful',
            token,
            user: {
                username: user.username,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Login failed', details: error.message });
    }
});

// Get user profile
app.get('/api/auth/profile', authenticateToken, (req, res) => {
    const user = users.get(req.user.username);
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({
        username: user.username,
        email: user.email,
        role: user.role,
        created_at: user.created_at
    });
});

// ============================================================================
// VALIDATION ROUTES
// ============================================================================

// Validate single Lua file
app.post('/api/validate/file', authenticateToken, upload.single('file'), async (req, res) => {
    let filePath = null;
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }
        
        // Security: Validate and sanitize file path
        filePath = validateFilePath(req.file.path, CONFIG.UPLOAD_DIR);
        if (!filePath) {
            // Clean up with original path if validation fails
            try { await fs.unlink(req.file.path); } catch (e) {}
            return res.status(400).json({ error: 'Invalid file path' });
        }
        
        const result = await validateLuaFile(filePath);
        
        // Save to history
        saveValidationResult(req.user.username, {
            type: 'file',
            filename: req.file.originalname,
            result
        });
        
        // Clean up uploaded file
        await fs.unlink(filePath).catch(() => {});
        
        res.json({
            filename: req.file.originalname,
            validation: result
        });
    } catch (error) {
        if (filePath) {
            await fs.unlink(filePath).catch(() => {});
        }
        res.status(500).json({ error: 'Validation failed', details: error.message });
    }
});

// Validate ZIP archive
app.post('/api/validate/archive', authenticateToken, upload.single('archive'), async (req, res) => {
    let filePath = null;
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No archive uploaded' });
        }
        
        // Security: Validate and sanitize file path
        filePath = validateFilePath(req.file.path, CONFIG.UPLOAD_DIR);
        if (!filePath) {
            // Clean up with original path if validation fails
            try { await fs.unlink(req.file.path); } catch (e) {}
            return res.status(400).json({ error: 'Invalid file path' });
        }
        
        const result = await validateZipArchive(filePath);
        
        // Save to history
        saveValidationResult(req.user.username, {
            type: 'archive',
            filename: req.file.originalname,
            result
        });
        
        // Clean up uploaded file
        await fs.unlink(filePath).catch(() => {});
        
        res.json({
            filename: req.file.originalname,
            validation: result
        });
    } catch (error) {
        if (filePath) {
            await fs.unlink(filePath).catch(() => {});
        }
        res.status(500).json({ error: 'Validation failed', details: error.message });
    }
});

// Get validation history
app.get('/api/validate/history', authenticateToken, (req, res) => {
    const history = validationHistory.get(req.user.username) || [];
    
    res.json({
        username: req.user.username,
        total_validations: history.length,
        history: history.slice(-50) // Return last 50 results
    });
});

// ============================================================================
// ADMIN ROUTES
// ============================================================================

const requireAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
    }
    next();
};

// List all users
app.get('/api/admin/users', authenticateToken, requireAdmin, (req, res) => {
    const userList = Array.from(users.values()).map(user => ({
        username: user.username,
        email: user.email,
        role: user.role,
        created_at: user.created_at
    }));
    
    res.json({
        total: userList.length,
        users: userList
    });
});

// Delete user
app.delete('/api/admin/users/:username', authenticateToken, requireAdmin, (req, res) => {
    const { username } = req.params;
    
    if (username === 'admin') {
        return res.status(400).json({ error: 'Cannot delete admin user' });
    }
    
    if (!users.has(username)) {
        return res.status(404).json({ error: 'User not found' });
    }
    
    users.delete(username);
    validationHistory.delete(username);
    
    res.json({ message: 'User deleted successfully' });
});

// Get system statistics
app.get('/api/admin/stats', authenticateToken, requireAdmin, (req, res) => {
    let totalValidations = 0;
    validationHistory.forEach(history => {
        totalValidations += history.length;
    });
    
    res.json({
        total_users: users.size,
        total_validations: totalValidations,
        uptime_seconds: process.uptime(),
        memory_usage: process.memoryUsage(),
        node_version: process.version
    });
});

// ============================================================================
// ERROR HANDLING
// ============================================================================

app.use((err, req, res, next) => {
    console.error('Error:', err);
    
    if (err.name === 'MulterError') {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ error: 'File too large' });
        }
        return res.status(400).json({ error: err.message });
    }
    
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// ============================================================================
// SERVER INITIALIZATION
// ============================================================================

async function initializeServer() {
    try {
        // Create upload directory
        await fs.mkdir(CONFIG.UPLOAD_DIR, { recursive: true });
        
        // Start server
        app.listen(CONFIG.PORT, () => {
            console.log(`
========================================
Factorio Mod Validator Backend API
Phase 7: Production-Ready System
========================================
Server running on port ${CONFIG.PORT}
Environment: ${process.env.NODE_ENV || 'development'}
Upload directory: ${CONFIG.UPLOAD_DIR}
Rate limit: ${CONFIG.RATE_LIMIT_MAX_REQUESTS} requests per ${CONFIG.RATE_LIMIT_WINDOW / 60000} minutes

Default admin credentials:
  Username: admin
  Password: admin123

API Documentation: http://localhost:${CONFIG.PORT}/api/docs
Health Check: http://localhost:${CONFIG.PORT}/api/health
========================================
            `);
        });
    } catch (error) {
        console.error('Failed to initialize server:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    process.exit(0);
});

// Start server if run directly
if (require.main === module) {
    initializeServer();
}

module.exports = app;
