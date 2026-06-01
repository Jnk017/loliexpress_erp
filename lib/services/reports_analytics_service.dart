import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time reports updates
  final StreamController<Map<String, dynamic>> _salesMetricsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _inventoryMetricsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _financialMetricsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _customerMetricsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _agingReportController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Realtime subscriptions
  RealtimeChannel? _salesOrdersChannel;
  RealtimeChannel? _invoicesChannel;
  RealtimeChannel? _paymentsChannel;
  RealtimeChannel? _inventoryChannel;

  Stream<Map<String, dynamic>> get salesMetricsStream =>
      _salesMetricsController.stream;
  Stream<Map<String, dynamic>> get inventoryMetricsStream =>
      _inventoryMetricsController.stream;
  Stream<Map<String, dynamic>> get financialMetricsStream =>
      _financialMetricsController.stream;
  Stream<Map<String, dynamic>> get customerMetricsStream =>
      _customerMetricsController.stream;
  Stream<Map<String, dynamic>> get agingReportStream =>
      _agingReportController.stream;

  /// Initialize real-time subscriptions for reports & analytics
  Future<void> initializeRealtimeSubscriptions() async {
    // Subscribe to sales_orders for sales analytics
    _salesOrdersChannel = _supabase
        .channel('sales_orders_analytics')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sales_orders',
          callback: (payload) => _handleSalesOrderChange(payload),
        )
        .subscribe();

    // Subscribe to invoices for financial analytics and aging report
    _invoicesChannel = _supabase
        .channel('invoices_analytics')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (payload) => _handleInvoiceChange(payload),
        )
        .subscribe();

    // Subscribe to payments for receivables aging updates
    _paymentsChannel = _supabase
        .channel('payments_analytics')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (payload) => _handlePaymentChange(payload),
        )
        .subscribe();

    // Subscribe to inventory_stock for inventory analytics
    _inventoryChannel = _supabase
        .channel('inventory_analytics')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory_stock',
          callback: (payload) => _handleInventoryChange(payload),
        )
        .subscribe();
  }

  /// Handle sales order changes - refresh sales charts
  void _handleSalesOrderChange(PostgresChangePayload payload) async {
    debugPrint('Sales order change detected: ${payload.eventType}');
    await refreshSalesMetrics();
    await refreshFinancialMetrics();
    await refreshCustomerMetrics();
  }

  /// Handle invoice changes - refresh financial charts and aging report
  void _handleInvoiceChange(PostgresChangePayload payload) async {
    debugPrint('Invoice change detected: ${payload.eventType}');
    await refreshFinancialMetrics();
    await refreshAgingReport();
  }

  /// Handle payment changes - refresh aging report instantly
  void _handlePaymentChange(PostgresChangePayload payload) async {
    debugPrint('Payment change detected: ${payload.eventType}');
    await refreshAgingReport();
    await refreshFinancialMetrics();
  }

  /// Handle inventory changes - refresh inventory charts
  void _handleInventoryChange(PostgresChangePayload payload) async {
    debugPrint('Inventory change detected: ${payload.eventType}');
    await refreshInventoryMetrics();
  }

  /// Fetch and calculate sales metrics
  Future<Map<String, dynamic>> getSalesMetrics() async {
    try {
      final startDate =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      // Total revenue
      final ordersResponse = await _supabase
          .from('sales_orders')
          .select('total_amount, order_date')
          .gte('order_date', startDate)
          .order('order_date');

      double totalRevenue = 0;
      List<Map<String, dynamic>> chartData = [];

      for (var order in ordersResponse) {
        totalRevenue += (order['total_amount'] as num?)?.toDouble() ?? 0;
        chartData.add({
          'date': order['order_date'],
          'amount': order['total_amount'],
        });
      }

      // Sales by category
      final categoryResponse =
          await _supabase.rpc('get_sales_by_category', params: {
        'start_date': startDate,
      }).catchError((e) async {
        debugPrint('RPC call failed, using fallback query: $e');
        return await _supabase.from('order_items').select('''
              quantity,
              line_total,
              products!inner (
                name,
                category_id,
                product_categories!inner (
                  name
                )
              )
            ''').gte('created_at', startDate);
      });

      return {
        'totalRevenue': totalRevenue,
        'chartData': chartData,
        'categoryData': categoryResponse,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error fetching sales metrics: $e');
      return {
        'totalRevenue': 0,
        'chartData': [],
        'categoryData': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Fetch and calculate inventory metrics
  Future<Map<String, dynamic>> getInventoryMetrics() async {
    try {
      // Stock levels by product
      final stockResponse = await _supabase.from('inventory_stock').select('''
            quantity,
            reorder_level,
            products!inner (
              name,
              sku
            )
          ''').order('quantity', ascending: true);

      // Low stock items
      List<Map<String, dynamic>> lowStockItems = [];
      List<Map<String, dynamic>> stockLevels = [];

      for (var item in stockResponse) {
        final product = item['products'] as Map<String, dynamic>?;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final reorderLevel = (item['reorder_level'] as num?)?.toInt() ?? 10;

        stockLevels.add({
          'product': product?['name'] ?? 'Unknown',
          'quantity': quantity,
        });

        if (quantity <= reorderLevel) {
          lowStockItems.add({
            'product': product?['name'] ?? 'Unknown',
            'sku': product?['sku'] ?? 'N/A',
            'quantity': quantity,
            'reorderLevel': reorderLevel,
          });
        }
      }

      return {
        'stockLevels': stockLevels,
        'lowStockItems': lowStockItems,
        'totalProducts': stockLevels.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error fetching inventory metrics: $e');
      return {
        'stockLevels': [],
        'lowStockItems': [],
        'totalProducts': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Fetch and calculate financial metrics including profitability
  Future<Map<String, dynamic>> getFinancialMetrics() async {
    try {
      final startDate =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      // Revenue from orders
      final ordersResponse = await _supabase
          .from('sales_orders')
          .select('total_amount, subtotal, tax_amount')
          .gte('order_date', startDate);

      double totalRevenue = 0;
      double totalCost = 0;

      for (var order in ordersResponse) {
        totalRevenue += (order['total_amount'] as num?)?.toDouble() ?? 0;
      }

      // Expenses
      final expensesResponse = await _supabase
          .from('expenses')
          .select('amount')
          .gte('expense_date', startDate);

      double totalExpenses = 0;
      for (var expense in expensesResponse) {
        totalExpenses += (expense['amount'] as num?)?.toDouble() ?? 0;
      }

      // Calculate profitability
      final grossProfit = totalRevenue - totalCost;
      final netProfit = grossProfit - totalExpenses;
      final profitMargin =
          totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;

      return {
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'grossProfit': grossProfit,
        'netProfit': netProfit,
        'profitMargin': profitMargin,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error fetching financial metrics: $e');
      return {
        'totalRevenue': 0,
        'totalExpenses': 0,
        'grossProfit': 0,
        'netProfit': 0,
        'profitMargin': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Fetch customer analytics metrics
  Future<Map<String, dynamic>> getCustomerMetrics() async {
    try {
      // Top customers by revenue
      final customersResponse = await _supabase.rpc(
        'get_top_customers',
        params: {'limit_count': 10},
      ).catchError((e) async {
        debugPrint('RPC call failed, using fallback query: $e');
        return await _supabase.from('sales_orders').select('''
              customer_id,
              total_amount,
              customers!inner (
                company_name
              )
            ''').order('total_amount', ascending: false).limit(10);
      });

      List<Map<String, dynamic>> topCustomers = [];
      if (customersResponse is List) {
        for (var item in customersResponse) {
          final customer = item['customers'] as Map<String, dynamic>?;
          topCustomers.add({
            'name': customer?['company_name'] ?? 'Unknown',
            'revenue': item['total_amount'] ?? 0,
          });
        }
      }

      // Total active customers
      final activeCustomersResponse =
          await _supabase.from('customers').select('id').eq('is_active', true);

      final activeCustomersCount = activeCustomersResponse.length;

      return {
        'topCustomers': topCustomers,
        'activeCustomersCount': activeCustomersCount,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error fetching customer metrics: $e');
      return {
        'topCustomers': [],
        'activeCustomersCount': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Fetch accounts receivable aging report
  Future<Map<String, dynamic>> getAgingReport() async {
    try {
      final response = await _supabase.from('invoices').select('''
            id,
            invoice_number,
            total_amount,
            amount_paid,
            due_date,
            payment_status,
            customer_id,
            customers!inner (
              company_name
            )
          ''').inFilter('payment_status', [
        'pending',
        'partial'
      ]).order('due_date', ascending: true);

      Map<String, List<Map<String, dynamic>>> agingBuckets = {
        'current': [],
        '30-day': [],
        '60-day': [],
        '90-day': [],
      };

      Map<String, double> agingTotals = {
        'current': 0,
        '30-day': 0,
        '60-day': 0,
        '90-day': 0,
      };

      for (var invoice in response) {
        final customer = invoice['customers'] as Map<String, dynamic>?;
        final totalAmount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (invoice['amount_paid'] as num?)?.toDouble() ?? 0;
        final outstanding = totalAmount - amountPaid;
        final dueDate = DateTime.parse(invoice['due_date'] as String);
        final now = DateTime.now();
        final daysOverdue = now.difference(dueDate).inDays;

        String bucket = 'current';
        if (daysOverdue > 90) {
          bucket = '90-day';
        } else if (daysOverdue > 60) {
          bucket = '60-day';
        } else if (daysOverdue > 30) {
          bucket = '30-day';
        }

        final invoiceData = {
          'invoiceNumber': invoice['invoice_number'],
          'customer': customer?['company_name'] ?? 'Unknown',
          'amount': outstanding,
          'daysOverdue': daysOverdue > 0 ? daysOverdue : 0,
          'dueDate': invoice['due_date'],
        };

        agingBuckets[bucket]?.add(invoiceData);
        agingTotals[bucket] = (agingTotals[bucket] ?? 0) + outstanding;
      }

      final totalOutstanding = agingTotals.values.fold(0.0, (a, b) => a + b);

      return {
        'agingBuckets': agingBuckets,
        'agingTotals': agingTotals,
        'totalOutstanding': totalOutstanding,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error fetching aging report: $e');
      return {
        'agingBuckets': {
          'current': [],
          '30-day': [],
          '60-day': [],
          '90-day': []
        },
        'agingTotals': {'current': 0, '30-day': 0, '60-day': 0, '90-day': 0},
        'totalOutstanding': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Refresh sales metrics and emit to stream
  Future<void> refreshSalesMetrics() async {
    try {
      final metrics = await getSalesMetrics();
      _salesMetricsController.add(metrics);
    } catch (e) {
      debugPrint('Error refreshing sales metrics: $e');
    }
  }

  /// Refresh inventory metrics and emit to stream
  Future<void> refreshInventoryMetrics() async {
    try {
      final metrics = await getInventoryMetrics();
      _inventoryMetricsController.add(metrics);
    } catch (e) {
      debugPrint('Error refreshing inventory metrics: $e');
    }
  }

  /// Refresh financial metrics and emit to stream
  Future<void> refreshFinancialMetrics() async {
    try {
      final metrics = await getFinancialMetrics();
      _financialMetricsController.add(metrics);
    } catch (e) {
      debugPrint('Error refreshing financial metrics: $e');
    }
  }

  /// Refresh customer metrics and emit to stream
  Future<void> refreshCustomerMetrics() async {
    try {
      final metrics = await getCustomerMetrics();
      _customerMetricsController.add(metrics);
    } catch (e) {
      debugPrint('Error refreshing customer metrics: $e');
    }
  }

  /// Refresh aging report and emit to stream
  Future<void> refreshAgingReport() async {
    try {
      final report = await getAgingReport();
      _agingReportController.add(report);
    } catch (e) {
      debugPrint('Error refreshing aging report: $e');
    }
  }

  /// Cleanup subscriptions
  void dispose() {
    _salesOrdersChannel?.unsubscribe();
    _invoicesChannel?.unsubscribe();
    _paymentsChannel?.unsubscribe();
    _inventoryChannel?.unsubscribe();
    _salesMetricsController.close();
    _inventoryMetricsController.close();
    _financialMetricsController.close();
    _customerMetricsController.close();
    _agingReportController.close();
  }
}
