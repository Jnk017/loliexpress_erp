import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TimeRangeSelectorWidget extends StatelessWidget {
  final String selectedRange;
  final Function(String) onRangeChanged;

  const TimeRangeSelectorWidget({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 20),
        SizedBox(width: 2.w),
        const Text('Time Range:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(width: 2.w),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedRange,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: '24h', child: Text('Last 24 Hours')),
              DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
              DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
              DropdownMenuItem(value: 'all', child: Text('All Time')),
            ],
            onChanged: (value) {
              if (value != null) onRangeChanged(value);
            },
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync, size: 16, color: Colors.green[700]),
              SizedBox(width: 1.w),
              Text(
                'Live',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
