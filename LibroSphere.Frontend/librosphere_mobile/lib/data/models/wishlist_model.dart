import 'json_helpers.dart';
import 'wishlist_item_model.dart';

class WishlistModel {
  WishlistModel({required this.id, required this.userId, required this.items});

  final String id;
  final String userId;
  final List<WishlistItemModel> items;

  factory WishlistModel.empty() => WishlistModel(
        id: '',
        userId: '',
        items: const <WishlistItemModel>[],
      );

  factory WishlistModel.fromJson(Map<String, dynamic> json) => WishlistModel(
        id: readString(json, ['wishlistId', 'WishlistId']),
        userId: readString(json, ['userId', 'UserId']),
        items: ((json['items'] as List?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(WishlistItemModel.fromJson)
            .toList(),
      );
}
