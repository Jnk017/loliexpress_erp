import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/investigation_workspace_service.dart';
import '../../../services/supabase_service.dart';

class UploadEvidenceDialogWidget extends StatefulWidget {
  final String incidentId;
  final VoidCallback onEvidenceUploaded;

  const UploadEvidenceDialogWidget({
    super.key,
    required this.incidentId,
    required this.onEvidenceUploaded,
  });

  @override
  State<UploadEvidenceDialogWidget> createState() =>
      _UploadEvidenceDialogWidgetState();
}

class _UploadEvidenceDialogWidgetState
    extends State<UploadEvidenceDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workspaceService = InvestigationWorkspaceService();

  String _selectedCategory = 'log';
  bool _isCritical = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitEvidence() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = SupabaseService.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _workspaceService.addEvidence(
        incidentId: widget.incidentId,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        isCritical: _isCritical,
        collectedBy: currentUserId,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onEvidenceUploaded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evidence added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de terminer l’opération. Réessayez.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Evidence'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Evidence Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Evidence title is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'log', child: Text('Log')),
                  DropdownMenuItem(
                      value: 'screenshot', child: Text('Screenshot')),
                  DropdownMenuItem(value: 'document', child: Text('Document')),
                  DropdownMenuItem(
                      value: 'network_capture', child: Text('Network Capture')),
                  DropdownMenuItem(
                      value: 'forensic_artifact',
                      child: Text('Forensic Artifact')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'log';
                  });
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              CheckboxListTile(
                title: const Text('Mark as Critical Evidence'),
                subtitle:
                    const Text('Critical evidence requires special handling'),
                value: _isCritical,
                onChanged: (value) {
                  setState(() {
                    _isCritical = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitEvidence,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }
}
