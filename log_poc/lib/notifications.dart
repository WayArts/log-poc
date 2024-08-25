import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

enum NotificationSounds {
  timerEnded,
  timersFinised
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> _onDidReceiveNotification(NotificationResponse notificationResponse) async {
    print("Notification receive");
  }

  static Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveNotification,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  }

  static Future<void> showInstantNotification(String title, String body) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notification_channel_id',
          'Instant Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails());

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'instant_notification',
    );
  }

  static String? _getFileNameFromEnumAndroid(NotificationSounds? sound) {
    switch (sound) {
      case NotificationSounds.timerEnded:
      return "timer_ended";
      case NotificationSounds.timersFinised:
      return "timers_finised";
      default:
      return null;
    }
  }

  static String? _getFileNameFromEnumIOS(NotificationSounds? sound) {
    switch (sound) {
      case NotificationSounds.timerEnded:
      return "TimerEnded.wav";
      case NotificationSounds.timersFinised:
      return "TimersFinised.wav";
      default:
      return null;
    }
  }

  static Future<void> scheduleNotification(int id, String title, String body, tz.TZDateTime scheduledTime, { NotificationSounds? sound }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      // tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3)),
      scheduledTime,
      // tz.TZDateTime.from(DateTime.now().add(const Duration(seconds: 10)), tz.local),
      NotificationDetails(
        iOS: DarwinNotificationDetails(sound: _getFileNameFromEnumIOS(sound)),
        android:
        AndroidNotificationDetails(
          'logpoc_channel',
          'Log poc Channel',
          channelDescription: 'Log poc Channel',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(_getFileNameFromEnumAndroid(sound)),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancelAllScheduledMessages() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> cancelScheduledMessages(List<int> notificationIds) async {
    for (var id in notificationIds) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }
}