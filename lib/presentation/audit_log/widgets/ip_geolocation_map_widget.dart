import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/forensic_analysis_service.dart';

class IpGeolocationMapWidget extends StatefulWidget {
  const IpGeolocationMapWidget({super.key});

  @override
  State<IpGeolocationMapWidget> createState() => _IpGeolocationMapWidgetState();
}

class _IpGeolocationMapWidgetState extends State<IpGeolocationMapWidget> {
  final ForensicAnalysisService _forensicService = ForensicAnalysisService();
  List<IpGeolocationData> _geolocations = [];
  bool _isLoading = true;
  String _selectedThreatFilter = 'all';

  final List<Map<String, dynamic>> _threatFilters = [
    {'value': 'all', 'label': 'All Locations', 'color': Colors.grey},
    {'value': 'high', 'label': 'High Threat', 'color': Colors.red},
    {'value': 'medium', 'label': 'Medium Threat', 'color': Colors.orange},
    {'value': 'low', 'label': 'Low Threat', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadGeolocations();
  }

  Future<void> _loadGeolocations() async {
    setState(() => _isLoading = true);

    try {
      final geolocations = await _forensicService.getIpGeolocations(
        threatLevel: _selectedThreatFilter,
      );

      setState(() {
        _geolocations = geolocations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading geolocations: $e')),
        );
      }
    }
  }

  Color _getThreatColor(String threatLevel) {
    switch (threatLevel) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
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
                  Icons.map_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP Geolocation Mapping',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Access location analysis',
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

          // Threat level filter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _threatFilters.map((filter) {
                  final isSelected = _selectedThreatFilter == filter['value'];
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
                            _selectedThreatFilter = filter['value'] as String);
                        _loadGeolocations();
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

          // Map placeholder and location list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _geolocations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 15.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No geolocation data found',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Map placeholder
                          Container(
                            height: 30.h,
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Stack(
                              children: [
                                // Map visualization placeholder
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.public,
                                        size: 12.w,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        'Interactive Map View',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${_geolocations.where((g) => g.hasCoordinates).length} locations tracked',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Threat level indicators on map
                                ..._geolocations
                                    .where((g) => g.hasCoordinates)
                                    .take(5)
                                    .map((geo) {
                                  return Positioned(
                                    left: 20.w +
                                        (_geolocations.indexOf(geo) * 10.w),
                                    top: 10.h +
                                        (_geolocations.indexOf(geo) * 5.h),
                                    child: Container(
                                      width: 3.w,
                                      height: 3.w,
                                      decoration: BoxDecoration(
                                        color: _getThreatColor(geo.threatLevel),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                _getThreatColor(geo.threatLevel)
                                                    .withAlpha(128),
                                            blurRadius: 8.0,
                                            spreadRadius: 2.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          SizedBox(height: 2.h),

                          // Location list
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              itemCount: _geolocations.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 2.h,
                                color: Colors.grey[300],
                              ),
                              itemBuilder: (context, index) {
                                final geo = _geolocations[index];
                                return _buildLocationItem(geo);
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(IpGeolocationData geo) {
    final threatColor = _getThreatColor(geo.threatLevel);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: threatColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          // Threat indicator
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: threatColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 3.w),

          // Location details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  geo.locationDisplay,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  geo.ipAddress,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: 'monospace',
                    color: Colors.grey[600],
                  ),
                ),
                if (geo.isp != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      'ISP: ${geo.isp}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Indicators
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Threat level badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: threatColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  geo.threatLevel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Proxy/VPN indicator
              if (geo.isProxy || geo.isVpn)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Chip(
                    label: Text(
                      geo.isProxy ? 'PROXY' : 'VPN',
                      style: TextStyle(fontSize: 9.sp, color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
