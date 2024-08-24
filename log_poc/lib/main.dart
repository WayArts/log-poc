import 'dart:async';
// import 'dart:io';
// import 'dart:ui';

// import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:log_poc/ui.dart';
// import 'package:log_poc/notifications.dart';
import 'package:log_poc/timer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.init();

  await TimerController.init();

  runApp(const MyApp());
}
