// API and WebSocket configuration
export const API_CONFIG = {
  // Base API URL for HTTP requests
  API_BASE_URL: 'https://resq-qbiz.onrender.com/api',
  
  // WebSocket URL for real-time communication
  WS_BASE_URL: 'wss://resq-qbiz.onrender.com',
  
  // For local development, uncomment these:
  // API_BASE_URL: 'http://localhost:5000/api',
  // WS_BASE_URL: 'ws://localhost:5000',
};

// App constants
export const APP_CONFIG = {
  APP_NAME: 'ResQ',
  VERSION: '1.0.0',
  MAX_RECORDING_DURATION: 30000, // 30 seconds
  WEBSOCKET_RECONNECT_ATTEMPTS: 5,
  WEBSOCKET_RECONNECT_DELAY: 1000,
};