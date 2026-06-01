import 'package:supabase_flutter/supabase_flutter.dart';

class ForensicExportService {
  final _client = Supabase.instance.client;

  // Export template models
  static const String tableExportTemplates = 'forensic_export_templates';
  static const String tableExportHistory = 'forensic_export_history';

  // ============================================================================
  // EXPORT TEMPLATES MANAGEMENT
  // ============================================================================

  /// Get all active export templates
  Future<List<Map<String, dynamic>>> getExportTemplates() async {
    final response = await _client.from(tableExportTemplates).select('''
          *,
          creator:created_by(id, full_name, email)
        ''').eq('is_active', true).order('template_name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get export template by ID
  Future<Map<String, dynamic>?> getExportTemplate(String templateId) async {
    final response = await _client.from(tableExportTemplates).select('''
          *,
          creator:created_by(id, full_name, email)
        ''').eq('id', templateId).single();

    return response;
  }

  /// Get export templates by type
  Future<List<Map<String, dynamic>>> getExportTemplatesByType(
      String templateType) async {
    final response = await _client
        .from(tableExportTemplates)
        .select('''
          *,
          creator:created_by(id, full_name, email)
        ''')
        .eq('template_type', templateType)
        .eq('is_active', true)
        .order('template_name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create new export template (admin only)
  Future<Map<String, dynamic>> createExportTemplate({
    required String templateName,
    required String templateType,
    required String format,
    String? description,
    bool includeTimeline = true,
    bool includeIpGeolocation = true,
    bool includeDeviceFingerprints = true,
    bool includeAnomalyCorrelations = true,
    bool includeAuditLogs = true,
    String? complianceStandard,
    Map<String, dynamic>? reportSections,
    String? watermarkText,
    bool digitalSignatureRequired = false,
  }) async {
    final response = await _client
        .from(tableExportTemplates)
        .insert({
          'template_name': templateName,
          'template_type': templateType,
          'description': description,
          'format': format,
          'include_timeline': includeTimeline,
          'include_ip_geolocation': includeIpGeolocation,
          'include_device_fingerprints': includeDeviceFingerprints,
          'include_anomaly_correlations': includeAnomalyCorrelations,
          'include_audit_logs': includeAuditLogs,
          'compliance_standard': complianceStandard,
          'report_sections': reportSections,
          'watermark_text': watermarkText,
          'digital_signature_required': digitalSignatureRequired,
        })
        .select()
        .single();

    return response;
  }

  // ============================================================================
  // FORENSIC EVIDENCE EXPORT
  // ============================================================================

  /// Generate filtered forensic evidence export
  Future<List<Map<String, dynamic>>> generateForensicEvidenceExport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? userIds,
    List<String>? anomalyTypes,
    List<String>? severityLevels,
    List<String>? ipAddresses,
  }) async {
    final response = await _client.rpc(
      'generate_forensic_evidence_export',
      params: {
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': endDate.toIso8601String(),
        'p_user_ids': userIds,
        'p_anomaly_types': anomalyTypes,
        'p_severity_levels': severityLevels,
        'p_ip_addresses': ipAddresses,
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================================
  // IP CORRELATION EXPORT
  // ============================================================================

  /// Generate IP correlation export
  Future<List<Map<String, dynamic>>> generateIpCorrelationExport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? threatLevels,
  }) async {
    final response = await _client.rpc(
      'generate_ip_correlation_export',
      params: {
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': endDate.toIso8601String(),
        'p_threat_levels': threatLevels,
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================================
  // INVESTIGATION SUMMARY EXPORT
  // ============================================================================

  /// Generate investigation summary export
  Future<Map<String, dynamic>?> generateInvestigationSummaryExport(
      String investigationReportId) async {
    final response = await _client.rpc(
      'generate_investigation_summary_export',
      params: {
        'p_investigation_report_id': investigationReportId,
      },
    );

    if (response is List && response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  // ============================================================================
  // EXPORT HISTORY & AUDIT TRAIL
  // ============================================================================

  /// Create export record (audit trail)
  Future<String> createExportRecord({
    required String exportName,
    required String templateId,
    required String format,
    required DateTime filterStartDate,
    required DateTime filterEndDate,
    List<String>? filterUserIds,
    List<String>? filterAnomalyTypes,
    List<String>? filterSeverityLevels,
  }) async {
    final response = await _client.rpc(
      'create_forensic_export_record',
      params: {
        'p_export_name': exportName,
        'p_template_id': templateId,
        'p_format': format,
        'p_filter_start_date': filterStartDate.toIso8601String(),
        'p_filter_end_date': filterEndDate.toIso8601String(),
        'p_filter_user_ids': filterUserIds,
        'p_filter_anomaly_types': filterAnomalyTypes,
        'p_filter_severity_levels': filterSeverityLevels,
      },
    );

    return response as String;
  }

  /// Get export history with filters
  Future<List<Map<String, dynamic>>> getExportHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    var query = _client.from(tableExportHistory).select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''').order('exported_at', ascending: false).limit(limit);

    if (status != null) {
      final statusQuery = await _client
          .from(tableExportHistory)
          .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
          .eq('status', status)
          .order('exported_at', ascending: false)
          .limit(limit);

      if (startDate != null) {
        final startDateQuery = await _client
            .from(tableExportHistory)
            .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
            .eq('status', status)
            .gte('exported_at', startDate.toIso8601String())
            .order('exported_at', ascending: false)
            .limit(limit);

        if (endDate != null) {
          final response = await _client
              .from(tableExportHistory)
              .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
              .eq('status', status)
              .gte('exported_at', startDate.toIso8601String())
              .lte('exported_at', endDate.toIso8601String())
              .order('exported_at', ascending: false)
              .limit(limit);
          return List<Map<String, dynamic>>.from(response);
        }
        return List<Map<String, dynamic>>.from(startDateQuery);
      } else if (endDate != null) {
        final endDateQuery = await _client
            .from(tableExportHistory)
            .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
            .eq('status', status)
            .lte('exported_at', endDate.toIso8601String())
            .order('exported_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(endDateQuery);
      }
      return List<Map<String, dynamic>>.from(statusQuery);
    }

    if (startDate != null) {
      final startDateQuery = await _client
          .from(tableExportHistory)
          .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
          .gte('exported_at', startDate.toIso8601String())
          .order('exported_at', ascending: false)
          .limit(limit);

      if (endDate != null) {
        final response = await _client
            .from(tableExportHistory)
            .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
            .gte('exported_at', startDate.toIso8601String())
            .lte('exported_at', endDate.toIso8601String())
            .order('exported_at', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }
      return List<Map<String, dynamic>>.from(startDateQuery);
    }

    if (endDate != null) {
      final endDateQuery = await _client
          .from(tableExportHistory)
          .select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''')
          .lte('exported_at', endDate.toIso8601String())
          .order('exported_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(endDateQuery);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get export history by ID
  Future<Map<String, dynamic>?> getExportHistoryById(String exportId) async {
    final response = await _client.from(tableExportHistory).select('''
          *,
          template:template_id(*),
          exporter:exported_by(id, full_name, email)
        ''').eq('id', exportId).single();

    return response;
  }

  /// Update export status
  Future<void> updateExportStatus({
    required String exportId,
    required String status,
    String? filePath,
    int? fileSizeBytes,
    int? recordCount,
    String? errorMessage,
    String? digitalSignature,
    bool? watermarkApplied,
  }) async {
    await _client.from(tableExportHistory).update({
      'status': status,
      if (filePath != null) 'file_path': filePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (recordCount != null) 'record_count': recordCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (digitalSignature != null) 'digital_signature': digitalSignature,
      if (watermarkApplied != null) 'watermark_applied': watermarkApplied,
    }).eq('id', exportId);
  }

  /// Get export statistics
  Future<Map<String, dynamic>> getExportStatistics() async {
    final response = await _client.from(tableExportHistory).select('status');

    final List<dynamic> exports = response as List;
    final total = exports.length;
    final completed = exports.where((e) => e['status'] == 'completed').length;
    final failed = exports.where((e) => e['status'] == 'failed').length;
    final pending = exports.where((e) => e['status'] == 'pending').length;

    return {
      'total': total,
      'completed': completed,
      'failed': failed,
      'pending': pending,
      'success_rate':
          total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
    };
  }
}
