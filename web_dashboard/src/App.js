// Factorio Mod Validation Dashboard
// Phase 6: Web Interface for Validation Management
// Reference: React 18.2 - https://react.dev/

import React, { useState, useCallback } from 'react';
import './App.css';

// Main Dashboard Component
function ValidationDashboard() {
  const [selectedFile, setSelectedFile] = useState(null);
  const [validationResults, setValidationResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('upload');

  const handleFileUpload = useCallback((event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedFile(file);
      setValidationResults(null);
    }
  }, []);

  const validateFile = useCallback(async () => {
    if (!selectedFile) return;
    
    setLoading(true);
    
    // TODO: Production backend integration
    // Replace mock validation with actual API call to Lua validation engine
    // Example: const response = await fetch('/api/validate', {
    //   method: 'POST',
    //   body: formData
    // });
    // const results = await response.json();
    
    // MOCK VALIDATION - For demonstration only
    setTimeout(() => {
      const mockResults = {
        valid: true,
        filename: selectedFile.name,
        size: selectedFile.size,
        timestamp: new Date().toISOString(),
        syntax: {
          valid: true,
          errors: [],
          warnings: []
        },
        api_usage: {
          total_calls: 42,
          valid_calls: 40,
          invalid_calls: 2,
          coverage: 95.2
        },
        metrics: {
          lines_of_code: 234,
          cyclomatic_complexity: 12,
          maintainability_index: 78.5,
          halstead: {
            volume: 1234.5,
            difficulty: 12.3,
            effort: 15185.35
          }
        },
        issues: [
          {
            type: 'warning',
            line: 45,
            message: 'Deprecated API usage: game.player'
          },
          {
            type: 'error',
            line: 67,
            message: 'Invalid API call: undefined_function()'
          }
        ]
      };
      
      setValidationResults(mockResults);
      setLoading(false);
      setActiveTab('results');
    }, 1500);
  }, [selectedFile]);

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>🏭 Factorio Mod Validation Dashboard</h1>
        <p>Phase 6: Enhanced Validation & Analysis</p>
      </header>

      <nav className="dashboard-nav">
        <button 
          className={activeTab === 'upload' ? 'active' : ''}
          onClick={() => setActiveTab('upload')}
        >
          Upload
        </button>
        <button 
          className={activeTab === 'results' ? 'active' : ''}
          onClick={() => setActiveTab('results')}
          disabled={!validationResults}
        >
          Results
        </button>
        <button 
          className={activeTab === 'metrics' ? 'active' : ''}
          onClick={() => setActiveTab('metrics')}
          disabled={!validationResults}
        >
          Metrics
        </button>
        <button 
          className={activeTab === 'heatmap' ? 'active' : ''}
          onClick={() => setActiveTab('heatmap')}
          disabled={!validationResults}
        >
          API Heatmap
        </button>
      </nav>

      <main className="dashboard-main">
        {activeTab === 'upload' && (
          <FileUploader 
            onFileUpload={handleFileUpload}
            onValidate={validateFile}
            selectedFile={selectedFile}
            loading={loading}
          />
        )}
        
        {activeTab === 'results' && validationResults && (
          <ValidationResults results={validationResults} />
        )}
        
        {activeTab === 'metrics' && validationResults && (
          <MetricsChart metrics={validationResults.metrics} />
        )}
        
        {activeTab === 'heatmap' && validationResults && (
          <APIHeatmap apiUsage={validationResults.api_usage} />
        )}
      </main>
    </div>
  );
}

// File Upload Component
function FileUploader({ onFileUpload, onValidate, selectedFile, loading }) {
  return (
    <div className="file-uploader">
      <div className="upload-area">
        <input 
          type="file" 
          id="file-input"
          accept=".lua,.zip"
          onChange={onFileUpload}
          disabled={loading}
        />
        <label htmlFor="file-input" className="upload-label">
          {selectedFile ? (
            <div className="file-selected">
              <span className="file-icon">📄</span>
              <span className="file-name">{selectedFile.name}</span>
              <span className="file-size">
                ({Math.round(selectedFile.size / 1024)} KB)
              </span>
            </div>
          ) : (
            <div className="upload-prompt">
              <span className="upload-icon">⬆️</span>
              <span>Drop Lua file or ZIP archive here</span>
              <span className="upload-hint">or click to browse</span>
            </div>
          )}
        </label>
      </div>
      
      {selectedFile && (
        <button 
          className="validate-button"
          onClick={onValidate}
          disabled={loading}
        >
          {loading ? 'Validating...' : 'Validate File'}
        </button>
      )}
    </div>
  );
}

// Validation Results Component
function ValidationResults({ results }) {
  return (
    <div className="validation-results">
      <div className="results-header">
        <h2>{results.valid ? '✅ Validation Passed' : '❌ Validation Failed'}</h2>
        <div className="results-meta">
          <span>File: {results.filename}</span>
          <span>Validated: {new Date(results.timestamp).toLocaleString()}</span>
        </div>
      </div>

      <div className="results-grid">
        <div className="result-card">
          <h3>Syntax Analysis</h3>
          <div className="card-content">
            <div className="stat">
              <span className="stat-label">Status:</span>
              <span className={results.syntax.valid ? 'stat-success' : 'stat-error'}>
                {results.syntax.valid ? 'Valid' : 'Invalid'}
              </span>
            </div>
            <div className="stat">
              <span className="stat-label">Errors:</span>
              <span className="stat-value">{results.syntax.errors.length}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Warnings:</span>
              <span className="stat-value">{results.syntax.warnings.length}</span>
            </div>
          </div>
        </div>

        <div className="result-card">
          <h3>API Usage</h3>
          <div className="card-content">
            <div className="stat">
              <span className="stat-label">Total Calls:</span>
              <span className="stat-value">{results.api_usage.total_calls}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Valid:</span>
              <span className="stat-success">{results.api_usage.valid_calls}</span>
            </div>
            <div className="stat">
              <span className="stat-label">Coverage:</span>
              <span className="stat-value">{results.api_usage.coverage}%</span>
            </div>
          </div>
        </div>
      </div>

      {results.issues.length > 0 && (
        <div className="issues-list">
          <h3>Issues Found</h3>
          {results.issues.map((issue, index) => (
            <div key={index} className={`issue issue-${issue.type}`}>
              <span className="issue-type">{issue.type.toUpperCase()}</span>
              <span className="issue-line">Line {issue.line}</span>
              <span className="issue-message">{issue.message}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// Metrics Chart Component
function MetricsChart({ metrics }) {
  return (
    <div className="metrics-chart">
      <h2>Code Metrics</h2>
      
      <div className="metrics-grid">
        <div className="metric-card">
          <h3>Lines of Code</h3>
          <div className="metric-value large">{metrics.lines_of_code}</div>
        </div>
        
        <div className="metric-card">
          <h3>Cyclomatic Complexity</h3>
          <div className="metric-value large">{metrics.cyclomatic_complexity}</div>
          <div className="metric-rating">
            {metrics.cyclomatic_complexity <= 10 ? 'Low' : 
             metrics.cyclomatic_complexity <= 20 ? 'Moderate' : 'High'}
          </div>
        </div>
        
        <div className="metric-card">
          <h3>Maintainability Index</h3>
          <div className="metric-value large">{metrics.maintainability_index}</div>
          <div className="metric-progress">
            <div 
              className="metric-progress-bar"
              style={{width: `${metrics.maintainability_index}%`}}
            ></div>
          </div>
        </div>
      </div>

      <div className="halstead-metrics">
        <h3>Halstead Metrics</h3>
        <div className="halstead-grid">
          <div className="halstead-item">
            <span className="halstead-label">Volume:</span>
            <span className="halstead-value">{metrics.halstead.volume.toFixed(2)}</span>
          </div>
          <div className="halstead-item">
            <span className="halstead-label">Difficulty:</span>
            <span className="halstead-value">{metrics.halstead.difficulty.toFixed(2)}</span>
          </div>
          <div className="halstead-item">
            <span className="halstead-label">Effort:</span>
            <span className="halstead-value">{metrics.halstead.effort.toFixed(2)}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// API Heatmap Component
function APIHeatmap({ apiUsage }) {
  // Mock heatmap data
  const apiCategories = [
    { name: 'game', calls: 15, coverage: 95 },
    { name: 'defines', calls: 12, coverage: 100 },
    { name: 'script', calls: 8, coverage: 88 },
    { name: 'remote', calls: 5, coverage: 75 },
    { name: 'rendering', calls: 2, coverage: 50 }
  ];

  return (
    <div className="api-heatmap">
      <h2>API Usage Heatmap</h2>
      <p className="heatmap-subtitle">
        Coverage: {apiUsage.coverage}% 
        ({apiUsage.valid_calls}/{apiUsage.total_calls} valid calls)
      </p>
      
      <div className="heatmap-grid">
        {apiCategories.map((category, index) => (
          <div 
            key={index} 
            className="heatmap-cell"
            style={{
              backgroundColor: `rgba(76, 175, 80, ${category.coverage / 100})`,
              height: `${category.calls * 10}px`
            }}
          >
            <span className="cell-label">{category.name}</span>
            <span className="cell-value">{category.calls} calls</span>
            <span className="cell-coverage">{category.coverage}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function App() {
  return (
    <div className="App">
      <ValidationDashboard />
    </div>
  );
}

export default App;
