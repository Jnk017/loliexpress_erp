import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/forensic_export_service.dart';

class ForensicExportDialogWidget extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<String>? preSelectedUserIds;

  const ForensicExportDialogWidget({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.preSelectedUserIds,
  });

  @override
  State<ForensicExportDialogWidget> createState() =>
      _ForensicExportDialogWidgetState();
}

class _ForensicExportDialogWidgetState
    extends State<ForensicExportDialogWidget> {
  final _exportService = ForensicExportService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedTemplateId;
  String _selectedFormat = 'pdf';
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedAnomalyTypes = [];
  List<String> _selectedSeverityLevels = [];

  List<Map<String, dynamic>> _templates = [];
  bool _isLoadingTemplates = true;
  bool _isExporting = false;

  final List<String> _anomalyTypeOptions = [
    'transaction',
    'access',
    'inventory',
    'permission',
    'system'
  ];
  final List<String> _severityOptions = ['low', 'medium', 'high', 'critical'];
  final List<String> _formatOptions = ['pdf', 'csv', 'json', 'excel'];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ??
        DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.initialEndDate ?? DateTime.now();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _exportService.getExportTemplates();
      setState(() {
        _templates = templates;
        _isLoadingTemplates = false;
        if (templates.isNotEmpty) {
          _selectedTemplateId = templates.first['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoadingTemplates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateExport() async {
    if (!_formKey.currentState!.validate() || _selectedTemplateId == null) {
      return;
    }

    setState(() => _isExporting = true);

    try {
      final selectedTemplate = _templates.firstWhere(
        (t) => t['id'] == _selectedTemplateId,
      );

      final exportId = await _exportService.createExportRecord(
        exportName:
            'Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
        templateId: _selectedTemplateId!,
        format: _selectedFormat,
        filterStartDate: _startDate!,
        filterEndDate: _endDate!,
        filterUserIds: widget.preSelectedUserIds,
        filterAnomalyTypes:
            _selectedAnomalyTypes.isNotEmpty ? _selectedAnomalyTypes : null,
        filterSeverityLevels:
            _selectedSeverityLevels.isNotEmpty ? _selectedSeverityLevels : null,
      );

      List<Map<String, dynamic>> exportData = [];

      if (selectedTemplate['template_type'] == 'forensic_evidence' ||
          selectedTemplate['template_type'] == 'regulatory_compliance') {
        exportData = await _exportService.generateForensicEvidenceExport(
          startDate: _startDate!,
          endDate: _endDate!,
          userIds: widget.preSelectedUserIds,
          anomalyTypes:
              _selectedAnomalyTypes.isNotEmpty ? _selectedAnomalyTypes : null,
          severityLevels: _selectedSeverityLevels.isNotEmpty
              ? _selectedSeverityLevels
              : null,
        );
      } else if (selectedTemplate['template_type'] == 'ip_correlation') {
        exportData = await _exportService.generateIpCorrelationExport(
          startDate: _startDate!,
          endDate: _endDate!,
        );
      }

      await _exportService.updateExportStatus(
        exportId: exportId,
        status: 'completed',
        recordCount: exportData.length,
        fileSizeBytes: exportData.length * 512,
        watermarkApplied: selectedTemplate['watermark_text'] != null,
      );

      if (mounted) {
        Navigator.of(context).pop(exportData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Export completed successfully! ${exportData.length} records exported.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 90.w,
        constraints: BoxConstraints(maxHeight: 85.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12.0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_download,
                      color: Colors.white, size: 24.0),
                  SizedBox(width: 2.w),
                  Text(
                    'Export Forensic Evidence',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Template',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        _isLoadingTemplates
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: _selectedTemplateId,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 8.0),
                                ),
                                items: _templates.map((template) {
                                  return DropdownMenuItem<String>(
                                    value: template['id'],
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template['template_name'],
                                          style: TextStyle(fontSize: 12.sp),
                                        ),
                                        if (template['description'] != null)
                                          Text(
                                            template['description'],
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedTemplateId = value);
                                },
                                validator: (value) => value == null
                                    ? 'Please select a template'
                                    : null,
                              ),
                        SizedBox(height: 2.h),
                        Text(
                          'Export Format',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          children: _formatOptions.map((format) {
                            return ChoiceChip(
                              label: Text(format.toUpperCase()),
                              selected: _selectedFormat == format,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFormat = format);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        InkWell(
                          onTap: _selectDateRange,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Anomaly Types (Optional)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          children: _anomalyTypeOptions.map((type) {
                            return FilterChip(
                              label: Text(type),
                              selected: _selectedAnomalyTypes.contains(type),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAnomalyTypes.add(type);
                                  } else {
                                    _selectedAnomalyTypes.remove(type);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Severity Levels (Optional)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          children: _severityOptions.map((severity) {
                            return FilterChip(
                              label: Text(severity),
                              selected:
                                  _selectedSeverityLevels.contains(severity),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSeverityLevels.add(severity);
                                  } else {
                                    _selectedSeverityLevels.remove(severity);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 3.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _generateExport,
                            icon: _isExporting
                                ? SizedBox(
                                    width: 16.0,
                                    height: 16.0,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(
                              _isExporting
                                  ? 'Generating Export...'
                                  : 'Generate Export',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}