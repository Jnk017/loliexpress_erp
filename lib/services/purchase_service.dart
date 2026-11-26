import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseService {
  static PurchaseService? _instance;
  static PurchaseService get instance => _instance ??= PurchaseService._();
  PurchaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  // Suppliers
  Future<List<Map<String, dynamic>>> getSuppliers({String? search}) async {
    try {
      var query = _client.from('suppliers').select();
      if (search != null && search.isNotEmpty) {
        query = query
            .or('company_name.ilike.%$search%,contact_person.ilike.%$search%');
      }
      final response = await query.order('company_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur chargement fournisseurs: $e');
    }
  }

  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    try {
      return await _client.from('suppliers').insert(data).select().single();
    } catch (e) {
      throw Exception('Erreur création fournisseur: $e');
    }
  }

  Future<Map<String, dynamic>> updateSupplier(
      String id, Map<String, dynamic> data) async {
    try {
      return await _client
          .from('suppliers')
          .update(data)
          .eq('id', id)
          .select()
          .single();
    } catch (e) {
      throw Exception('Erreur mise à jour fournisseur: $e');
    }
  }

  // Purchases
  Future<List<Map<String, dynamic>>> getPurchases(
      {String? status, String? supplierId, int limit = 50}) async {
    try {
      var query = _client
          .from('purchases')
          .select('*, suppliers(company_name, contact_person)');
      if (status != null) query = query.eq('status', status);
      if (supplierId != null) query = query.eq('supplier_id', supplierId);
      final response =
          await query.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur chargement achats: $e');
    }
  }

  Future<Map<String, dynamic>?> getPurchaseById(String id) async {
    try {
      return await _client
          .from('purchases')
          .select(
              '*, suppliers(company_name), purchase_items(*, products(name, sku)), supplier_bills(id,bill_number,due_date,currency,amount,amount_paid)')
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      throw Exception('Erreur chargement achat: $e');
    }
  }

  Future<Map<String, dynamic>> createPurchase({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    required String currency,
    double? exchangeRate,
    String? notes,
  }) async {
    try {
      final result = await _client.rpc('create_purchase_with_items', params: {
        'p_supplier_id': supplierId,
        'p_items': items,
        'p_currency': currency,
        'p_exchange_rate': exchangeRate,
        'p_notes': notes,
      });
      if (result is! Map) {
        throw const FormatException('Réponse de création achat invalide');
      }
      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw Exception('Erreur création achat: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProcurementProductChoices() async {
    final rows = await _client.rpc('list_procurement_product_choices');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> getWarehouseReceiptQueue() async {
    final rows = await _client.rpc('list_warehouse_purchase_receipts');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> receivePurchaseItem({
    required String purchaseItemId,
    required String warehouseId,
    required int quantity,
    required String requestId,
  }) async {
    final result = await _client.rpc('receive_purchase_item', params: {
      'p_purchase_item_id': purchaseItemId,
      'p_warehouse_id': warehouseId,
      'p_quantity': quantity,
      'p_request_id': requestId,
    });
    if (result is! Map) {
      throw const FormatException('Réponse de réception achat invalide');
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> updatePurchaseStatus(
      String id, String status) async {
    if (status != 'cancelled') {
      throw ArgumentError.value(status, 'status', 'Enregistrez une réception pour changer ce statut');
    }
    try {
      final result = await _client.rpc('cancel_unreceived_purchase', params: {'p_purchase_id': id});
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  Future<void> registerSupplierBill({
    required String purchaseId,
    required String billNumber,
    required String dueDate,
    required double amount,
  }) async {
    await _client.rpc('register_supplier_bill', params: {
      'p_purchase_id': purchaseId,
      'p_bill_number': billNumber,
      'p_due_date': dueDate,
      'p_amount': amount,
    });
  }

  Future<void> recordSupplierBillPayment({
    required String billId,
    required double amount,
    required String currency,
    required String reference,
    required String requestId,
    required String accountKind,
    required String paymentMethod,
    required String accountId,
  }) async {
    await _client.rpc('pay_supplier_bill_from_account', params: {
      'p_bill_id': billId,
      'p_amount': amount,
      'p_currency': currency,
      'p_reference': reference,
      'p_request_id': requestId,
      'p_kind': accountKind,
      'p_method': paymentMethod,
      'p_account_id': accountId,
    });
  }

  // Stats
  Future<Map<String, dynamic>> getPurchaseStats() async {
    try {
      final purchases = await _client
          .from('purchases')
          .select('total_amount, currency, status, payment_status');
      double totalCDF = 0, totalUSD = 0;
      int pending = 0, received = 0, unpaid = 0;
      for (final p in purchases) {
        final amount = (p['total_amount'] as num?)?.toDouble() ?? 0;
        if (p['currency'] == 'USD') {
          totalUSD += amount;
        } else {
          totalCDF += amount;
        }
        if (p['status'] == 'pending') pending++;
        if (p['status'] == 'received') received++;
        if (p['payment_status'] != 'paid') unpaid++;
      }
      return {
        'total_cdf': totalCDF,
        'total_usd': totalUSD,
        'total_purchases': purchases.length,
        'pending': pending,
        'received': received,
        'unpaid': unpaid,
      };
    } catch (e) {
      throw Exception('Erreur stats achats: $e');
    }
  }

  // Receivables aging
  Future<List<Map<String, dynamic>>> getReceivablesAging() async {
    try {
      final response = await _client.from('receivables_aging').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur chargement créances: $e');
    }
  }

  Future<Map<String, dynamic>> getReceivablesSummary() async {
    try {
      final receivables = await getReceivablesAging();
      double totalCDF = 0, totalUSD = 0;
      int count0_30 = 0, count31_60 = 0, count61_90 = 0, count90plus = 0;
      Map<String, double> byCustomerCDF = {};
      Map<String, double> byCustomerUSD = {};

      for (final r in receivables) {
        final amount = (r['total_amount'] as num?)?.toDouble() ?? 0;
        final currency = r['currency'] ?? 'CDF';
        final customer = r['company_name'] ?? 'Inconnu';
        final bracket = r['aging_bracket'] ?? '';

        if (currency == 'USD') {
          totalUSD += amount;
          byCustomerUSD[customer] = (byCustomerUSD[customer] ?? 0) + amount;
        } else {
          totalCDF += amount;
          byCustomerCDF[customer] = (byCustomerCDF[customer] ?? 0) + amount;
        }

        switch (bracket) {
          case '0-30 jours':
            count0_30++;
            break;
          case '31-60 jours':
            count31_60++;
            break;
          case '61-90 jours':
            count61_90++;
            break;
          case '90+ jours':
            count90plus++;
            break;
        }
      }

      return {
        'total_cdf': totalCDF,
        'total_usd': totalUSD,
        'count': receivables.length,
        'bracket_0_30': count0_30,
        'bracket_31_60': count31_60,
        'bracket_61_90': count61_90,
        'bracket_90_plus': count90plus,
        'by_customer_cdf': byCustomerCDF,
        'by_customer_usd': byCustomerUSD,
        'details': receivables,
      };
    } catch (e) {
      throw Exception('Erreur résumé créances: $e');
    }
  }
}
