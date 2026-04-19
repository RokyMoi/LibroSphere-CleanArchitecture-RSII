import '../../../../core/utils/json_readers.dart';
import 'analytics_activity_model.dart';

class DashboardStatsModel {
  DashboardStatsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalReviews,
    required this.totalWishlistItems,
    required this.totalSales,
    required this.totalProfit,
    required this.totalBooks,
    required this.totalAuthors,
    required this.averageBookPrice,
    required this.revenueLast30Days,
    required this.recentActivity,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalReviews;
  final int totalWishlistItems;
  final int totalSales;
  final double totalProfit;
  final int totalBooks;
  final int totalAuthors;
  final double averageBookPrice;
  final double revenueLast30Days;
  final List<AnalyticsActivityModel> recentActivity;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final commerce =
        (json['commerce'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final engagement =
        (json['engagement'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final catalog =
        (json['catalog'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    return DashboardStatsModel(
      totalUsers: (engagement['totalUsers'] as num?)?.toInt() ?? 0,
      activeUsers: (engagement['activeUsers'] as num?)?.toInt() ?? 0,
      totalReviews: (engagement['totalReviews'] as num?)?.toInt() ?? 0,
      totalWishlistItems:
          (engagement['totalWishlistItems'] as num?)?.toInt() ?? 0,
      totalSales: (commerce['paidOrders'] as num?)?.toInt() ?? 0,
      totalProfit: (commerce['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalBooks: (catalog['totalBooks'] as num?)?.toInt() ?? 0,
      totalAuthors: (catalog['totalAuthors'] as num?)?.toInt() ?? 0,
      averageBookPrice: readDouble(catalog, <String>['averageBookPrice']),
      revenueLast30Days: readDouble(commerce, <String>['revenueLast30Days']),
      recentActivity: ((json['recentActivity'] as List?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsActivityModel.fromJson)
          .toList(),
    );
  }
}
