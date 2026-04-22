enum OrderStatus { pending, paymentReceived, paymentFailed, refunded, unknown }

OrderStatus parseOrderStatus(dynamic raw) {
  if (raw is num) {
    switch (raw.toInt()) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.paymentReceived;
      case 2:
        return OrderStatus.paymentFailed;
      case 3:
        return OrderStatus.refunded;
      default:
        return OrderStatus.unknown;
    }
  }

  final text = raw?.toString().toLowerCase() ?? '';
  if (text.contains('paymentreceived')) return OrderStatus.paymentReceived;
  if (text.contains('paymentfailed')) return OrderStatus.paymentFailed;
  if (text.contains('refunded')) return OrderStatus.refunded;
  if (text.contains('pending')) return OrderStatus.pending;
  return OrderStatus.unknown;
}
