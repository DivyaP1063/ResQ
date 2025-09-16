import React, { useState } from 'react';
import Header from './Header';
import AudioRecorder from './AudioRecorder';
import RecordingsList from './RecordingsList';
import EmergencyAlerts from './EmergencyAlerts';
import Profile from './Profile';
import { Mic, List, AlertTriangle, User } from 'lucide-react';

type TabType = 'recorder' | 'recordings' | 'alerts' | 'profile';

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState<TabType>('recorder');

  const tabs = [
    { id: 'recorder' as TabType, label: 'Monitor', icon: Mic, color: 'text-blue-600' },
    { id: 'recordings' as TabType, label: 'Recordings', icon: List, color: 'text-gray-600' },
    { id: 'alerts' as TabType, label: 'Alerts', icon: AlertTriangle, color: 'text-red-600' },
    { id: 'profile' as TabType, label: 'Profile', icon: User, color: 'text-purple-600' },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'recorder':
        return <AudioRecorder />;
      case 'recordings':
        return <RecordingsList />;
      case 'alerts':
        return <EmergencyAlerts />;
      case 'profile':
        return <Profile />;
      default:
        return <AudioRecorder />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Navigation Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-8">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8" aria-label="Tabs">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`${
                      activeTab === tab.id
                        ? 'border-red-500 text-red-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    } whitespace-nowrap py-4 px-6 border-b-2 font-medium text-sm flex items-center space-x-2`}
                  >
                    <Icon className="h-5 w-5" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Tab Content */}
        <div className="bg-white rounded-lg shadow-sm">
          {renderContent()}
        </div>
      </div>
    </div>
  );
}