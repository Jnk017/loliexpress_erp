import 'package:supabase_flutter/supabase_flutter.dart';

// Forensic Timeline Event Model
class ForensicTimelineEvent {
  final String eventId;
  final DateTime eventTimestamp;
  final String eventType;
  final String eventCategory;
  final String eventDescription;
  final String? ipAddress;
  final Map<String, dynamic>? deviceInfo;
  final Map<String, dynamic>? locationInfo;
  final bool riskIndicator;

  ForensicTimelineEvent({
    required this.eventId,
    required this.eventTimestamp,
    required this.eventType,
    required this.eventCategory,
    required this.eventDescription,
    this.ipAddress,
    this.deviceInfo,
    this.locationInfo,
    required this.riskIndicator,
  });

  factory ForensicTimelineEvent.fromJson(Map<String, dynamic> json) {
    return ForensicTimelineEvent(
      eventId: json['event_id'] as String,
      eventTimestamp: DateTime.parse(json['event_timestamp'] as String),
      eventType: json['event_type'] as String,
      eventCategory: json['event_category'] as String,
      eventDescription: json['event_description'] as String,
      ipAddress: json['ip_address'] as String?,
      deviceInfo: json['device_info'] as Map<String, dynamic>?,
      locationInfo: json['location_info'] as Map<String, dynamic>?,
      riskIndicator: json['risk_indicator'] as bool,
    );
  }

  String get locationDisplay {
    if (locationInfo == null) return 'Unknown Location';
    final city = locationInfo!['city'] as String?;
    final country = locationInfo!['country'] as String?;
    return city != null && country != null
        ? '$city, $country'
        : country ?? 'Unknown';
  }

  String get threatLevel {
    return locationInfo?['threat_level'] as String? ?? 'low';
  }

  bool get isProxyOrVpn {
    return locationInfo?['is_proxy'] as bool? ?? false;
  }

  String get browserName {
    return deviceInfo?['browser_name'] as String? ?? 'Unknown';
  }

  String get osName {
    return deviceInfo?['os_name'] as String? ?? 'Unknown';
  }

  bool get isMobile {
    return deviceInfo?['is_mobile'] as bool? ?? false;
  }
}

// IP Geolocation Model
class IpGeolocationData {
  final String ipAddress;
  final String? countryName;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String? isp;
  final bool isProxy;
  final bool isVpn;
  final String threatLevel;

  IpGeolocationData({
    required this.ipAddress,
    this.countryName,
    this.city,
    this.latitude,
    this.longitude,
    this.timezone,
    this.isp,
    required this.isProxy,
    required this.isVpn,
    required this.threatLevel,
  });

  factory IpGeolocationData.fromJson(Map<String, dynamic> json) {
    return IpGeolocationData(
      ipAddress: json['ip_address'] as String,
      countryName: json['country_name'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      timezone: json['timezone'] as String?,
      isp: json['isp'] as String?,
      isProxy: json['is_proxy'] as bool? ?? false,
      isVpn: json['is_vpn'] as bool? ?? false,
      threatLevel: json['threat_level'] as String? ?? 'low',
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  String get locationDisplay {
    if (city != null && countryName != null) {
      return '$city, $countryName';
    } else if (countryName != null) {
      return countryName!;
    }
    return 'Unknown Location';
  }
}

// Anomaly Correlation Pattern Model
class AnomalyCorrelationPattern {
  final String id;
  final String patternName;
  final String patternType;
  final List<String> anomalyIds;
  final String userId;
  final double correlationScore;
  final String riskLevel;
  final String? patternDescription;
  final DateTime detectedAt;
  final DateTime startTime;
  final DateTime endTime;
  final int eventCount;
  final int? uniqueIps;
  final int? uniqueDevices;
  final String investigationStatus;

  AnomalyCorrelationPattern({
    required this.id,
    required this.patternName,
    required this.patternType,
    required this.anomalyIds,
    required this.userId,
    required this.correlationScore,
    required this.riskLevel,
    this.patternDescription,
    required this.detectedAt,
    required this.startTime,
    required this.endTime,
    required this.eventCount,
    this.uniqueIps,
    this.uniqueDevices,
    required this.investigationStatus,
  });

  factory AnomalyCorrelationPattern.fromJson(Map<String, dynamic> json) {
    return AnomalyCorrelationPattern(
      id: json['id'] as String,
      patternName: json['pattern_name'] as String,
      patternType: json['pattern_type'] as String,
      anomalyIds: (json['anomaly_ids'] as List).cast<String>(),
      userId: json['user_id'] as String,
      correlationScore: (json['correlation_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      patternDescription: json['pattern_description'] as String?,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      eventCount: json['event_count'] as int,
      uniqueIps: json['unique_ips'] as int?,
      uniqueDevices: json['unique_devices'] as int?,
      investigationStatus: json['investigation_status'] as String,
    );
  }

  Duration get timeSpan => endTime.difference(startTime);
}

// Device Fingerprint Model
class DeviceFingerprint {
  final String id;
  final String fingerprintHash;
  final String userAgent;
  final String? deviceType;
  final String? browserName;
  final String? osName;
  final bool isMobile;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int totalSessions;

  DeviceFingerprint({
    required this.id,
    required this.fingerprintHash,
    required this.userAgent,
    this.deviceType,
    this.browserName,
    this.osName,
    required this.isMobile,
    required this.firstSeen,
    required this.lastSeen,
    required this.totalSessions,
  });

  factory DeviceFingerprint.fromJson(Map<String, dynamic> json) {
    return DeviceFingerprint(
      id: json['id'] as String,
      fingerprintHash: json['fingerprint_hash'] as String,
      userAgent: json['user_agent'] as String,
      deviceType: json['device_type'] as String?,
      browserName: json['browser_name'] as String?,
      osName: json['os_name'] as String?,
      isMobile: json['is_mobile'] as bool? ?? false,
      firstSeen: DateTime.parse(json['first_seen'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      totalSessions: json['total_sessions'] as int? ?? 1,
    );
  }

  String get deviceDisplay {
    if (browserName != null && osName != null) {
      return '$browserName on $osName';
    } else if (browserName != null) {
      return browserName!;
    } else if (osName != null) {
      return osName!;
    }
    return deviceType ?? 'Unknown Device';
  }
}

class ForensicAnalysisService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get forensic timeline for a user
  Future<List<ForensicTimelineEvent>> getForensicTimeline({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _supabase.rpc(
        'build_forensic_timeline',
        params: {
          'user_id_input': userId,
          'start_time_input': startTime.toIso8601String(),
          'end_time_input': endTime.toIso8601String(),
        },
      );

      return (response as List)
          .map((json) =>
              ForensicTimelineEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load forensic timeline: $e');
    }
  }

  // Get IP geolocation data
  Future<List<IpGeolocationData>> getIpGeolocations({
    int limit = 50,
    String? threatLevel,
  }) async {
    try {
      var query = _supabase.from('ip_geolocation_cache').select();

      if (threatLevel != null && threatLevel != 'all') {
        query = query.eq('threat_level', threatLevel);
      }

      final response =
          await query.order('last_updated', ascending: false).limit(limit);

      return (response as List)
          .map((json) =>
              IpGeolocationData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load IP geolocations: $e');
    }
  }

  // Detect anomaly correlation patterns
  Future<List<AnomalyCorrelationPattern>> detectCorrelationPatterns({
    required String userId,
    int timeWindowHours = 24,
  }) async {
    try {
      final response = await _supabase.rpc(
        'detect_correlation_patterns',
        params: {
          'user_id_input': userId,
          'time_window_hours': timeWindowHours,
        },
      );

      return (response as List)
          .map((json) => AnomalyCorrelationPattern.fromJson({
                'id': json['pattern_id'],
                'pattern_name': json['pattern_type'],
                'pattern_type': json['pattern_type'],
                'anomaly_ids': json['correlated_anomalies'],
                'user_id': userId,
                'correlation_score': json['correlation_score'],
                'risk_level': json['risk_level'],
                'pattern_description': json['description'],
                'detected_at': DateTime.now().toIso8601String(),
                'start_time': DateTime.now()
                    .subtract(Duration(hours: timeWindowHours))
                    .toIso8601String(),
                'end_time': DateTime.now().toIso8601String(),
                'event_count': (json['correlated_anomalies'] as List).length,
                'investigation_status': 'pending',
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to detect correlation patterns: $e');
    }
  }

  // Get stored correlation patterns
  Future<List<AnomalyCorrelationPattern>> getCorrelationPatterns({
    String? userId,
    String? riskLevel,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('anomaly_correlation_patterns').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (riskLevel != null && riskLevel != 'all') {
        query = query.eq('risk_level', riskLevel);
      }

      final response =
          await query.order('detected_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) =>
              AnomalyCorrelationPattern.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load correlation patterns: $e');
    }
  }

  // Get device fingerprints for a user (by looking at forensic timeline)
  Future<List<DeviceFingerprint>> getDeviceFingerprints({
    int limit = 50,
    bool onlyMobile = false,
  }) async {
    try {
      var query = _supabase.from('device_fingerprints').select();

      if (onlyMobile) {
        query = query.eq('is_mobile', true);
      }

      final response =
          await query.order('last_seen', ascending: false).limit(limit);

      return (response as List)
          .map((json) =>
              DeviceFingerprint.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load device fingerprints: $e');
    }
  }

  // Update investigation status for correlation pattern
  Future<void> updateInvestigationStatus({
    required String patternId,
    required String status,
    String? notes,
  }) async {
    try {
      await _supabase.from('anomaly_correlation_patterns').update({
        'investigation_status': status,
        if (notes != null) 'investigation_notes': notes,
        'investigated_by': _supabase.auth.currentUser?.id,
        'investigated_at': DateTime.now().toIso8601String(),
      }).eq('id', patternId);
    } catch (e) {
      throw Exception('Failed to update investigation status: $e');
    }
  }

  // Generate forensic investigation report summary
  Future<Map<String, dynamic>> generateForensicSummary({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Get timeline events
      final timeline = await getForensicTimeline(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
      );

      // Get correlation patterns
      final patterns = await detectCorrelationPatterns(userId: userId);

      // Calculate statistics
      final totalEvents = timeline.length;
      final anomalousEvents = timeline.where((e) => e.riskIndicator).length;
      final uniqueIps = timeline
          .map((e) => e.ipAddress)
          .where((ip) => ip != null)
          .toSet()
          .length;
      final uniqueDevices = timeline
          .map((e) => e.deviceInfo?['browser_name'])
          .where((b) => b != null)
          .toSet()
          .length;

      final highRiskPatterns = patterns
          .where((p) => p.riskLevel == 'high' || p.riskLevel == 'critical')
          .length;

      return {
        'total_events': totalEvents,
        'anomalous_events': anomalousEvents,
        'anomaly_percentage': totalEvents > 0
            ? (anomalousEvents / totalEvents * 100).toStringAsFixed(1)
            : '0.0',
        'unique_ips': uniqueIps,
        'unique_devices': uniqueDevices,
        'correlation_patterns': patterns.length,
        'high_risk_patterns': highRiskPatterns,
        'time_span_hours': endTime.difference(startTime).inHours,
      };
    } catch (e) {
      throw Exception('Failed to generate forensic summary: $e');
    }
  }
}
