import '../../../../core/utils/json_readers.dart';

class AuthTokensModel {
  AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: readString(json, <String>['accessToken', 'AccessToken']),
      refreshToken: readString(
        json,
        <String>['refreshToken', 'RefreshToken'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
