import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../services/forensic_analysis_service.dart';

class AnomalyCorrelationWidget extends StatefulWidget {
  final String? userId;

  const AnomalyCorrelationWidget({
    super.key,
    this.userId,
  });

  @override
  State<AnomalyCorrelationWidget> createState() =>
      _AnomalyCorrelationWidgetState();
}

class _AnomalyCorrelationWidgetState extends State<AnomalyCorrelationWidget> {
  final ForensicAnalysisService _forensicService = ForensicAnalysisService();
  List<AnomalyCorrelationPattern> _patterns = [];
  bool _isLoading = true;
  String _selectedRiskFilter = 'all';

  final List<Map<String, dynamic>> _riskFilters = [
    {'value': 'all', 'label': 'All Patterns', 'color': Colors.grey},
    {'value': 'critical', 'label': 'Critical', 'color': Colors.red},
    {'value': 'high', 'label': 'High', 'color': Colors.orange},
    {'value': 'medium', 'label': 'Medium', 'color': Colors.amber},
    {'value': 'low', 'label': 'Low', 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    setState(() => _isLoading = true);

    try {
      final patterns = await _forensicService.getCorrelationPatterns(
        userId: widget.userId,
        riskLevel: _selectedRiskFilter == 'all' ? null : _selectedRiskFilter,
      );

      setState(() {
        _patterns = patterns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patterns: $e')),
        );
      }
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.check_circle_outline;
      case 'investigating':
        return Icons.search;
      case 'false_positive':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined;
    }
  }

  Future<void> _updateStatus(AnomalyCorrelationPattern pattern) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Investigation Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'pending',
            'investigating',
            'resolved',
            'false_positive',
          ].map((status) {
            return ListTile(
              title: Text(status.toUpperCase()),
              leading: Icon(_getStatusIcon(status)),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null) {
      try {
        await _forensicService.updateInvestigationStatus(
          patternId: pattern.id,
          status: newStatus,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully')),
          );
          _loadPatterns();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(
                  Icons.hub_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anomaly Correlation Patterns',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pattern detection and scoring',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Risk level filter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _riskFilters.map((filter) {
                  final isSelected = _selectedRiskFilter == filter['value'];
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: FilterChip(
                      label: Text(
                        filter['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 11.sp,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() =>
                            _selectedRiskFilter = filter['value'] as String);
                        _loadPatterns();
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: filter['color'] as Color,
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Divider(height: 3.h, color: Colors.grey[300]),

          // Patterns list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patterns.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bubble_chart_outlined,
                              size: 15.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No correlation patterns found',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _patterns.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 2.h),
                        itemBuilder: (context, index) {
                          final pattern = _patterns[index];
                          return _buildPatternCard(pattern);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(AnomalyCorrelationPattern pattern) {
    final riskColor = _getRiskColor(pattern.riskLevel);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: riskColor.withAlpha(77), width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Risk indicator
              Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: riskColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 3.w),

              // Pattern name
              Expanded(
                child: Text(
                  pattern.patternName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Risk level badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  pattern.riskLevel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Description
          if (pattern.patternDescription != null)
            Text(
              pattern.patternDescription!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[700],
              ),
            ),

          SizedBox(height: 2.h),

          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.score,
                  label: 'Score',
                  value: pattern.correlationScore.toStringAsFixed(1),
                  color: riskColor,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  icon: Icons.event,
                  label: 'Events',
                  value: pattern.eventCount.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  icon: Icons.timelapse,
                  label: 'Span',
                  value: _formatTimeSpan(pattern.timeSpan),
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Status and actions
          Row(
            children: [
              Icon(
                _getStatusIcon(pattern.investigationStatus),
                size: 4.w,
                color: Colors.grey[600],
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  pattern.investigationStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _updateStatus(pattern),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
              ),
            ],
          ),

          // Detection timestamp
          SizedBox(height: 1.h),
          Text(
            'Detected: ${DateFormat('MMM dd, yyyy HH:mm').format(pattern.detectedAt)}',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 5.w, color: color),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatTimeSpan(Duration duration) {
    if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inDays}d';
    }
  }
}
