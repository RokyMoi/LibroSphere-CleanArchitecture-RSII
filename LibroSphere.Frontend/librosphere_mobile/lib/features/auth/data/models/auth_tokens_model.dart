import '../../../../data/models/json_helpers.dart';

class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) => AuthTokensModel(
        accessToken: readString(json, ['accessToken', 'AccessToken']),
        refreshToken: readString(json, ['refreshToken', 'RefreshToken']),
      );
}
