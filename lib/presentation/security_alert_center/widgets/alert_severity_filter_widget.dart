import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlertSeverityFilterWidget extends StatelessWidget {
  final String selectedSeverity;
  final Function(String) onSeverityChanged;

  const AlertSeverityFilterWidget({
    super.key,
    required this.selectedSeverity,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildFilterChip('All', 'all', Colors.grey)),
        SizedBox(width: 2.w),
        Expanded(child: _buildFilterChip('Critical', 'critical', Colors.red)),
        SizedBox(width: 2.w),
        Expanded(child: _buildFilterChip('High', 'high', Colors.orange)),
        SizedBox(width: 2.w),
        Expanded(
            child: _buildFilterChip('Medium', 'medium', Colors.yellow[700]!)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = selectedSeverity == value;
    return GestureDetector(
      onTap: () => onSeverityChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }
}
