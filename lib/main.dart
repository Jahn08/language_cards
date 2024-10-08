import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:language_cards/src/app.dart';

void main() {
  runZonedGuarded(() async {
    await SentryFlutter.init((_) {});
    runApp(const App());
  }, (error, stack) async {
    debugPrint('Uncaught Error: $error\nError Stack: $stack');
    await Sentry.captureException(error, stackTrace: stack);
  });
}
