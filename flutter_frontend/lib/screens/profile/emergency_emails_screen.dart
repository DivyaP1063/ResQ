import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class EmergencyEmailsScreen extends StatefulWidget {
  const EmergencyEmailsScreen({super.key});

  @override
  State<EmergencyEmailsScreen> createState() => _EmergencyEmailsScreenState();
}

class _EmergencyEmailsScreenState extends State<EmergencyEmailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email1Controller = TextEditingController();
  final _email2Controller = TextEditingController();
  final _email3Controller = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyEmails();
  }

  @override
  void dispose() {
    _email1Controller.dispose();
    _email2Controller.dispose();
    _email3Controller.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyEmails() async {
    setState(() => _isLoading = true);

    try {
      final emails = await _apiService.getEmergencyEmails();
      if (emails.length >= 3) {
        _email1Controller.text = emails[0];
        _email2Controller.text = emails[1];
        _email3Controller.text = emails[2];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load emergency emails: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEmergencyEmails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final emails = [
        _email1Controller.text.trim(),
        _email2Controller.text.trim(),
        _email3Controller.text.trim(),
      ];

      await _apiService.updateEmergencyEmails(emails);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency emails updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update emergency emails: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Contact Emails',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Emergency Notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'These email addresses will receive immediate notifications when an emergency is detected in your audio recordings.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Fields
                    _buildEmailField(
                      controller: _email1Controller,
                      label: 'Emergency Email 1',
                      hint: 'family@example.com',
                    ),

                    const SizedBox(height: 16),

                    _buildEmailField(
                      controller: _email2Controller,
                      label: 'Emergency Email 2',
                      hint: 'friend@example.com',
                    ),

                    const SizedBox(height: 16),

                    _buildEmailField(
                      controller: _email3Controller,
                      label: 'Emergency Email 3',
                      hint: 'emergency@example.com',
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEmergencyEmails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Emergency Emails',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Test Button
                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              // TODO: Add test email functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Test email feature coming soon!'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Send Test Email'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmailField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hint,
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }
}
