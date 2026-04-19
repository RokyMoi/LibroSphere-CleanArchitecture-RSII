import 'auth_tokens_model.dart';
import 'auth_user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.tokens,
    required this.user,
  });

  final AuthTokensModel tokens;
  final AuthUserModel user;
}
