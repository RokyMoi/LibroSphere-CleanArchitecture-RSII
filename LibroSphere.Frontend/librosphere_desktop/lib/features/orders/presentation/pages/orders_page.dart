import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../viewmodels/orders_viewmodel.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.viewModel});

  final OrdersViewModel viewModel;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
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
        const Text(
          'Orders Management',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          '${viewModel.totalCount} orders total',
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
            decoration: const InputDecoration(
              hintText: 'Search by buyer email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (value) => viewModel.search(value),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: viewModel.statusFilter ?? 'All',
          hint: const Text('Filter by status'),
          items: viewModel.availableStatuses
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: desktopMutedForeground),
          SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
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
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Buyer Email', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
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
                  isRefunding: viewModel.refundingOrderId == order.id,
                  onRefund: () => _showRefundDialog(context, viewModel, order.id),
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
            'Page ${viewModel.currentPage} of ${viewModel.totalPages}',
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

  Future<void> _showRefundDialog(BuildContext context, OrdersViewModel viewModel, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Order'),
        content: const Text('Are you sure you want to refund this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.refundOrder(orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Order refunded successfully' : 'Failed to refund order'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.isRefunding,
    required this.onRefund,
  });

  final dynamic order;
  final bool isRefunding;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_shortId(order.id))),
          Expanded(flex: 2, child: Text(order.buyerEmail)),
          Expanded(
            flex: 1,
            child: _StatusBadge(status: order.status),
          ),
          Expanded(
            flex: 1,
            child: Text('${order.totalAmount.toStringAsFixed(2)} ${order.currency}'),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatDate(order.createdOnUtc)),
          ),
          Expanded(
            flex: 1,
            child: order.status == 'PaymentReceived'
                ? ElevatedButton(
                    onPressed: isRefunding ? null : onRefund,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: isRefunding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Refund'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8).toUpperCase();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = _monthName(local.month);
    return '$month ${local.day}, ${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PaymentReceived':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Refunded':
        return Colors.blue;
      case 'PaymentFailed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
