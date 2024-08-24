import 'package:log_poc/notifications.dart';

class TimerState {
  // in milliseconds since epoch, 0 means didn't start
  int startMoment = 0;

  // in milliseconds, updated after timer pauses or finishes
  int passedBeforeStart = 0;
  
  // in seconds
  List<int> timersSizes = [];
  
  // updated after start
  List<int> notificationIds = [];

  TimerState();

  TimerState.init(
    this.timersSizes,
    this.timersValues,
    this.currentTimer,
    this.playing,
    this.finished,
    this.addedNewAfterFinish
  );

  TimerState.fromJson(Map<String, dynamic> data)
  {
    timersSizes = List.from(data['timersSizes']);
    timersValues = List.from(data['timersValues']);
    currentTimer = data['currentTimer'];
    playing = data['playing'];
    finished = data['finished'];
    addedNewAfterFinish = data['addedNewAfterFinish'];
  }

  Map<String, dynamic> toJson() {
    return {
      'timersSizes': timersSizes,
      'timersValues': timersValues,
      'currentTimer': currentTimer,
      'playing': playing,
      'finished': finished,
      'addedNewAfterFinish': addedNewAfterFinish,
    };
  }
}

class TimerController {
  bool inited = false;
  
  TimerState state = TimerState();
  static Future<void> init() async {
    state = TimerState();

    inited = true;
  }

  Future<void> dropTimer() async {
    timer?.cancel();
    timer = null;
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateTimer();
    });
  }

  Future<void> timerEndNotify() async {
    await player.stop();
    await player.setAsset(
      'assets/TimerEnded.mp3',
      tag: const MediaItem(id: "1", title: "timer ended")
    );
    await player.setVolume(0.7);
    await player.seek(Duration.zero);
    await player.play();
  }

  Future<void> timerFinished() async {
    await player.stop();
    await player.setAsset(
      'assets/TimersFinised.mp3',
      tag: const MediaItem(id: "2", title: "timer finished")
    );
    await player.setVolume(1);
    await player.seek(Duration.zero);
    await player.play();
  }

  Future<void> updateTimer() async {
    if (state.timersValues[state.currentTimer] > 0)
    {
      state.timersValues[state.currentTimer]--;
    }

    if (state.timersValues[state.currentTimer] == 0)
    {      
      if (state.currentTimer + 1 < state.timersSizes.length)
      {
        state.currentTimer++;
        timerEndNotify();
      } else {
        playStopTimer();
        state.finished = true;
        timerFinished();
      }
    }

    service?.invoke(BackgroundEvents.stateUpdated, state.toJson());
  }

  void addTimer(int value) {
    if (value > 0) {
      state.timersSizes.add(value);
      state.timersValues.add(value);
      if (state.finished) {
        state.addedNewAfterFinish = true;
      }
    }

    service?.invoke(BackgroundEvents.stateUpdated, state.toJson());
  }

  Future<void> playStopTimer() async {
    if (state.finished) {
      if (state.addedNewAfterFinish) {
        state.addedNewAfterFinish = false;
        state.finished = false;
        state.currentTimer++;
      } else {
        resetTimer();
      }
    }

    if (state.timersSizes.isEmpty) {
      return;
    }

    state.playing = !state.playing;

    if (state.playing) {
      if (state.currentTimer < 0) {
        state.currentTimer = 0;
      }
        
      startTimer();
    } else {
      dropTimer();
    }

    service?.invoke(BackgroundEvents.stateUpdated, state.toJson());
  }

  void resetTimer() {
    state.timersValues = List.from(state.timersSizes);
    state.playing = false;
    state.finished = false;
    state.addedNewAfterFinish = false;
    state.currentTimer = -1;
    dropTimer();

    service?.invoke(BackgroundEvents.stateUpdated, state.toJson());
  }

  void clearTimer() {
    state.timersSizes.clear();
    state.timersValues.clear();
    state.playing = false;
    state.finished = false;
    state.addedNewAfterFinish = false;
    state.currentTimer = -1;
    dropTimer();

    service?.invoke(BackgroundEvents.stateUpdated, state.toJson());
  }
}




class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {
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
      onDidReceiveNotificationResponse: onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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

  static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      timezone.TZDateTime.from(scheduledTime, timezone.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> scheduleTimerEnded(int secondsNumber, DateTime scheduledTime) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      "Timer ended",
      secondsNumber.toString(),
      timezone.TZDateTime.from(scheduledTime, timezone.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          sound: 'TimerEnded.wav'
        ),
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Channel',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('TimerEnded'),
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}