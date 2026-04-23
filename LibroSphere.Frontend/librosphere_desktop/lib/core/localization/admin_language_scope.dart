import 'package:flutter/material.dart';

import 'admin_language_controller.dart';

class AdminLanguageScope extends InheritedNotifier<AdminLanguageController> {
  const AdminLanguageScope({
    super.key,
    required AdminLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminLanguageController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminLanguageScope>();
    assert(scope != null, 'AdminLanguageScope not found in widget tree.');
    return scope!.notifier!;
  }

  static AdminLanguage languageOf(BuildContext context) {
    return controllerOf(context).language;
  }
}

extension AdminLanguageContextX on BuildContext {
  AdminLanguage get adminLanguage => AdminLanguageScope.languageOf(this);

  bool get isEnglish => adminLanguage.isEnglish;

  String tr({
    required String english,
    required String bosnian,
  }) {
    return isEnglish ? english : bosnian;
  }
}
