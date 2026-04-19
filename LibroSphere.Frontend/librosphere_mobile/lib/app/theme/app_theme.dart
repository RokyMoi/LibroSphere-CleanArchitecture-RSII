import 'package:flutter/material.dart';

import '../../core/app_constants.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: pageBackground,
    fontFamily: 'Segoe UI',
    colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
  );
}
