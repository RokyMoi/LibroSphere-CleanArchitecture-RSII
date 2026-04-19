import 'json_helpers.dart';

class PagedResult<T> {
  PagedResult({
    required this.items,
    this.page = 1,
    this.pageSize = 0,
    this.totalCount = 0,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => pageSize > 0 && page * pageSize < totalCount;
  int get totalPages => pageSize <= 0 ? 1 : (totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize));

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parser) {
    final items = ((json['items'] as List?) ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList();
    return PagedResult<T>(
      items: items,
      page: readInt(json, ['page', 'Page']),
      pageSize: readInt(json, ['pageSize', 'PageSize']),
      totalCount: readInt(json, ['totalCount', 'TotalCount']),
    );
  }
}
