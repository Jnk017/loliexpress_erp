import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './add_task_dialog_widget.dart';
import './upload_evidence_dialog_widget.dart';

class QuickActionsFabWidget extends StatefulWidget {
  final String incidentId;
  final VoidCallback onActionComplete;

  const QuickActionsFabWidget({
    super.key,
    required this.incidentId,
    required this.onActionComplete,
  });

  @override
  State<QuickActionsFabWidget> createState() => _QuickActionsFabWidgetState();
}

class _QuickActionsFabWidgetState extends State<QuickActionsFabWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showAddTaskDialog() {
    _toggleExpanded();
    showDialog(
      context: context,
      builder: (context) => AddTaskDialogWidget(
        incidentId: widget.incidentId,
        onTaskAdded: widget.onActionComplete,
      ),
    );
  }

  void _showUploadEvidenceDialog() {
    _toggleExpanded();
    showDialog(
      context: context,
      builder: (context) => UploadEvidenceDialogWidget(
        incidentId: widget.incidentId,
        onEvidenceUploaded: widget.onActionComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleTransition(
          scale: _animation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.task_alt,
                label: 'Add Task',
                onPressed: _showAddTaskDialog,
              ),
              SizedBox(height: 2.h),
              _buildActionButton(
                icon: Icons.folder_special,
                label: 'Upload Evidence',
                onPressed: _showUploadEvidenceDialog,
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: Colors.blue[700],
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(77),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(width: 2.w),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: Colors.blue[700],
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}