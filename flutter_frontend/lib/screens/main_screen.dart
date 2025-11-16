import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/keyword_detection_provider.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'emergency/emergency_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EmergencyScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize WebSocket connection and keyword detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated && authProvider.user != null) {
        final wsProvider = context.read<WebSocketProvider>();
        wsProvider.connect(authProvider.user!.id);

        // Listen for emergency alerts from WebSocket
        wsProvider.addListener(_onWebSocketUpdate);
      }
      
      // Check and reconnect keyword detection if needed
      _checkAndReconnectKeywordDetection();
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();

    // Remove WebSocket listener to prevent memory leaks
    try {
      final wsProvider = context.read<WebSocketProvider>();
      wsProvider.removeListener(_onWebSocketUpdate);
    } catch (e) {
      // Ignore errors if context is no longer available
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground, check keyword detection connection
      _checkAndReconnectKeywordDetection();
    }
  }

  Future<void> _checkAndReconnectKeywordDetection() async {
    try {
      final keywordProvider = context.read<KeywordDetectionProvider>();
      
      // Check if the native service is running but Flutter side is not connected
      await keywordProvider.checkDetectionStatus();
      
      // If service is active but not listening through EventChannel, reconnect
      if (keywordProvider.isDetectionActive && !keywordProvider.isListening) {
        debugPrint('Detected service running but EventChannel disconnected. Reconnecting...');
        // This will re-establish the EventChannel connection
        await keywordProvider.checkDetectionStatus();
      }
    } catch (e) {
      debugPrint('Error checking keyword detection status: $e');
    }
  }

  void _onWebSocketUpdate() {
    final wsProvider = context.read<WebSocketProvider>();

    // Check for new emergency alerts and show dialog if needed
    if (wsProvider.emergencyAlerts.isNotEmpty) {
      final latestAlert = wsProvider.emergencyAlerts.last;
      final isEmergency = latestAlert['isEmergency'] ?? false;

      if (isEmergency && mounted) {
        // Show emergency dialog for WebSocket alerts
        final transcription =
            latestAlert['transcription'] ?? latestAlert['message'] ?? '';
        final confidenceValue = latestAlert['confidence'];
        final confidence =
            (confidenceValue is num) ? confidenceValue.toDouble() : 0.0;
        final emergencyType = latestAlert['emergencyType'] ?? 'unknown';

        _showWebSocketEmergencyAlert(transcription, confidence, emergencyType);
      }
    }
  }

  void _showWebSocketEmergencyAlert(
      String transcription, double confidence, String emergencyType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red, width: 3),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 30),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  ' EMERGENCY DETECTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detected Speech:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  '"$transcription"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency Type:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(emergencyType.toUpperCase(),
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Confidence:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This recording was processed in the background and emergency was detected.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<WebSocketProvider>().clearAlerts();
              },
              child: const Text(
                'Acknowledge',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WebSocketProvider>(
        builder: (context, wsProvider, child) {
          return Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: _screens,
              ),

              // Emergency Alert Overlay
              if (wsProvider.emergencyAlerts.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Emergency Detected!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                wsProvider.emergencyAlerts.last['message'] ??
                                    'Emergency alert',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            wsProvider.clearAlerts();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'Emergency',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
