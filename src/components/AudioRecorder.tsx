import React, { useState, useRef, useEffect } from 'react';
import { Mic, Square, Play, Pause, AlertTriangle, Activity, X } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useWebSocket } from '../hooks/useWebSocket';
import { recordingsAPI } from '../services/api';

export default function AudioRecorder() {
  const { token } = useAuth();
  const { sendEmergencyAlert } = useWebSocket();
  const [isRecording, setIsRecording] = useState(false);
  const [isMonitoring, setIsMonitoring] = useState(false);
  const [audioLevel, setAudioLevel] = useState(0);
  const [status, setStatus] = useState('idle');
  const [recordingDuration, setRecordingDuration] = useState(0);
  const [showEmergencyPopup, setShowEmergencyPopup] = useState(false);
  const [emergencyDetails, setEmergencyDetails] = useState({ 
    message: '', 
    confidence: 0, 
    keywords: [] as string[], 
    emergencyType: '', 
    riskLevel: '', 
    assemblyAI: null as any 
  });


  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const monitoringIntervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
      if (monitoringIntervalRef.current) clearInterval(monitoringIntervalRef.current);
      stopRecording();
      stopMonitoring();
    };
  }, []);

  const startMonitoring = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      // Set up audio analysis for monitoring
      const audioContext = new AudioContext();
      const analyser = audioContext.createAnalyser();
      const microphone = audioContext.createMediaStreamSource(stream);
      
      analyser.fftSize = 256;
      microphone.connect(analyser);
      analyserRef.current = analyser;

      setIsMonitoring(true);
      setStatus('monitoring');

      // Monitor audio levels
      monitoringIntervalRef.current = setInterval(() => {
        if (analyserRef.current) {
          const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount);
          analyserRef.current.getByteFrequencyData(dataArray);
          
          const average = dataArray.reduce((a, b) => a + b) / dataArray.length;
          setAudioLevel(average);
        }
      }, 100);
    } catch (error) {
      console.error('Error accessing microphone:', error);
      setStatus('error');
    }
  };

  const stopMonitoring = () => {
    if (monitoringIntervalRef.current) {
      clearInterval(monitoringIntervalRef.current);
      monitoringIntervalRef.current = null;
    }

    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }

    setIsMonitoring(false);
    setAudioLevel(0);
    setStatus('idle');
  };

  const startRecording = async () => {
    if (isRecording) return;

    try {
      let stream = streamRef.current;
      if (!stream) {
        stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        streamRef.current = stream;
      }

      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      chunksRef.current = [];

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunksRef.current.push(event.data);
        }
      };

      mediaRecorder.onstop = async () => {
        if (chunksRef.current.length > 0) {
          const audioBlob = new Blob(chunksRef.current, { type: 'audio/webm' });
          await processRecording(audioBlob);
        }
      };

      mediaRecorder.start();
      setIsRecording(true);
      setStatus('recording');
      setRecordingDuration(0);

      // Update duration every second
      intervalRef.current = setInterval(() => {
        setRecordingDuration(prev => prev + 1);
      }, 1000);

      // Auto-stop recording after 30 seconds
      setTimeout(() => {
        if (isRecording) {
          stopRecording();
        }
      }, 30000);

    } catch (error) {
      console.error('Error starting recording:', error);
      setStatus('error');
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
      setStatus(isMonitoring ? 'monitoring' : 'idle');

      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    }
  };

  const processRecording = async (audioBlob: Blob) => {
    console.log('processRecording called with blob size:', audioBlob.size);
    if (!token) {
      console.log('No token available');
      return;
    }

    try {
      setStatus('processing');
      const filename = `recording-${Date.now()}.webm`;
      const result = await recordingsAPI.uploadRecording(token, audioBlob, filename);

      console.log('API Response:', result);
      console.log('Is Emergency:', result.recording.isEmergency);
      console.log('Emergency Analysis:', result.emergencyAnalysis);

      if (result.recording.isEmergency) {
        // Send real-time emergency alert
        sendEmergencyAlert(
          result.recording.transcription,
          result.recording.confidence
        );
        
        // Show emergency popup
        setEmergencyDetails({
          message: result.recording.transcription,
          confidence: result.recording.confidence,
          keywords: result.recording.keywords || [],
          emergencyType: result.recording.emergencyType || '',
          riskLevel: result.emergencyAnalysis?.riskLevel || 'UNKNOWN',
          assemblyAI: result.assemblyAI || null
        });
        console.log('Setting showEmergencyPopup to true');
        setShowEmergencyPopup(true);
        
        setStatus('emergency_detected');
        setTimeout(() => setStatus(isMonitoring ? 'monitoring' : 'idle'), 3000);
      } else {
        setStatus(isMonitoring ? 'monitoring' : 'idle');
      }
    } catch (error) {
      console.error('Error processing recording:', error);
      setStatus('error');
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getStatusColor = () => {
    switch (status) {
      case 'recording':
        return 'text-red-600 bg-red-100';
      case 'monitoring':
        return 'text-blue-600 bg-blue-100';
      case 'emergency_detected':
        return 'text-orange-600 bg-orange-100';
      case 'processing':
        return 'text-yellow-600 bg-yellow-100';
      case 'error':
        return 'text-red-600 bg-red-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'recording':
        return 'Recording in progress...';
      case 'monitoring':
        return 'Monitoring for emergencies';
      case 'emergency_detected':
        return 'Emergency detected! Alert sent.';
      case 'processing':
        return 'Processing audio...';
      case 'error':
        return 'Error occurred';
      default:
        return 'Ready to monitor';
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-6">
      <div className="max-w-4xl mx-auto">
        {/* NEW Emergency Modal - Recreated from scratch */}
        {showEmergencyPopup && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* Backdrop */}
            <div 
              className="absolute inset-0 bg-black opacity-75"
              onClick={() => setShowEmergencyPopup(false)}
            ></div>
            
            {/* Modal */}
            <div className="relative bg-white rounded-xl shadow-2xl max-w-md w-full overflow-hidden border-4 border-red-500">
              {/* Header with red background */}
              <div className="bg-red-600 px-6 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <AlertTriangle className="h-8 w-8 text-white" />
                    <h2 className="text-xl font-bold text-white">🚨 EMERGENCY ALERT</h2>
                  </div>
                  <button
                    onClick={() => setShowEmergencyPopup(false)}
                    className="text-white hover:text-red-200 transition-colors"
                  >
                    <X className="h-6 w-6" />
                  </button>
                </div>
              </div>

              {/* Content */}
              <div className="p-6">
                {/* Transcription */}
                <div className="mb-4">
                  <h3 className="font-bold text-gray-800 mb-2">Detected Speech:</h3>
                  <div className="bg-red-50 border-l-4 border-red-500 p-3 rounded">
                    <p className="text-red-800 font-medium text-lg">
                      "{emergencyDetails.message}"
                    </p>
                  </div>
                </div>

                {/* Details Grid */}
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="text-center p-3 bg-gray-100 rounded-lg">
                    <p className="text-sm text-gray-600">Emergency Type</p>
                    <p className="font-bold text-gray-900 uppercase">
                      {emergencyDetails.emergencyType || 'GENERAL'}
                    </p>
                  </div>
                  <div className="text-center p-3 bg-gray-100 rounded-lg">
                    <p className="text-sm text-gray-600">Risk Level</p>
                    <p className={`font-bold ${
                      emergencyDetails.riskLevel === 'HIGH' ? 'text-red-600' : 
                      emergencyDetails.riskLevel === 'MEDIUM' ? 'text-orange-600' : 'text-yellow-600'
                    }`}>
                      {emergencyDetails.riskLevel}
                    </p>
                  </div>
                </div>

                {/* Confidence Bar */}
                <div className="mb-4">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm font-medium text-gray-700">Confidence Level</span>
                    <span className="text-sm font-bold text-gray-900">
                      {Math.round(emergencyDetails.confidence * 100)}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-3">
                    <div 
                      className="bg-red-600 h-3 rounded-full transition-all duration-500" 
                      style={{ width: `${emergencyDetails.confidence * 100}%` }}
                    ></div>
                  </div>
                </div>

                {/* Keywords */}
                {emergencyDetails.keywords && emergencyDetails.keywords.length > 0 && (
                  <div className="mb-4">
                    <h4 className="text-sm font-medium text-gray-700 mb-2">Detected Keywords:</h4>
                    <div className="flex flex-wrap gap-2">
                      {emergencyDetails.keywords.map((keyword, index) => (
                        <span
                          key={index}
                          className="bg-red-100 text-red-800 text-xs font-medium px-2.5 py-1 rounded-full"
                        >
                          {keyword}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Alert Message */}
                <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                  <div className="flex items-start space-x-2">
                    <AlertTriangle className="h-5 w-5 text-yellow-600 mt-0.5" />
                    <p className="text-yellow-800 text-sm">
                      Emergency alert has been sent automatically. Emergency services will be contacted if this is a genuine emergency.
                    </p>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex space-x-3">
                  <button
                    onClick={() => setShowEmergencyPopup(false)}
                    className="flex-1 bg-red-600 hover:bg-red-700 text-white font-semibold py-3 px-4 rounded-lg transition-colors"
                  >
                    Acknowledge Emergency
                  </button>
                  <button
                    onClick={() => setShowEmergencyPopup(false)}
                    className="flex-1 bg-gray-500 hover:bg-gray-600 text-white font-semibold py-3 px-4 rounded-lg transition-colors"
                  >
                    False Alarm
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Main Interface Card */}
        <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
          {/* Header Section */}
          <div className="bg-gradient-to-r from-blue-600 to-indigo-700 px-8 py-6">
            <div className="text-center">
              <h1 className="text-3xl font-bold text-white mb-2">
                🎤 Emergency Detection System
              </h1>
              <p className="text-blue-100">
                Advanced voice monitoring and emergency response system
              </p>
            </div>
          </div>

          {/* Status Bar */}
          <div className="px-8 py-4 bg-gray-50 border-b">
            <div className="flex items-center justify-center">
              <div className={`flex items-center px-6 py-3 rounded-full text-sm font-semibold ${getStatusColor()}`}>
                <Activity className="h-5 w-5 mr-2" />
                {getStatusText()}
              </div>
            </div>
          </div>

          {/* Main Content Area */}
          <div className="p-8">
            {/* Audio Level Visualization - Only show when monitoring */}
            {isMonitoring && (
              <div className="mb-8">
                <div className="text-center mb-4">
                  <h3 className="text-lg font-semibold text-gray-800 mb-2">
                    🔊 Audio Monitoring
                  </h3>
                  <p className="text-gray-600 text-sm">
                    Real-time audio level detection
                  </p>
                </div>
                <div className="relative">
                  <div className="bg-gray-200 rounded-full h-8 overflow-hidden shadow-inner">
                    <div 
                      className="h-full bg-gradient-to-r from-green-400 via-yellow-400 to-red-500 transition-all duration-200 rounded-full"
                      style={{ width: `${Math.min((audioLevel / 100) * 100, 100)}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-gray-500 mt-1">
                    <span>Silent</span>
                    <span className="font-medium">Level: {Math.round(audioLevel)}%</span>
                    <span>Loud</span>
                  </div>
                </div>
              </div>
            )}

            {/* Recording Timer - Only show when recording */}
            {isRecording && (
              <div className="text-center mb-8">
                <div className="inline-block bg-red-50 border-2 border-red-200 rounded-2xl p-6">
                  <div className="text-5xl font-mono font-bold text-red-600 mb-2">
                    {formatTime(recordingDuration)}
                  </div>
                  <div className="flex items-center justify-center space-x-2">
                    <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
                    <p className="text-red-700 font-semibold">Recording in progress...</p>
                  </div>
                </div>
              </div>
            )}

            {/* Control Panel */}
            <div className="space-y-6">
              {!isMonitoring ? (
                /* Initial State - Start Monitoring */
                <div className="text-center space-y-4">
                  <div className="mb-6">
                    <h2 className="text-2xl font-bold text-gray-800 mb-2">
                      Ready to Start Monitoring
                    </h2>
                    <p className="text-gray-600">
                      Click the button below to enable continuous audio monitoring
                    </p>
                  </div>
                  <button
                    onClick={startMonitoring}
                    className="inline-flex items-center px-12 py-4 p-2 rounded-md bg-blue-600 hover:bg-blue-700 text-white text-xl font-bold  shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-200"
                  >
                    <Play className="h-8 w-8 mr-3" />
                    Start Monitoring
                  </button>
                </div>
              ) : (
                /* Monitoring Active State */
                <div className="space-y-6">
                  <div className="text-center mb-6">
                    <h2 className="text-2xl font-bold text-gray-800 mb-2">
                      🟢 Monitoring Active
                    </h2>
                    <p className="text-gray-600">
                      System is ready to record. Click "Start Recording" when needed.
                    </p>
                  </div>

                  {/* Recording Controls */}
                  <div className="flex justify-center space-x-4">
                    {!isRecording ? (
                      <button
                        onClick={startRecording}
                        disabled={status === 'processing'}
                        className={`inline-flex items-center px-8 py-4 bg-black rounded-md text-white text-lg font-semibold p-2 shadow-lg transition-all duration-200 ${
                          status === 'processing' 
                            ? 'bg-gray-400 cursor-not-allowed' 
                            : 'bg-green-600 hover:bg-green-700 hover:shadow-xl transform hover:scale-105'
                        }`}
                      >
                        <Mic className="h-6 w-6 mr-3" />
                        {status === 'processing' ? 'Processing...' : 'Start Recording'}
                      </button>
                    ) : (
                      <button
                        onClick={stopRecording}
                        className="inline-flex items-center px-8 py-4 bg-red-600 hover:bg-red-700 text-white text-lg font-semibold rounded-md p-2 shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-200 animate-pulse"
                      >
                        <Square className="h-6 w-6 mr-3" />
                        Stop Recording
                      </button>
                    )}

                    <button
                      onClick={stopMonitoring}
                      className="inline-flex items-center p-2 rounded-md px-8 py-4 bg-gray-600 hover:bg-gray-700 text-white text-lg font-semibold shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-200"
                    >
                      <Pause className="h-6 w-6 mr-3" />
                      Stop Monitoring
                    </button>
                  </div>

                  {/* Test Emergency Button */}
                  <div className="text-center pt-4 border-t">
                    <button
                      onClick={() => {
                        setEmergencyDetails({
                          message: "Test emergency - help me please!",
                          confidence: 0.95,
                          keywords: ['help', 'emergency', 'please'],
                          emergencyType: 'help',
                          riskLevel: 'HIGH',
                          assemblyAI: null
                        });
                        setShowEmergencyPopup(true);
                      }}
                      className="inline-flex items-center px-6 py-3 bg-orange-500 hover:bg-orange-600 text-white font-medium rounded-lg shadow-md hover:shadow-lg transition-all duration-200"
                    >
                      <AlertTriangle className="h-5 w-5 mr-2" />
                      Test Emergency Modal
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Instructions Footer */}
          <div className="bg-gray-50 px-8 py-6 border-t">
            <div className="max-w-3xl mx-auto">
              <h3 className="text-lg font-semibold text-gray-800 mb-3 text-center">
                📋 How to Use Emergency Detection
              </h3>
              <div className="grid md:grid-cols-2 gap-4 text-sm text-gray-600">
                <div className="space-y-2">
                  <div className="flex items-start space-x-2">
                    <span className="text-blue-600 font-bold">1.</span>
                    <span><strong>Start Monitoring:</strong> Click to enable continuous audio monitoring</span>
                  </div>
                  <div className="flex items-start space-x-2">
                    <span className="text-blue-600 font-bold">2.</span>
                    <span><strong>Start Recording:</strong> Click when you need to record audio</span>
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="flex items-start space-x-2">
                    <span className="text-blue-600 font-bold">3.</span>
                    <span><strong>Stop Recording:</strong> Click to end recording and analyze for emergencies</span>
                  </div>
                  <div className="flex items-start space-x-2">
                    <span className="text-blue-600 font-bold">4.</span>
                    <span><strong>Emergency Alert:</strong> Modal appears if danger keywords are detected</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}