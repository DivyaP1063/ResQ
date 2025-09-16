import React from 'react';
import { AlertTriangle, Clock, Trash2, Bell } from 'lucide-react';
import { useWebSocket } from '../hooks/useWebSocket';

export default function EmergencyAlerts() {
  const { alerts, clearAlerts } = useWebSocket();

  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleString();
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return 'text-red-600 bg-red-100';
    if (confidence >= 0.6) return 'text-orange-600 bg-orange-100';
    return 'text-yellow-600 bg-yellow-100';
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Emergency Alerts</h2>
        
        {alerts.length > 0 && (
          <button
            onClick={clearAlerts}
            className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Clear All
          </button>
        )}
      </div>

      {alerts.length === 0 ? (
        <div className="text-center py-12">
          <Bell className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No active alerts</h3>
          <p className="text-gray-500">
            Emergency alerts will appear here when the system detects urgent situations from audio monitoring.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {alerts.map((alert, index) => (
            <div key={index} className="bg-white border-l-4 border-red-500 rounded-lg shadow-sm overflow-hidden">
              <div className="p-6">
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-3">
                    <div className="bg-red-100 p-2 rounded-full">
                      <AlertTriangle className="h-6 w-6 text-red-600" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-2 mb-2">
                        <h3 className="text-lg font-semibold text-red-800">
                          Emergency Alert
                        </h3>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getConfidenceColor(alert.confidence)}`}>
                          {Math.round(alert.confidence * 100)}% confidence
                        </span>
                      </div>
                      
                      <div className="mb-3">
                        <p className="text-gray-700 font-medium mb-1">Detected Message:</p>
                        <p className="text-gray-600 text-sm bg-gray-50 p-3 rounded-md border-l-2 border-gray-200">
                          "{alert.message}"
                        </p>
                      </div>

                      <div className="flex items-center space-x-4 text-sm text-gray-500">
                        <div className="flex items-center space-x-1">
                          <Clock className="h-4 w-4" />
                          <span>{formatTime(alert.timestamp)}</span>
                        </div>
                        <span>•</span>
                        <span>Real-time alert triggered</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Emergency Response Actions */}
                <div className="mt-4 p-4 bg-red-50 rounded-md border border-red-200">
                  <h4 className="text-sm font-medium text-red-800 mb-2">Recommended Actions:</h4>
                  <ul className="text-xs text-red-700 space-y-1">
                    <li>• Verify the emergency situation immediately</li>
                    <li>• Contact emergency services if needed (911)</li>
                    <li>• Check on the person's safety and wellbeing</li>
                    <li>• Review the full audio recording for context</li>
                    <li>• Follow your emergency response protocol</li>
                  </ul>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Alert Statistics */}
      <div className="mt-8 bg-gray-50 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Alert Statistics</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="text-2xl font-bold text-gray-900">{alerts.length}</div>
            <p className="text-sm text-gray-500">Total Alerts Today</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="text-2xl font-bold text-red-600">
              {alerts.filter(a => a.confidence >= 0.8).length}
            </div>
            <p className="text-sm text-gray-500">High Confidence</p>
          </div>
          <div className="bg-white p-4 rounded-lg shadow-sm">
            <div className="text-2xl font-bold text-orange-600">
              {alerts.filter(a => a.confidence >= 0.6 && a.confidence < 0.8).length}
            </div>
            <p className="text-sm text-gray-500">Medium Confidence</p>
          </div>
        </div>
      </div>
    </div>
  );
}