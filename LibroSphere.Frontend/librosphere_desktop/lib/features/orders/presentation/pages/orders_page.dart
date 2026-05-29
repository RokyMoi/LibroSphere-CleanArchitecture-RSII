import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/admin_language_scope.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../data/models/admin_order_model.dart';
import '../viewmodels/orders_viewmodel.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.viewModel});

  final OrdersViewModel viewModel;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _allStatusValue = 'All';

  @override
  void initState() {
    super.initState();
    widget.viewModel.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;

        if (viewModel.isLoading && viewModel.orders.isEmpty) {
          return const LoadingView();
        }

        if (viewModel.failure != null && viewModel.orders.isEmpty) {
          return ErrorView(
            message: viewModel.failure!.message,
            onRetry: () => viewModel.load(),
          );
        }

        return AdminPanel(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(viewModel),
              const SizedBox(height: 24),
              _buildFilters(viewModel),
              const SizedBox(height: 16),
              Expanded(
                child: viewModel.orders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersTable(viewModel),
              ),
              if (viewModel.orders.isNotEmpty) _buildPagination(viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OrdersViewModel viewModel) {
    return Row(
      children: [
        Text(
          context.tr(
            english: 'Orders Management',
            bosnian: 'Upravljanje narudzbama',
          ),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          context.tr(
            english: '${viewModel.totalCount} orders total',
            bosnian: 'Ukupno narudzbi: ${viewModel.totalCount}',
          ),
          style: const TextStyle(
            fontSize: 14,
            color: desktopMutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(OrdersViewModel viewModel) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr(
                english: 'Search by buyer email...',
                bosnian: 'Pretrazi po emailu kupca...',
              ),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onSubmitted: (value) => viewModel.search(value),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: viewModel.statusFilter ?? _allStatusValue,
          hint: Text(
            context.tr(
              english: 'Filter by status',
              bosnian: 'Filtriraj po statusu',
            ),
          ),
          items: viewModel.availableStatuses
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(context, status)),
                  ))
              .toList(),
          onChanged: (value) => viewModel.filterByStatus(value),
        ),
        const Spacer(),
        if (viewModel.isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: desktopMutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(
              english: 'No orders found',
              bosnian: 'Nema pronadjenih narudzbi',
            ),
            style: const TextStyle(
              fontSize: 18,
              color: desktopMutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(OrdersViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: desktopPrimaryLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    context.tr(english: 'Buyer Email', bosnian: 'Email kupca'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr(english: 'Status', bosnian: 'Status'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    context.tr(english: 'Total', bosnian: 'Ukupno'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    context.tr(english: 'Items', bosnian: 'Stavke'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr(english: 'Date', bosnian: 'Datum'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                // Actions column header — only meaningful for RefundRequested rows
                const Expanded(flex: 2, child: SizedBox.shrink()),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: viewModel.orders.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = viewModel.orders[index];
                return _OrderRow(
                  order: order,
                  isActionsDisabled: viewModel.isLoading,
                  onApprove: order.isRefundRequested
                      ? () => _handleApprove(context, viewModel, order)
                      : null,
                  onReject: order.isRefundRequested
                      ? () => _handleReject(context, viewModel, order)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(OrdersViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: viewModel.hasPreviousPage
                ? () => viewModel.goToPage(viewModel.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 16),
          Text(
            context.tr(
              english: 'Page ${viewModel.currentPage} of ${viewModel.totalPages}',
              bosnian: 'Stranica ${viewModel.currentPage} od ${viewModel.totalPages}',
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: viewModel.hasNextPage
                ? () => viewModel.goToPage(viewModel.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(BuildContext context, String status) {
    return switch (status) {
      _allStatusValue => context.tr(english: 'All', bosnian: 'Sve'),
      'Pending' => context.tr(english: 'Pending', bosnian: 'Na cekanju'),
      'PaymentReceived' =>
        context.tr(english: 'Payment Received', bosnian: 'Uplata primljena'),
      'PaymentFailed' =>
        context.tr(english: 'Payment Failed', bosnian: 'Uplata neuspjesna'),
      'Refunded' => context.tr(english: 'Refunded', bosnian: 'Refundirano'),
      'PartiallyRefunded' =>
        context.tr(english: 'Partially Refunded', bosnian: 'Djelimicno refundirano'),
      'RefundRequested' =>
        context.tr(english: 'Refund Pending', bosnian: 'Refund na cekanju'),
      'RefundRejected' =>
        context.tr(english: 'Refund Rejected', bosnian: 'Refund odbijen'),
      _ => status,
    };
  }

  Future<void> _handleApprove(
    BuildContext context,
    OrdersViewModel viewModel,
    AdminOrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr(english: 'Approve Refund', bosnian: 'Odobri refund')),
        content: Text(context.tr(
          english:
              'Approve refund for order ${order.id.substring(0, 8)}?\nThis will trigger a Stripe refund of ${order.totalAmount.toStringAsFixed(2)} ${order.displayCurrency}.',
          bosnian:
              'Odobri refund za narudzbu ${order.id.substring(0, 8)}?\nOvo ce pokrenuti Stripe refund od ${order.totalAmount.toStringAsFixed(2)} ${order.displayCurrency}.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(english: 'Cancel', bosnian: 'Otkazi')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr(english: 'Approve', bosnian: 'Odobri')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await viewModel.approveRefund(order.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? context.tr(english: 'Refund approved successfully.', bosnian: 'Refund uspjesno odobren.')
          : viewModel.failure?.message ?? 'Failed to approve refund.'),
      backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
    ));
  }

  Future<void> _handleReject(
    BuildContext context,
    OrdersViewModel viewModel,
    AdminOrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr(english: 'Reject Refund', bosnian: 'Odbij refund')),
        content: Text(context.tr(
          english:
              'Reject refund request for order ${order.id.substring(0, 8)}? The user will be notified.',
          bosnian:
              'Odbij zahtjev za refund narudzbe ${order.id.substring(0, 8)}? Korisnik ce biti obavijesten.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(english: 'Cancel', bosnian: 'Otkazi')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr(english: 'Reject', bosnian: 'Odbij')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await viewModel.rejectRefund(order.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? context.tr(english: 'Refund request rejected.', bosnian: 'Zahtjev za refund odbijen.')
          : viewModel.failure?.message ?? 'Failed to reject refund.'),
      backgroundColor: success ? Colors.orange.shade700 : Colors.red.shade700,
    ));
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    this.onApprove,
    this.onReject,
    this.isActionsDisabled = false,
  });

  final AdminOrderModel order;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isActionsDisabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(order.buyerEmail)),
          Expanded(
            flex: 2,
            child: _StatusBadge(status: order.status),
          ),
          Expanded(
            flex: 1,
            child: Text(formatCurrency(order.totalAmount, order.displayCurrency)),
          ),
          Expanded(
            flex: 1,
            child: Text(order.itemCount.toString()),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatAdminDateTime(
                order.createdOnUtc,
                language: context.adminLanguage,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: order.isRefundRequested
                ? Row(
                    children: [
                      _ActionButton(
                        label: context.tr(english: 'Approve', bosnian: 'Odobri'),
                        color: Colors.green.shade700,
                        onPressed: isActionsDisabled ? null : onApprove,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: context.tr(english: 'Reject', bosnian: 'Odbij'),
                        color: Colors.red.shade700,
                        onPressed: isActionsDisabled ? null : onReject,
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

  @override
  Widget build(BuildContext context) {
    final color = _color(_normalize(status));
    final label = _label(context, _normalize(status));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Color _color(String normalized) => switch (normalized) {
        'paymentreceived' => Colors.green,
        'pending' => Colors.orange,
        'refunded' || 'partiallyrefunded' => Colors.blue,
        'paymentfailed' => Colors.red,
        'refundrequested' => const Color(0xFFF59E0B),
        'refundrejected' => Colors.red.shade800,
        _ => Colors.grey,
      };

  static String _label(BuildContext context, String normalized) =>
      switch (normalized) {
        'paymentreceived' =>
          context.tr(english: 'Payment Received', bosnian: 'Uplata primljena'),
        'pending' => context.tr(english: 'Pending', bosnian: 'Na cekanju'),
        'refunded' => context.tr(english: 'Refunded', bosnian: 'Refundirano'),
        'partiallyrefunded' =>
          context.tr(english: 'Partially Refunded', bosnian: 'Djelimicno refundirano'),
        'paymentfailed' =>
          context.tr(english: 'Payment Failed', bosnian: 'Uplata neuspjesna'),
        'refundrequested' =>
          context.tr(english: 'Refund Pending', bosnian: 'Refund na cekanju'),
        'refundrejected' =>
          context.tr(english: 'Refund Rejected', bosnian: 'Refund odbijen'),
        _ => normalized,
      };
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: onPressed != null ? color : Colors.grey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: onPressed != null ? color : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onPressed != null ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
