import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlertAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AlertAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class AlertActionButtons extends StatelessWidget {
  final List<AlertAction> actions;
  final Alignment alignment;

  const AlertActionButtons({
    super.key,
    required this.actions,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: actions.map((action) => _buildActionButton(action)).toList(),
      ),
    );
  }

  Widget _buildActionButton(AlertAction action) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w),
      child: GestureDetector(
        onTap: action.onTap,
        child: Container(
          width: 15.w,
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: action.color,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: Colors.white, size: 24),
              SizedBox(height: 0.5.h),
              Text(
                action.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
