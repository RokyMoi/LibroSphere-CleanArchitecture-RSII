import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AdminLanguage { bosnian, english }

extension AdminLanguageX on AdminLanguage {
  String get storageValue => switch (this) {
        AdminLanguage.bosnian => 'bosnian',
        AdminLanguage.english => 'english',
      };

  String get label => switch (this) {
        AdminLanguage.bosnian => 'BOSANSKI',
        AdminLanguage.english => 'ENGLISH',
      };

  bool get isBosnian => this == AdminLanguage.bosnian;
  bool get isEnglish => this == AdminLanguage.english;

  static AdminLanguage fromStorageValue(String? value) {
    return value == 'bosnian' ? AdminLanguage.bosnian : AdminLanguage.english;
  }
}

class AdminLanguageController extends ChangeNotifier {
  static const _storageKey = 'adminDesktopLanguage';

  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsFuture;

  AdminLanguage _language = AdminLanguage.english;
  AdminLanguage get language => _language;

  Future<void> initialize() async {
    final prefs = await _getPrefs();
    _language = AdminLanguageX.fromStorageValue(prefs.getString(_storageKey));
    notifyListeners();
  }

  Future<void> setLanguage(AdminLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    notifyListeners();

    final prefs = await _getPrefs();
    await prefs.setString(_storageKey, language.storageValue);
  }

  Future<SharedPreferences> _getPrefs() {
    final existing = _prefs;
    if (existing != null) {
      return Future<SharedPreferences>.value(existing);
    }

    final future =
        _prefsFuture ??= SharedPreferences.getInstance().then((prefs) {
          _prefs = prefs;
          return prefs;
        });
    return future;
  }
}
