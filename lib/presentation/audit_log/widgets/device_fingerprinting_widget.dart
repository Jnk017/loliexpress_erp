import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../services/forensic_analysis_service.dart';

class DeviceFingerprintingWidget extends StatefulWidget {
  const DeviceFingerprintingWidget({super.key});

  @override
  State<DeviceFingerprintingWidget> createState() =>
      _DeviceFingerprintingWidgetState();
}

class _DeviceFingerprintingWidgetState
    extends State<DeviceFingerprintingWidget> {
  final ForensicAnalysisService _forensicService = ForensicAnalysisService();
  List<DeviceFingerprint> _devices = [];
  bool _isLoading = true;
  bool _onlyMobile = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    try {
      final devices = await _forensicService.getDeviceFingerprints(
        onlyMobile: _onlyMobile,
      );

      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading devices: $e')),
        );
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
                  Icons.fingerprint,
                  color: Theme.of(context).primaryColor,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Fingerprinting',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Unique device identification',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Mobile filter toggle
                FilterChip(
                  label: Text(
                    'Mobile Only',
                    style: TextStyle(
                      color: _onlyMobile ? Colors.white : Colors.black87,
                      fontSize: 11.sp,
                    ),
                  ),
                  selected: _onlyMobile,
                  onSelected: (selected) {
                    setState(() => _onlyMobile = selected);
                    _loadDevices();
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).primaryColor,
                  checkmarkColor: Colors.white,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),

          // Device list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other_outlined,
                              size: 15.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No devices found',
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
                        itemCount: _devices.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 2.h,
                          color: Colors.grey[300],
                        ),
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return _buildDeviceCard(device);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceFingerprint device) {
    final isNewDevice = device.firstSeen
        .isAfter(DateTime.now().subtract(const Duration(days: 7)));

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isNewDevice ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isNewDevice ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Device icon
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: device.isMobile
                      ? Colors.blue.withAlpha(51)
                      : Colors.grey.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  device.isMobile ? Icons.phone_android : Icons.computer,
                  size: 6.w,
                  color: device.isMobile ? Colors.blue : Colors.grey[700],
                ),
              ),
              SizedBox(width: 3.w),

              // Device details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceDisplay,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      device.deviceType ?? 'Unknown Type',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // New device badge
              if (isNewDevice)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 2.h),

          // Usage statistics
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.event_repeat,
                  label: 'Sessions',
                  value: device.totalSessions.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: 'First Seen',
                  value: DateFormat('MMM dd').format(device.firstSeen),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.update,
                  label: 'Last Seen',
                  value: DateFormat('MMM dd').format(device.lastSeen),
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Fingerprint hash (technical detail)
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.fingerprint, size: 4.w, color: Colors.grey[600]),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    device.fingerprintHash,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'monospace',
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
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
}
