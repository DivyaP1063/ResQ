import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/keyword_detection_provider.dart';

/// Settings screen for managing keyword detection preferences
class KeywordDetectionSettingsScreen extends StatefulWidget {
  const KeywordDetectionSettingsScreen({Key? key}) : super(key: key);

  @override
  State<KeywordDetectionSettingsScreen> createState() =>
      _KeywordDetectionSettingsScreenState();
}

class _KeywordDetectionSettingsScreenState
    extends State<KeywordDetectionSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Check current status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KeywordDetectionProvider>(context, listen: false)
          .checkDetectionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Detection Settings'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Consumer<KeywordDetectionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.red[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Always-On Protection',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ResQ can listen for emergency keywords even when your phone is locked or the app is closed.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main toggle section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Enable Keyword Detection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            provider.isDetectionActive
                                ? 'Listening for emergency keywords in background'
                                : 'Keyword detection is disabled',
                            style: TextStyle(
                              color: provider.isDetectionActive
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                            ),
                          ),
                          value: provider.isDetectionActive,
                          onChanged: (value) async {
                            _showConfirmationDialog(context, value);
                          },
                          activeColor: Colors.red[700],
                          secondary: Icon(
                            provider.isDetectionActive
                                ? Icons.mic
                                : Icons.mic_off,
                            color: provider.isDetectionActive
                                ? Colors.red[700]
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Status information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          'Detection Service',
                          provider.isDetectionActive ? 'Running' : 'Stopped',
                          provider.isDetectionActive
                              ? Colors.green
                              : Colors.red,
                          provider.isDetectionActive
                              ? Icons.play_circle
                              : Icons.stop_circle,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Event Listening',
                          provider.isListening ? 'Active' : 'Inactive',
                          provider.isListening ? Colors.green : Colors.orange,
                          provider.isListening
                              ? Icons.hearing
                              : Icons.hearing_disabled,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Keywords',
                          'Computer, Hey Google',
                          Colors.blue,
                          Icons.record_voice_over,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Keywords information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Keywords',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ResQ listens for these emergency trigger words:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wake Words (Available):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: ['alexa', 'computer', 'hey google']
                              .map((keyword) => Chip(
                                    label: Text(keyword),
                                    backgroundColor: Colors.green[50],
                                    labelStyle: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Emergency Words (Coming Soon):',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: ['help', 'emergency', 'save me', 'call 911']
                              .map((keyword) => Chip(
                                    label: Text(keyword),
                                    backgroundColor: Colors.orange[50],
                                    labelStyle: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Important notes
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Important Notes',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📱 CURRENT: Say "Alexa", "Computer", or "Hey Google" to trigger emergency recording\n\n'
                          '🚨 UPCOMING: Direct emergency words like "Help", "Emergency", "Save me" (requires custom keyword training)\n\n'
                          '• This feature runs in the background and may use battery\n'
                          '• Microphone permission is required\n'
                          '• Emergency recordings start automatically when keywords are detected\n'
                          '• Your emergency contacts will be notified\n'
                          '• Keep your phone charged for continuous protection\n'
                          '• Lower sensitivity = easier detection but more false positives',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[800],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(
      String label, String status, Color color, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context, bool enable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enable
            ? 'Enable Keyword Detection?'
            : 'Disable Keyword Detection?'),
        content: Text(
          enable
              ? 'This will start monitoring for emergency keywords in the background. '
                  'Make sure you have microphone permission granted.'
              : 'This will stop background monitoring for emergency keywords. '
                  'You won\'t receive automatic emergency detection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _toggleDetection(enable);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: enable ? Colors.red[700] : Colors.grey[700],
              foregroundColor: Colors.white,
            ),
            child: Text(enable ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDetection(bool enable) async {
    final provider =
        Provider.of<KeywordDetectionProvider>(context, listen: false);

    try {
      bool success;
      if (enable) {
        success = await provider.startDetection();
      } else {
        success = await provider.stopDetection();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enable
                    ? 'Keyword detection enabled successfully'
                    : 'Keyword detection disabled successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enable
                    ? 'Failed to enable keyword detection'
                    : 'Failed to disable keyword detection',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
