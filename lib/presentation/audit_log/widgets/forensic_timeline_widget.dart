import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../services/forensic_analysis_service.dart';

class ForensicTimelineWidget extends StatefulWidget {
  final String userId;
  final DateTime startTime;
  final DateTime endTime;

  const ForensicTimelineWidget({
    super.key,
    required this.userId,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<ForensicTimelineWidget> createState() => _ForensicTimelineWidgetState();
}

class _ForensicTimelineWidgetState extends State<ForensicTimelineWidget> {
  final ForensicAnalysisService _forensicService = ForensicAnalysisService();
  List<ForensicTimelineEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);

    try {
      final events = await _forensicService.getForensicTimeline(
        userId: widget.userId,
        startTime: widget.startTime,
        endTime: widget.endTime,
      );

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de terminer l’opération. Réessayez.')),
        );
      }
    }
  }

  Color _getEventColor(ForensicTimelineEvent event) {
    if (event.riskIndicator) {
      return Colors.red;
    } else if (event.threatLevel == 'high') {
      return Colors.orange;
    } else if (event.isProxyOrVpn) {
      return Colors.amber;
    }
    return Colors.blue;
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'insert':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.event;
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
                  Icons.timeline,
                  color: Theme.of(context).primaryColor,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forensic Timeline',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Detailed event reconstruction',
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
          Divider(height: 1, color: Colors.grey[300]),

          // Timeline content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timeline_outlined,
                              size: 15.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No timeline events found',
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
                        itemCount: _events.length,
                        separatorBuilder: (context, index) => Container(
                          margin: EdgeInsets.only(left: 8.w),
                          height: 3.h,
                          width: 0.5.w,
                          color: Colors.grey[300],
                        ),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return _buildTimelineItem(event);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ForensicTimelineEvent event) {
    final color = _getEventColor(event);
    final icon = _getEventIcon(event.eventType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.0),
          ),
          child: Icon(icon, size: 4.w, color: color),
        ),
        SizedBox(width: 3.w),

        // Event details
        Expanded(
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: event.riskIndicator
                    ? Colors.red.shade200
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp and risk indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, yyyy HH:mm:ss')
                            .format(event.eventTimestamp),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    if (event.riskIndicator)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'RISK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),

                // Event description
                Text(
                  event.eventDescription,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),

                // Location and device info
                Row(
                  children: [
                    // Location
                    if (event.locationInfo != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 4.w, color: Colors.grey[600]),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                event.locationDisplay,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Device
                    if (event.deviceInfo != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              event.isMobile
                                  ? Icons.phone_android
                                  : Icons.computer,
                              size: 4.w,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                '${event.browserName} on ${event.osName}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Threat indicators
                if (event.isProxyOrVpn || event.threatLevel != 'low')
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Wrap(
                      spacing: 2.w,
                      children: [
                        if (event.isProxyOrVpn)
                          Chip(
                            label: Text('Proxy/VPN',
                                style: TextStyle(
                                    fontSize: 9.sp, color: Colors.white)),
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (event.threatLevel == 'high')
                          Chip(
                            label: Text('High Threat',
                                style: TextStyle(
                                    fontSize: 9.sp, color: Colors.white)),
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ),

                // IP Address
                if (event.ipAddress != null)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text(
                      'IP: ${event.ipAddress}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontFamily: 'monospace',
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
