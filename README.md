# ResQ - Emergency Detection System

A comprehensive emergency detection system with React web frontend, Flutter mobile app, and Node.js backend that uses AI to analyze audio recordings for emergency situations.

## 🏗️ Project Structure

```
project/
├── server/                 # Node.js Backend
├── src/                   # React Frontend
├── flutter_frontend/      # Flutter Mobile App
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v16+)
- MongoDB
- AssemblyAI API Key
- React (for web frontend)
- Flutter SDK (for mobile app)

### 1. Backend Setup
```bash
cd server
npm install
cp .env.example .env  # Configure your environment variables
npm run dev
```

### 2. React Frontend Setup
```bash
npm install
npm run dev
```

### 3. Flutter Frontend Setup
```bash
cd flutter_frontend
flutter pub get
flutter run -d web  # For web version
```

## 🔧 Environment Variables

Create a `.env` file in the server directory:
```env
MONGODB_URI=mongodb://localhost:27017/resq
JWT_SECRET=your_jwt_secret_here
ASSEMBLYAI_API_KEY=your_assemblyai_api_key
PORT=5000
```

## 📱 Frontends

- **React Web App**: Modern web interface with real-time audio monitoring
- **Flutter Mobile App**: Cross-platform mobile application with native audio features

## 🔗 API Endpoints

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile
- `POST /api/recordings/upload` - Upload audio recording
- `GET /api/recordings` - Get user recordings

## 🎯 Features

- ✅ Real-time audio monitoring
- ✅ Emergency detection using AI
- ✅ WebSocket real-time alerts
- ✅ User authentication
- ✅ Audio recording and analysis
- ✅ Cross-platform support (Web + Mobile)

## 📚 Documentation

See individual README files:
- [React Frontend README](./README-REACT.md)
- [Flutter Frontend README](./flutter_frontend/README-FLUTTER.md)
- [Backend API Documentation](./server/README-API.md)