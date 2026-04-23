import 'package:flutter/material.dart';

import '../../../../core/localization/admin_language_controller.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/admin/admin_panel.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/analytics_tile.dart';
import '../widgets/recent_activity_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.viewModel,
    required this.languageController,
  });

  final DashboardViewModel viewModel;
  final AdminLanguageController languageController;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.viewModel,
        widget.languageController,
      ]),
      builder: (context, _) {
        final viewModel = widget.viewModel;
        final language = widget.languageController.language;

        if (viewModel.isLoading) {
          return const LoadingView();
        }

        if (viewModel.failure != null) {
          return ErrorView(
            message: viewModel.failure!.message,
            onRetry: () => viewModel.load(),
          );
        }

        final stats = viewModel.stats!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: AdminPanel(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                _DashboardRow(
                  items: [
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Number of Users:'
                          : 'Broj korisnika:',
                      value: stats.totalUsers.toString(),
                    ),
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Total Sales:'
                          : 'Ukupna prodaja:',
                      value: stats.totalSales.toString(),
                    ),
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Total Profit:'
                          : 'Ukupan profit:',
                      value: formatCurrency(stats.totalProfit, 'USD'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _DashboardRow(
                  items: [
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Active Users:'
                          : 'Aktivni korisnici:',
                      value: stats.activeUsers.toString(),
                    ),
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Books / Authors:'
                          : 'Knjige / Autori:',
                      value: '${stats.totalBooks} / ${stats.totalAuthors}',
                    ),
                    _DashboardTileData(
                      label: language.isEnglish
                          ? '30d Revenue:'
                          : 'Prihod 30d:',
                      value: formatCurrency(stats.revenueLast30Days, 'USD'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _DashboardRow(
                  items: [
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Reviews:'
                          : 'Recenzije:',
                      value: stats.totalReviews.toString(),
                    ),
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Wishlist Items:'
                          : 'Wishlist stavke:',
                      value: stats.totalWishlistItems.toString(),
                    ),
                    _DashboardTileData(
                      label: language.isEnglish
                          ? 'Avg Book Price:'
                          : 'Prosjecna cijena knjige:',
                      value: formatCurrency(stats.averageBookPrice, 'USD'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    language.isEnglish ? 'Recent Activity' : 'Nedavna aktivnost',
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
                    child: RecentActivityList(
                      items: stats.recentActivity,
                      language: language,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.items});

  final List<_DashboardTileData> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(
            child: AnalyticsTile(
              label: items[index].label,
              value: items[index].value,
            ),
          ),
          if (index < items.length - 1) const SizedBox(width: 22),
        ],
      ],
    );
  }
}

class _DashboardTileData {
  const _DashboardTileData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
