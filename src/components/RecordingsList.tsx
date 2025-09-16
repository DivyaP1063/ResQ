import React, { useState, useEffect } from 'react';
import { Clock, AlertTriangle, Play, Trash2, Download, Filter } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { recordingsAPI } from '../services/api';

interface Recording {
  _id: string;
  transcription: string;
  isEmergency: boolean;
  emergencyType: string | null;
  confidence: number;
  keywords: string[];
  createdAt: string;
  duration: number;
}

export default function RecordingsList() {
  const { token } = useAuth();
  const [recordings, setRecordings] = useState<Recording[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'emergencies'>('all');
  const [page, setPage] = useState(1);

  useEffect(() => {
    fetchRecordings();
  }, [filter, page]);

  const fetchRecordings = async () => {
    if (!token) return;

    try {
      setLoading(true);
      const response = filter === 'emergencies' 
        ? await recordingsAPI.getEmergencyRecordings(token)
        : await recordingsAPI.getRecordings(token, page);
      
      setRecordings(response.recordings);
    } catch (error) {
      console.error('Failed to fetch recordings:', error);
    } finally {
      setLoading(false);
    }
  };

  const deleteRecording = async (recordingId: string) => {
    if (!token || !confirm('Are you sure you want to delete this recording?')) return;

    try {
      await recordingsAPI.deleteRecording(token, recordingId);
      setRecordings(recordings.filter(r => r._id !== recordingId));
    } catch (error) {
      console.error('Failed to delete recording:', error);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const getEmergencyTypeColor = (type: string | null) => {
    switch (type) {
      case 'help':
        return 'bg-red-100 text-red-800';
      case 'medical':
        return 'bg-orange-100 text-orange-800';
      case 'fire':
        return 'bg-red-100 text-red-800';
      case 'police':
        return 'bg-blue-100 text-blue-800';
      case 'accident':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="p-8 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-500 mx-auto"></div>
        <p className="mt-4 text-gray-600">Loading recordings...</p>
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Audio Recordings</h2>
        
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <Filter className="h-4 w-4 text-gray-500" />
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as 'all' | 'emergencies')}
              className="rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
            >
              <option value="all">All Recordings</option>
              <option value="emergencies">Emergencies Only</option>
            </select>
          </div>
        </div>
      </div>

      {recordings.length === 0 ? (
        <div className="text-center py-12">
          <Clock className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No recordings found</h3>
          <p className="text-gray-500">
            {filter === 'emergencies' 
              ? 'No emergency recordings have been detected yet.'
              : 'Start monitoring to create audio recordings.'}
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {recordings.map((recording) => (
            <div key={recording._id} className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <div className="flex items-center space-x-2">
                      {recording.isEmergency && (
                        <AlertTriangle className="h-5 w-5 text-red-500" />
                      )}
                      <span className="text-sm font-medium text-gray-900">
                        {formatDate(recording.createdAt)}
                      </span>
                    </div>
                    
                    {recording.isEmergency && (
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getEmergencyTypeColor(recording.emergencyType)}`}>
                        {recording.emergencyType?.toUpperCase() || 'EMERGENCY'}
                      </span>
                    )}
                    
                    {recording.confidence > 0 && (
                      <span className="text-xs text-gray-500">
                        {Math.round(recording.confidence * 100)}% confidence
                      </span>
                    )}
                  </div>

                  {recording.transcription && (
                    <div className="mb-3">
                      <p className="text-gray-700 text-sm leading-relaxed">
                        "{recording.transcription}"
                      </p>
                    </div>
                  )}

                  {recording.keywords.length > 0 && (
                    <div className="mb-3">
                      <p className="text-xs text-gray-500 mb-1">Detected keywords:</p>
                      <div className="flex flex-wrap gap-1">
                        {recording.keywords.map((keyword, index) => (
                          <span key={index} className="px-2 py-1 bg-gray-100 text-gray-700 text-xs rounded">
                            {keyword}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                <div className="flex items-center space-x-2 ml-4">
                  <button
                    onClick={() => deleteRecording(recording._id)}
                    className="p-2 text-gray-400 hover:text-red-500 rounded-full hover:bg-red-50 transition-colors"
                    title="Delete recording"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {recording.isEmergency && (
                <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
                  <div className="flex items-center space-x-2">
                    <AlertTriangle className="h-4 w-4 text-red-600" />
                    <span className="text-sm font-medium text-red-800">
                      Emergency Detected
                    </span>
                  </div>
                  <p className="text-xs text-red-700 mt-1">
                    This recording was flagged as a potential emergency situation.
                    Real-time alerts were triggered for immediate response.
                  </p>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}