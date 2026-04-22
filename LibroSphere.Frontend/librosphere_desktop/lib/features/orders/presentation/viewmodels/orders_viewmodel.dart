import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/models/admin_order_model.dart';
import '../../data/models/orders_page_model.dart';
import '../../data/repositories/orders_repository.dart';

class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel(
    this._repository,
    this._token, {
    Future<void> Function()? onDataChanged,
  }) : _onDataChanged = onDataChanged;

  final OrdersRepository _repository;
  final String _token;
  final Future<void> Function()? _onDataChanged;
  final int pageSize = 12;
  bool _hasLoaded = false;

  bool isLoading = true;
  Failure? failure;
  String searchTerm = '';
  String? statusFilter;
  List<AdminOrderModel> orders = <AdminOrderModel>[];
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  bool hasPreviousPage = false;
  bool hasNextPage = false;

  List<String> get availableStatuses => [
    'All',
    'Pending',
    'PaymentReceived',
    'PaymentFailed',
    'Refunded',
  ];

  Future<void> ensureLoaded() async {
    if (_hasLoaded) return;
    await load();
  }

  Future<void> load() async {
    _setLoading(true);
    final result = await _repository.getAllOrders(
      token: _token,
      searchTerm: searchTerm.isEmpty ? null : searchTerm,
      status: statusFilter == 'All' || statusFilter == null ? null : statusFilter,
      page: currentPage,
      pageSize: pageSize,
    );
    _handleLoadResult(result);
  }

  Future<void> refresh() async {
    await load();
    await _onDataChanged?.call();
  }

  void search(String value) {
    searchTerm = value.trim();
    currentPage = 1;
    load();
  }

  void filterByStatus(String? status) {
    statusFilter = status;
    currentPage = 1;
    load();
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    currentPage = page;
    load();
  }

  void clearError() {
    if (failure == null) return;
    failure = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    failure = null;
    notifyListeners();
  }

  void _handleLoadResult(Result<OrdersPageModel> result) {
    switch (result) {
      case Success<OrdersPageModel>(value: final page):
        orders = page.orders;
        currentPage = page.page;
        totalPages = page.totalPages;
        totalCount = page.totalCount;
        hasPreviousPage = page.hasPreviousPage;
        hasNextPage = page.hasNextPage;
        isLoading = false;
        _hasLoaded = true;
        notifyListeners();
      case ErrorResult<OrdersPageModel>(failure: final f):
        failure = f is Failure ? f : Failure(message: f.toString());
        isLoading = false;
        notifyListeners();
    }
  }
}
