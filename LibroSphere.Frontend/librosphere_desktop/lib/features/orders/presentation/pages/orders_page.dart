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
  static const _statusValues = [
    _allStatusValue,
    'Pending',
    'PaymentReceived',
    'PaymentFailed',
    'Refunded',
  ];

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
          items: _statusValues
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
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
                  flex: 1,
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
                return _OrderRow(order: order);
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

  String _statusLabel(String status) {
    return switch (status) {
      _allStatusValue => context.tr(english: 'All', bosnian: 'Sve'),
      'Pending' => context.tr(english: 'Pending', bosnian: 'Na cekanju'),
      'PaymentReceived' => context.tr(
          english: 'Payment Received',
          bosnian: 'Uplata primljena',
        ),
      'PaymentFailed' => context.tr(
          english: 'Payment Failed',
          bosnian: 'Uplata neuspjesna',
        ),
      'Refunded' => context.tr(english: 'Refunded', bosnian: 'Refundirano'),
      _ => status,
    };
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final AdminOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(order.buyerEmail)),
          Expanded(
            flex: 1,
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
        ],
      ),
    );
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
        _statusLabel(context),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'paymentreceived':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.blue;
      case 'paymentfailed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _normalizeStatus(String status) =>
      status.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

  String _statusLabel(BuildContext context) {
    return switch (_normalizeStatus(status)) {
      'paymentreceived' => context.tr(
          english: 'Payment Received',
          bosnian: 'Uplata primljena',
        ),
      'pending' => context.tr(english: 'Pending', bosnian: 'Na cekanju'),
      'refunded' => context.tr(english: 'Refunded', bosnian: 'Refundirano'),
      'paymentfailed' => context.tr(
          english: 'Payment Failed',
          bosnian: 'Uplata neuspjesna',
        ),
      _ => status,
    };
  }
}
