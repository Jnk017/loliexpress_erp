import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';

class AssignInvestigatorDialogWidget extends StatefulWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onAssigned;

  const AssignInvestigatorDialogWidget({
    super.key,
    required this.incident,
    required this.onAssigned,
  });

  @override
  State<AssignInvestigatorDialogWidget> createState() =>
      _AssignInvestigatorDialogWidgetState();
}

class _AssignInvestigatorDialogWidgetState
    extends State<AssignInvestigatorDialogWidget> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _investigators = [];
  String? _selectedInvestigatorId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInvestigators();
  }

  Future<void> _loadInvestigators() async {
    try {
      final response = await _supabaseService.client
          .from('user_profiles')
          .select('id, full_name, email, role')
          .eq('is_active', true)
          .inFilter('role', ['admin', 'commercial_staff']);

      if (!mounted) return;
      setState(() {
        _investigators = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load investigators: $e')),
      );
    }
  }

  Future<void> _assignInvestigator() async {
    if (_selectedInvestigatorId == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Create forensic investigation report
      await _supabaseService.client
          .from('forensic_investigation_reports')
          .insert({
        'user_id': widget.incident['user_id'],
        'investigator_id': _selectedInvestigatorId,
        'report_title':
            'Investigation: ${widget.incident['title'] ?? 'Unknown Incident'}',
        'report_type': 'security_incident',
        'status': 'draft',
        'severity': widget.incident['severity'],
        'time_range_start': widget.incident['detected_at'],
        'time_range_end': DateTime.now().toIso8601String(),
        'evidence_anomalies': [widget.incident['id']],
      });

      widget.onAssigned();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investigator assigned successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign investigator: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 60.h, maxWidth: 90.w),
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
                  const Icon(Icons.assignment_ind, color: Colors.white),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Assign Investigator',
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _investigators.isEmpty
                      ? Center(
                          child: Text(
                            'No investigators available',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(2.w),
                          itemCount: _investigators.length,
                          itemBuilder: (context, index) {
                            final investigator = _investigators[index];
                            final isSelected =
                                _selectedInvestigatorId == investigator['id'];

                            return Card(
                              margin: EdgeInsets.only(bottom: 1.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade700,
                                  child: Text(
                                    investigator['full_name']
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  investigator['full_name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  investigator['email'] ?? '',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: Colors.blue.shade700)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedInvestigatorId =
                                        investigator['id'];
                                  });
                                },
                              ),
                            );
                          },
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
                      onPressed:
                          _isSubmitting || _selectedInvestigatorId == null
                              ? null
                              : _assignInvestigator,
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
                          : const Text('Assign'),
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
