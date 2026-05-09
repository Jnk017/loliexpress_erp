import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';

class CreateIncidentDialogWidget extends StatefulWidget {
  final VoidCallback onIncidentCreated;

  const CreateIncidentDialogWidget({
    super.key,
    required this.onIncidentCreated,
  });

  @override
  State<CreateIncidentDialogWidget> createState() =>
      _CreateIncidentDialogWidgetState();
}

class _CreateIncidentDialogWidgetState
    extends State<CreateIncidentDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;

  String _selectedSeverity = 'medium';
  String _selectedCategory = 'system';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = _supabaseService.client.auth.currentUser?.id;

      await _supabaseService.client.from('security_anomalies').insert({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'severity': _selectedSeverity,
        'category': _selectedCategory,
        'alert_status': 'pending',
        'user_id': userId,
        'detected_at': DateTime.now().toIso8601String(),
        'risk_score': _getRiskScoreForSeverity(_selectedSeverity),
      });

      widget.onIncidentCreated();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create incident: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  int _getRiskScoreForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 90;
      case 'high':
        return 70;
      case 'medium':
        return 50;
      case 'low':
        return 30;
      default:
        return 50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 75.h, maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Create Manual Incident Report',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Incident Title',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter incident title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe the incident in detail...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),

                      // Severity
                      Text(
                        'Severity',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      DropdownButtonFormField<String>(
                        value: _selectedSeverity,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'critical', child: Text('Critical')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(
                              value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSeverity = value!);
                        },
                      ),
                      SizedBox(height: 2.h),

                      // Category
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'transaction', child: Text('Transaction')),
                          DropdownMenuItem(
                              value: 'access', child: Text('Access')),
                          DropdownMenuItem(
                              value: 'inventory', child: Text('Inventory')),
                          DropdownMenuItem(
                              value: 'permission', child: Text('Permission')),
                          DropdownMenuItem(
                              value: 'system', child: Text('System')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitIncident,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 2.h,
                              width: 2.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}