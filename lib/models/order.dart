class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      status: json['order_status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'CDF',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class OrderItem {
  final String productId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toInsertJson(String orderId) {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }
}
