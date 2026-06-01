import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/purchase_service.dart';

class PurchasesReportWidget extends StatefulWidget {
  const PurchasesReportWidget({super.key});

  @override
  State<PurchasesReportWidget> createState() => _PurchasesReportWidgetState();
}

class _PurchasesReportWidgetState extends State<PurchasesReportWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _purchases = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final stats = await PurchaseService.instance.getPurchaseStats();
      final purchases = await PurchaseService.instance.getPurchases();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, double> _getTopSuppliers() {
    final Map<String, double> supplierTotals = {};
    for (final purchase in _purchases) {
      final supplier = purchase['suppliers'] as Map<String, dynamic>?;
      final name = supplier?['company_name'] ?? 'Inconnu';
      final amount = (purchase['total_amount'] as num?)?.toDouble() ?? 0;
      supplierTotals[name] = (supplierTotals[name] ?? 0) + amount;
    }

    final sorted = supplierTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(5));
  }

  Map<String, double> _getMonthlyTrend() {
    final Map<String, double> monthly = {};
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];

    for (final purchase in _purchases) {
      final createdAt = purchase['created_at'] as String?;
      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt);
          final key = '${months[date.month - 1]} ${date.year}';
          final amount = (purchase['total_amount'] as num?)?.toDouble() ?? 0;
          monthly[key] = (monthly[key] ?? 0) + amount;
        } catch (_) {}
      }
    }

    return monthly;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            SizedBox(height: 1.h),
            Text('Erreur: $_errorMessage', textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalCards(),
            SizedBox(height: 2.h),
            _buildStatusBreakdown(),
            SizedBox(height: 2.h),
            _buildTopSuppliers(),
            SizedBox(height: 2.h),
            _buildMonthlyTrend(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCards() {
    final totalCDF = (_stats!['total_cdf'] as num?)?.toDouble() ?? 0;
    final totalUSD = (_stats!['total_usd'] as num?)?.toDouble() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total achats CDF',
            value: 'FC ${totalCDF.toStringAsFixed(0)}',
            icon: Icons.shopping_bag,
            color: Colors.indigo,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _StatCard(
            title: 'Total achats USD',
            value: '\$${totalUSD.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown() {
    final pending = (_stats!['pending'] as num?)?.toInt() ?? 0;
    final received = (_stats!['received'] as num?)?.toInt() ?? 0;
    final total = pending + received;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par statut',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: received / total,
                  backgroundColor: Colors.orange.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 12,
                ),
              ),
              SizedBox(height: 1.5.h),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusChip(
                  label: 'En attente',
                  count: pending,
                  color: Colors.orange,
                ),
                _StatusChip(
                  label: 'Reçus',
                  count: received,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSuppliers() {
    final topSuppliers = _getTopSuppliers();
    if (topSuppliers.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue =
        topSuppliers.values.isEmpty ? 1.0 : topSuppliers.values.first;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 fournisseurs',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ...topSuppliers.entries.map((entry) {
              final fraction = maxValue > 0 ? entry.value / maxValue : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(fontSize: 11.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'FC ${entry.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.indigo.shade300),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrend() {
    final monthly = _getMonthlyTrend();
    if (monthly.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = monthly.values.isEmpty
        ? 1.0
        : monthly.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendance mensuelle',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ...monthly.entries.map((entry) {
              final fraction = maxValue > 0 ? entry.value / maxValue : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18.w,
                      child: Text(
                        entry.key,
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal.shade300),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'FC ${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 9.sp, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
        ),
      ],
    );
  }
}
