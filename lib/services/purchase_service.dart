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
              '*, suppliers(company_name), purchase_items(*, products(name, sku))')
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
    double exchangeRate = 1,
    String? notes,
  }) async {
    try {
      double totalAmount = 0;
      for (final item in items) {
        totalAmount += (item['quantity'] as num) * (item['unit_cost'] as num);
      }

      final purchase = await _client
          .from('purchases')
          .insert({
            'supplier_id': supplierId,
            'total_amount': totalAmount,
            'currency': currency,
            'exchange_rate': exchangeRate,
            'status': 'pending',
            'payment_status': 'pending',
            'created_by': _client.auth.currentUser?.id,
            'received_by': _client.auth.currentUser?.id,
            if (notes != null) 'notes': notes,
          })
          .select()
          .single();

      for (final item in items) {
        await _client.from('purchase_items').insert({
          'purchase_id': purchase['id'],
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit_cost': item['unit_cost'],
          'total_cost': (item['quantity'] as num) * (item['unit_cost'] as num),
        });
      }

      return purchase;
    } catch (e) {
      throw Exception('Erreur création achat: $e');
    }
  }

  Future<Map<String, dynamic>> updatePurchaseStatus(
      String id, String status) async {
    try {
      return await _client
          .from('purchases')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
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
