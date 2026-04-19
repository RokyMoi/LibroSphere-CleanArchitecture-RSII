import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/analytics_tile.dart';
import '../widgets/recent_activity_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const LoadingView();
        }

        if (widget.viewModel.failure != null) {
          return ErrorView(
            message: widget.viewModel.failure!.message,
            onRetry: () => widget.viewModel.load(),
          );
        }

        final data = widget.viewModel.stats!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Container(
            decoration: BoxDecoration(
              color: desktopPrimaryLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Number of Users:',
                          value: data.totalUsers.toString(),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Total Sales:',
                          value: data.totalSales.toString(),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Total Profit:',
                          value: formatCurrency(data.totalProfit, 'USD'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Active Users:',
                          value: data.activeUsers.toString(),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Books / Authors:',
                          value: '${data.totalBooks} / ${data.totalAuthors}',
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: AnalyticsTile(
                          label: '30d Revenue:',
                          value: formatCurrency(data.revenueLast30Days, 'USD'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Reviews:',
                          value: data.totalReviews.toString(),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Wishlist Items:',
                          value: data.totalWishlistItems.toString(),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: AnalyticsTile(
                          label: 'Avg Book Price:',
                          value: formatCurrency(data.averageBookPrice, 'USD'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      child: RecentActivityList(items: data.recentActivity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
