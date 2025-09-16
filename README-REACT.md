# ResQ React Frontend - Emergency Detection System

## 🌟 Overview

The ResQ React frontend is a modern, responsive web application that provides real-time emergency detection through audio monitoring. It connects to the ResQ backend API and uses WebSocket for real-time alerts.

## 🏗️ Architecture

### Technology Stack
- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **Context API** for state management
- **Web Audio API** for audio recording
- **WebSocket** for real-time communication

### Project Structure
```
src/
├── components/          # Reusable UI components
│   ├── AudioRecorder.tsx    # Main audio recording component
│   ├── Dashboard.tsx        # User dashboard
│   ├── EmergencyAlerts.tsx  # Emergency notification system
│   ├── Header.tsx           # Navigation header
│   ├── LoginForm.tsx        # User authentication form
│   ├── Profile.tsx          # User profile management
│   └── RecordingsList.tsx   # Display user recordings
├── contexts/            # React Context providers
│   ├── AuthContext.tsx      # Authentication state management
│   └── WebSocketContext.tsx # WebSocket connection management
├── hooks/              # Custom React hooks
│   ├── useAuth.ts           # Authentication logic
│   └── useWebSocket.ts      # WebSocket connection logic
├── services/           # API and external services
│   └── api.ts              # Backend API communication
├── App.tsx            # Main application component
├── main.tsx           # Application entry point
└── index.css          # Global styles
```

## 🚀 Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn package manager
- ResQ backend server running

### 1. Install Dependencies
```bash
npm install
# or
yarn install
```

### 2. Environment Configuration
Create a `.env` file in the project root:
```env
VITE_API_URL=http://localhost:5000
VITE_WS_URL=ws://localhost:5000
```

### 3. Start Development Server
```bash
npm run dev
# or
yarn dev
```

The application will be available at `http://localhost:5173`

### 4. Build for Production
```bash
npm run build
# or
yarn build
```

## 🎯 Core Features

### 1. Authentication System
- **User Registration**: Create new accounts with email validation
- **User Login**: Secure JWT-based authentication
- **Protected Routes**: Automatic redirection for unauthorized users
- **Persistent Sessions**: Remember user login state

### 2. Audio Recording & Monitoring
- **Real-time Audio Monitoring**: Continuous audio level detection
- **Manual Recording**: User-initiated audio recording
- **Audio Visualization**: Visual feedback during recording
- **WebRTC Integration**: Browser-based audio capture

### 3. Emergency Detection
- **AI-Powered Analysis**: Backend integration with AssemblyAI
- **Keyword Detection**: Identifies emergency-related phrases
- **Confidence Scoring**: Reliability assessment of detections
- **Real-time Alerts**: Immediate notification system

### 4. User Interface
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Modern UI/UX**: Clean, intuitive interface
- **Real-time Updates**: Live status indicators
- **Accessibility**: WCAG compliant components

## 🧩 Component Details

### AudioRecorder Component
The main component handling all audio-related functionality:

```typescript
// Key features:
- Audio permission handling
- Recording state management
- Real-time audio level monitoring
- Emergency detection processing
- Visual feedback and animations
```

**State Management:**
- `isRecording`: Current recording status
- `isMonitoring`: Background monitoring status
- `audioLevel`: Real-time audio input level
- `status`: Current system status ('idle', 'recording', 'processing', etc.)
- `recordingDuration`: Timer for active recordings

**Key Methods:**
- `startMonitoring()`: Begin continuous audio monitoring
- `stopMonitoring()`: End audio monitoring
- `startRecording()`: Begin manual recording
- `stopRecording()`: End recording and process audio
- `processRecording()`: Send audio to backend for analysis

### Emergency Modal System
Displays emergency detection results:

```typescript
// Emergency details shown:
- Transcription of detected speech
- Confidence percentage
- Emergency keywords found
- Risk level assessment
- Recommended actions
```

### Context Providers

#### AuthContext
Manages user authentication state:
```typescript
interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (userData: RegisterData) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}
```

#### WebSocketContext
Handles real-time communication:
```typescript
interface WebSocketContextType {
  isConnected: boolean;
  lastMessage: any;
  sendMessage: (message: any) => void;
  sendEmergencyAlert: (transcription: string, confidence: number) => void;
}
```

## 🔄 Application Flow

### 1. User Authentication Flow
```
User visits app → Check auth token → 
If authenticated: Go to Dashboard
If not: Show Login Form →
User logs in → Store JWT token → 
Connect WebSocket → Navigate to Dashboard
```

### 2. Audio Monitoring Flow
```
User clicks "Start Monitoring" →
Request microphone permission →
Create audio stream →
Set up audio analysis →
Monitor audio levels →
Display real-time feedback
```

### 3. Recording & Emergency Detection Flow
```
User clicks "Start Recording" →
Begin MediaRecorder →
Show recording timer →
User clicks "Stop Recording" →
Create audio blob →
Upload to backend API →
Backend processes with AssemblyAI →
Return analysis results →
If emergency detected: Show emergency modal
If not: Return to monitoring state
```

### 4. Emergency Alert Flow
```
Emergency detected →
Send WebSocket alert →
Show emergency modal →
Display transcription & confidence →
Show detected keywords →
Provide emergency contact options
```

## 🎨 Styling and UI

### Tailwind CSS Configuration
The project uses Tailwind CSS for styling with custom configurations:

- **Color Palette**: Blue/indigo gradient theme
- **Responsive Design**: Mobile-first approach
- **Component Classes**: Reusable utility classes
- **Animations**: Custom CSS animations for recording states

### Key UI Components
- **Gradient Backgrounds**: Blue to indigo gradients
- **Card Layouts**: Elevated, rounded containers
- **Button States**: Different styles for various actions
- **Status Indicators**: Color-coded status displays
- **Modal Overlays**: Emergency alert popups

## 🔌 API Integration

### Backend Communication
All API calls are handled through the `api.ts` service:

```typescript
// Available API methods:
- registerUser(userData)
- loginUser(credentials)
- getUserProfile(token)
- uploadRecording(token, audioBlob, filename)
- getRecordings(token)
```

### WebSocket Integration
Real-time features powered by WebSocket connection:

```typescript
// WebSocket events:
- connection: Establish real-time link
- emergency_alert: Broadcast emergency detection
- disconnect: Handle connection loss
- reconnect: Automatic reconnection logic
```

## 📱 Browser Compatibility

### Supported Browsers
- Chrome 80+
- Firefox 75+
- Safari 13+
- Edge 80+

### Required Browser Features
- WebRTC MediaDevices API
- Web Audio API
- WebSocket support
- File API for audio blob handling

## 🔧 Development

### Available Scripts
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
npm run type-check   # TypeScript type checking
```

### Development Tools
- **TypeScript**: Type safety and better developer experience
- **ESLint**: Code quality and consistency
- **Prettier**: Code formatting
- **Vite**: Fast development server and building

### Code Structure Guidelines
- **Component Organization**: One component per file
- **Custom Hooks**: Extract reusable logic
- **Type Definitions**: Strong TypeScript typing
- **Error Handling**: Comprehensive error boundaries

## 🐛 Troubleshooting

### Common Issues

#### Microphone Permission Denied
```javascript
// Handle permission errors
if (error.name === 'NotAllowedError') {
  console.log('Microphone permission denied');
  // Show user instructions to enable microphone
}
```

#### WebSocket Connection Failed
```javascript
// Implement reconnection logic
useEffect(() => {
  const reconnectInterval = setInterval(() => {
    if (!isConnected) {
      connect();
    }
  }, 5000);
  
  return () => clearInterval(reconnectInterval);
}, [isConnected]);
```

#### API Request Failures
```javascript
// Implement retry logic with exponential backoff
const retryRequest = async (fn, retries = 3) => {
  try {
    return await fn();
  } catch (error) {
    if (retries > 0) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      return retryRequest(fn, retries - 1);
    }
    throw error;
  }
};
```

## 🧪 Testing

### Testing Strategy
- **Unit Tests**: Individual component testing
- **Integration Tests**: API and WebSocket communication
- **E2E Tests**: Complete user workflows
- **Browser Testing**: Cross-browser compatibility

### Test Commands
```bash
npm run test          # Run unit tests
npm run test:watch    # Run tests in watch mode
npm run test:coverage # Generate coverage report
npm run e2e          # Run end-to-end tests
```

## 🚀 Deployment

### Build Process
```bash
npm run build
```

### Deployment Options
- **Vercel**: Automatic deployments from Git
- **Netlify**: Static site hosting
- **AWS S3**: Static website hosting
- **Custom Server**: Serve built files

### Environment Variables for Production
```env
VITE_API_URL=https://your-backend-domain.com
VITE_WS_URL=wss://your-backend-domain.com
```

## 📈 Performance Optimization

### Key Optimizations
- **Code Splitting**: Lazy loading of routes
- **Asset Optimization**: Vite's built-in optimizations
- **WebSocket Management**: Efficient connection handling
- **Memory Management**: Proper cleanup of audio streams

### Monitoring
- **Error Tracking**: Implement error reporting
- **Performance Metrics**: Monitor load times
- **User Analytics**: Track user interactions

## 🔐 Security Considerations

### Security Measures
- **JWT Token Management**: Secure token storage
- **HTTPS Only**: Force secure connections
- **Input Validation**: Client-side validation
- **CSP Headers**: Content Security Policy
- **Audio Data Protection**: Secure audio handling

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review browser console for errors
3. Verify backend API connectivity
4. Check WebSocket connection status

## 🔄 Updates and Maintenance

### Regular Maintenance
- Keep dependencies updated
- Monitor browser compatibility
- Update API integrations
- Review security practices

This React frontend provides a robust, user-friendly interface for the ResQ emergency detection system with comprehensive audio monitoring and real-time alert capabilities.