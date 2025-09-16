import React, { createContext, useEffect, useState, ReactNode, useRef } from 'react';
import { useAuth } from '../hooks/useAuth';
import { API_CONFIG, APP_CONFIG } from '../config/constants';

interface EmergencyAlert {
  type: string;
  message: string;
  timestamp: string;
  confidence: number;
}

interface WebSocketContextType {
  isConnected: boolean;
  alerts: EmergencyAlert[];
  sendEmergencyAlert: (message: string, confidence: number) => void;
  clearAlerts: () => void;
}

const WebSocketContext = createContext<WebSocketContextType | null>(null);

export function WebSocketProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [isConnected, setIsConnected] = useState(false);
  const [alerts, setAlerts] = useState<EmergencyAlert[]>([]);
  const [reconnectAttempts, setReconnectAttempts] = useState(0);
  const maxReconnectAttempts = APP_CONFIG.WEBSOCKET_RECONNECT_ATTEMPTS;
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    if (!user) return;

    // Use the configured WebSocket URL
    const wsUrl = API_CONFIG.WS_BASE_URL;
    
    const connectWebSocket = () => {
      wsRef.current = new WebSocket(wsUrl);

      wsRef.current.onopen = () => {
        setIsConnected(true);
        setReconnectAttempts(0); // Reset attempts on successful connection
        
        // Authenticate with the WebSocket server
        wsRef.current?.send(JSON.stringify({
          type: 'auth',
          userId: user._id
        }));
      };

      wsRef.current.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          
          if (data.type === 'emergency_alert') {
            setAlerts(prev => [...prev, {
              type: data.type,
              message: data.message,
              timestamp: data.timestamp,
              confidence: data.confidence
            }]);
          }
        } catch (error) {
          console.error('WebSocket message error:', error);
        }
      };

      wsRef.current.onclose = () => {
        setIsConnected(false);
        
        // Only attempt to reconnect if we haven't exceeded max attempts
        if (reconnectAttempts < maxReconnectAttempts) {
          setReconnectAttempts(prev => prev + 1);
          const delay = Math.min(APP_CONFIG.WEBSOCKET_RECONNECT_DELAY * Math.pow(2, reconnectAttempts), 10000); // Exponential backoff
          setTimeout(connectWebSocket, delay);
        }
      };

      wsRef.current.onerror = () => {
        setIsConnected(false);
      };
    };

    connectWebSocket();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [user]);

  const sendEmergencyAlert = (message: string, confidence: number) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({
        type: 'emergency_detected',
        userId: user?._id,
        message,
        confidence
      }));
    }
  };

  const clearAlerts = () => {
    setAlerts([]);
  };

  const value = {
    isConnected,
    alerts,
    sendEmergencyAlert,
    clearAlerts
  };

  return (
    <WebSocketContext.Provider value={value}>
      {children}
    </WebSocketContext.Provider>
  );
}

export { WebSocketContext };