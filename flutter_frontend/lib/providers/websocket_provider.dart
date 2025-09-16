import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  
  bool _isConnected = false;
  List<Map<String, dynamic>> _emergencyAlerts = [];

  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get emergencyAlerts => _emergencyAlerts;

  WebSocketProvider() {
    _webSocketService.onConnectionChanged = (connected) {
      _isConnected = connected;
      notifyListeners();
    };

    _webSocketService.onEmergencyAlert = (alert) {
      _emergencyAlerts.add(alert);
      notifyListeners();
    };
  }

  void connect(String userId) {
    _webSocketService.connect(userId);
  }

  void disconnect() {
    _webSocketService.disconnect();
  }

  void sendEmergencyAlert(String message, double confidence) {
    _webSocketService.sendEmergencyAlert(message, confidence);
  }

  void clearAlerts() {
    _emergencyAlerts.clear();
    notifyListeners();
  }

  void removeAlert(int index) {
    if (index < _emergencyAlerts.length) {
      _emergencyAlerts.removeAt(index);
      notifyListeners();
    }
  }
}