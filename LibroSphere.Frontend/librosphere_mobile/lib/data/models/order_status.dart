enum OrderStatus {
  pending,
  paymentReceived,
  paymentFailed,
  refunded,
  partiallyRefunded,
  refundRequested,
  refundRejected,
  unknown,
}

OrderStatus parseOrderStatus(dynamic raw) {
  if (raw is num) {
    return switch (raw.toInt()) {
      0 => OrderStatus.pending,
      1 => OrderStatus.paymentReceived,
      2 => OrderStatus.paymentFailed,
      3 => OrderStatus.refunded,
      4 => OrderStatus.partiallyRefunded,
      5 => OrderStatus.refundRequested,
      6 => OrderStatus.refundRejected,
      _ => OrderStatus.unknown,
    };
  }

  final text = raw?.toString().toLowerCase() ?? '';
  if (text.contains('refundrequested') || text == 'refund_requested') return OrderStatus.refundRequested;
  if (text.contains('refundrejected') || text == 'refund_rejected') return OrderStatus.refundRejected;
  if (text.contains('partiallyrefunded') || text == 'partially_refunded') return OrderStatus.partiallyRefunded;
  if (text.contains('paymentreceived')) return OrderStatus.paymentReceived;
  if (text.contains('paymentfailed')) return OrderStatus.paymentFailed;
  if (text.contains('refunded')) return OrderStatus.refunded;
  if (text.contains('pending')) return OrderStatus.pending;
  return OrderStatus.unknown;
}
