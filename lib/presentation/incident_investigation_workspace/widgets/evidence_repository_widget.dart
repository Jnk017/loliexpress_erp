import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/investigation_workspace_service.dart';

class EvidenceRepositoryWidget extends StatefulWidget {
  final String incidentId;

  const EvidenceRepositoryWidget({super.key, required this.incidentId});

  @override
  State<EvidenceRepositoryWidget> createState() =>
      _EvidenceRepositoryWidgetState();
}

class _EvidenceRepositoryWidgetState extends State<EvidenceRepositoryWidget> {
  final _workspaceService = InvestigationWorkspaceService();
  List<Map<String, dynamic>> _evidence = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    try {
      final evidence = await _workspaceService.getEvidence(widget.incidentId);
      setState(() {
        _evidence = evidence;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredEvidence() {
    if (_selectedCategory == 'all') return _evidence;
    return _evidence.where((e) => e['category'] == _selectedCategory).toList();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'log':
        return 'Logs';
      case 'screenshot':
        return 'Screenshots';
      case 'document':
        return 'Documents';
      case 'network_capture':
        return 'Network Captures';
      case 'forensic_artifact':
        return 'Forensic Artifacts';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'log':
        return Icons.description;
      case 'screenshot':
        return Icons.image;
      case 'document':
        return Icons.file_present;
      case 'network_capture':
        return Icons.router;
      case 'forensic_artifact':
        return Icons.biotech;
      default:
        return Icons.folder;
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredEvidence = _getFilteredEvidence();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'All'),
                _buildCategoryChip('log', 'Logs'),
                _buildCategoryChip('screenshot', 'Screenshots'),
                _buildCategoryChip('document', 'Documents'),
                _buildCategoryChip('network_capture', 'Network'),
                _buildCategoryChip('forensic_artifact', 'Forensic'),
                _buildCategoryChip('other', 'Other'),
              ],
            ),
          ),
        ),
        Expanded(
          child: filteredEvidence.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 2.h),
                      Text(
                        'No evidence in this category',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: filteredEvidence.length,
                  itemBuilder: (context, index) {
                    final item = filteredEvidence[index];
                    final collectedBy =
                        item['collected_by'] as Map<String, dynamic>?;

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: item['is_critical'] == true
                            ? Border.all(color: Colors.red[700]!, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        leading: Icon(
                          _getCategoryIcon(item['category']),
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item['is_critical'] == true)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'CRITICAL',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 0.5.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 12.sp,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  _getCategoryDisplayName(item['category']),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Icon(
                                  Icons.storage,
                                  size: 12.sp,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  _formatFileSize(item['file_size']),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item['description'] != null) ...[
                                  Text(
                                    'Description:',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    item['description'],
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                ],
                                Row(
                                  children: [
                                    Text(
                                      'Collected by: ',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (collectedBy != null)
                                      Text(
                                        collectedBy['full_name'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Collected: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(item['collected_at']))}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (item['file_path'] != null) ...[
                                  SizedBox(height: 2.h),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text('Download'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: Colors.blue[700],
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }
}
