# Factorio Validation Web Dashboard

React-based web interface for Phase 6 validation features.

## Features

- **File Upload**: Drag-and-drop interface for .lua files and .zip archives
- **Real-time Validation**: Live syntax checking and API validation
- **Metrics Visualization**: Interactive charts for code metrics
- **API Heatmap**: Visual representation of API usage coverage
- **Issue Reporting**: Detailed error and warning display

## Installation

```bash
cd web_dashboard
npm install
```

## Development

```bash
npm start
```

Opens [http://localhost:3000](http://localhost:3000) in your browser.

## Build

```bash
npm run build
```

Creates optimized production build in `build/` directory.

## Architecture

- **React 18.2**: Modern React with hooks
- **Component-based**: Modular, reusable components
- **Responsive**: Mobile-friendly design
- **Mock Backend**: Simulated validation (connect to real backend API in production)

## Components

- `ValidationDashboard`: Main dashboard container
- `FileUploader`: File selection and upload
- `ValidationResults`: Display validation outcomes
- `MetricsChart`: Code metrics visualization
- `APIHeatmap`: API coverage heatmap

## Integration

Connect to backend validation API by replacing mock data in `validateFile()` function with actual API calls to Lua validation engine.

## References

- React Documentation: https://react.dev/
- Phase 5 Validation: ../tests/validation_engine.lua
- Phase 6 Enhanced Parser: ../tests/enhanced_parser.lua
