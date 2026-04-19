enum OrderStatus { pending, paymentReceived, paymentFailed, unknown }

OrderStatus parseOrderStatus(dynamic raw) {
  if (raw is num) {
    switch (raw.toInt()) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.paymentReceived;
      case 2:
        return OrderStatus.paymentFailed;
      default:
        return OrderStatus.unknown;
    }
  }

  final text = raw?.toString().toLowerCase() ?? '';
  if (text.contains('paymentreceived')) return OrderStatus.paymentReceived;
  if (text.contains('paymentfailed')) return OrderStatus.paymentFailed;
  if (text.contains('pending')) return OrderStatus.pending;
  return OrderStatus.unknown;
}
