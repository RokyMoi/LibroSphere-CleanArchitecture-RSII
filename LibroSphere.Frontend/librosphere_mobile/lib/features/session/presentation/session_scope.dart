import 'package:flutter/material.dart';

import 'viewmodels/session_viewmodel.dart';

class SessionScope extends InheritedNotifier<SessionViewModel> {
  const SessionScope({
    super.key,
    required SessionViewModel session,
    required super.child,
  }) : super(notifier: session);

  static SessionViewModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope not found in widget tree.');
    return scope!.notifier!;
  }

  static SessionViewModel read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<SessionScope>();
    final scope = element?.widget as SessionScope?;
    assert(scope != null, 'SessionScope not found in widget tree.');
    return scope!.notifier!;
  }
}

extension SessionScopeContext on BuildContext {
  SessionViewModel get session => SessionScope.of(this);
}
