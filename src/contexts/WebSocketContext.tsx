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
  connectionStatus: 'connecting' | 'connected' | 'disconnected' | 'failed';
}

const WebSocketContext = createContext<WebSocketContextType | null>(null);

export function WebSocketProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [isConnected, setIsConnected] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<'connecting' | 'connected' | 'disconnected' | 'failed'>('disconnected');
  const [alerts, setAlerts] = useState<EmergencyAlert[]>([]);
  const [reconnectAttempts, setReconnectAttempts] = useState(0);
  const maxReconnectAttempts = APP_CONFIG.WEBSOCKET_RECONNECT_ATTEMPTS;
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    if (!user) return;

    // Use the configured WebSocket URL
    const wsUrl = API_CONFIG.WS_BASE_URL;
    
    const connectWebSocket = () => {
      console.log('Attempting to connect to WebSocket:', wsUrl);
      setConnectionStatus('connecting');
      
      try {
        wsRef.current = new WebSocket(wsUrl);
      } catch (error) {
        console.error('Failed to create WebSocket connection:', error);
        setConnectionStatus('failed');
        return;
      }

      wsRef.current.onopen = () => {
        console.log('WebSocket connected successfully');
        setIsConnected(true);
        setConnectionStatus('connected');
        setReconnectAttempts(0); // Reset attempts on successful connection
        
        // Wait a moment before sending auth message to ensure connection is fully established
        setTimeout(() => {
          if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
            wsRef.current.send(JSON.stringify({
              type: 'auth',
              userId: user._id
            }));
          }
        }, 100);
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

      wsRef.current.onclose = (event) => {
        console.log('WebSocket connection closed:', event.code, event.reason);
        setIsConnected(false);
        setConnectionStatus('disconnected');
        
        // Only attempt to reconnect if we haven't exceeded max attempts and it wasn't a normal closure
        if (reconnectAttempts < maxReconnectAttempts && event.code !== 1000) {
          setReconnectAttempts(prev => prev + 1);
          const delay = Math.min(APP_CONFIG.WEBSOCKET_RECONNECT_DELAY * Math.pow(2, reconnectAttempts), 10000); // Exponential backoff
          console.log(`Attempting to reconnect in ${delay}ms (attempt ${reconnectAttempts + 1}/${maxReconnectAttempts})`);
          setTimeout(connectWebSocket, delay);
        } else if (reconnectAttempts >= maxReconnectAttempts) {
          setConnectionStatus('failed');
        }
      };

      wsRef.current.onerror = (error) => {
        console.error('WebSocket error:', error);
        setIsConnected(false);
        setConnectionStatus('failed');
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
      console.log('Sending emergency alert via WebSocket');
      wsRef.current.send(JSON.stringify({
        type: 'emergency_detected',
        userId: user?._id,
        message,
        confidence
      }));
    } else {
      console.warn('WebSocket not connected, cannot send emergency alert. ReadyState:', wsRef.current?.readyState);
      // Could implement a queue here to send when reconnected
    }
  };

  const clearAlerts = () => {
    setAlerts([]);
  };

  const value = {
    isConnected,
    alerts,
    sendEmergencyAlert,
    clearAlerts,
    connectionStatus
  };

  return (
    <WebSocketContext.Provider value={value}>
      {children}
    </WebSocketContext.Provider>
  );
}

export { WebSocketContext };