import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IncidentFiltersWidget extends StatefulWidget {
  final String? selectedSeverity;
  final String? selectedStatus;
  final String? selectedCategory;
  final List<String> severityOptions;
  final List<String> statusOptions;
  final List<String> categoryOptions;
  final Function(String?, String?, String?) onFiltersApplied;

  const IncidentFiltersWidget({
    super.key,
    this.selectedSeverity,
    this.selectedStatus,
    this.selectedCategory,
    required this.severityOptions,
    required this.statusOptions,
    required this.categoryOptions,
    required this.onFiltersApplied,
  });

  @override
  State<IncidentFiltersWidget> createState() => _IncidentFiltersWidgetState();
}

class _IncidentFiltersWidgetState extends State<IncidentFiltersWidget> {
  String? _tempSeverity;
  String? _tempStatus;
  String? _tempCategory;

  @override
  void initState() {
    super.initState();
    _tempSeverity = widget.selectedSeverity;
    _tempStatus = widget.selectedStatus;
    _tempCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Incidents',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempSeverity = null;
                    _tempStatus = null;
                    _tempCategory = null;
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Severity Filter
          Text(
            'Severity',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: widget.severityOptions.map((severity) {
              final isSelected = _tempSeverity == severity;
              return FilterChip(
                label: Text(severity.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempSeverity = selected ? severity : null;
                  });
                },
                selectedColor: _getSeverityColor(severity),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),

          // Status Filter
          Text(
            'Status',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: widget.statusOptions.map((status) {
              final isSelected = _tempStatus == status;
              return FilterChip(
                label: Text(status.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempStatus = selected ? status : null;
                  });
                },
                selectedColor: Colors.blue.shade600,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),

          // Category Filter
          Text(
            'Category',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: widget.categoryOptions.map((category) {
              final isSelected = _tempCategory == category;
              return FilterChip(
                label: Text(category.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempCategory = selected ? category : null;
                  });
                },
                selectedColor: Colors.purple.shade600,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 3.h),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersApplied(
                  _tempSeverity,
                  _tempStatus,
                  _tempCategory,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }
}
