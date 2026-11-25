import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuickActionFabWidget extends StatefulWidget {
  final VoidCallback onRecordExpense;
  final VoidCallback onCreateReceipt;
  final VoidCallback onGenerateReport;

  const QuickActionFabWidget({
    super.key,
    required this.onRecordExpense,
    required this.onCreateReceipt,
    required this.onGenerateReport,
  });

  @override
  State<QuickActionFabWidget> createState() => _QuickActionFabWidgetState();
}

class _QuickActionFabWidgetState extends State<QuickActionFabWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _buildActionButton(
            context: context,
            label: 'Enregistrer une dépense',
            icon: Icons.receipt,
            onPressed: () {
              _toggleExpanded();
              widget.onRecordExpense();
            },
            theme: theme,
          ),
          SizedBox(height: 2.h),
          _buildActionButton(
            context: context,
            label: 'Encaisser une facture',
            icon: Icons.description,
            onPressed: () {
              _toggleExpanded();
              widget.onCreateReceipt();
            },
            theme: theme,
          ),
          SizedBox(height: 2.h),
          _buildActionButton(
            context: context,
            label: 'Générer un rapport',
            icon: Icons.assessment,
            onPressed: () {
              _toggleExpanded();
              widget.onGenerateReport();
            },
            theme: theme,
          ),
          SizedBox(height: 2.h),
        ],
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: theme.colorScheme.primary,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: CustomIconWidget(
              iconName: _isExpanded ? 'close' : 'add',
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return FadeTransition(
      opacity: _expandAnimation,
      child: ScaleTransition(
        scale: _expandAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            FloatingActionButton.small(
              onPressed: onPressed,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: CustomIconWidget(
                iconName:
                    icon.toString().split('(')[1].split(')')[0].split('.')[1],
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
