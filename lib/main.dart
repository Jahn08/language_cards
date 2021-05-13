import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import './src/app.dart';

void main() async {
	await SentryFlutter.init(
		(options) { },
		appRunner: () => runApp(App())
	);
}
