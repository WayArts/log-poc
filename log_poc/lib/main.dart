import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:device_info_plus/device_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const notificationChannelId = "my_foreground";

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
      foregroundServiceType: AndroidForegroundType.mediaPlayback,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  final player = TimerPlayer();

  await player.initState(service);

  service.on(BackgroundEvents.closeApp).listen((event) async {
    await player.dispose();
    service.stopSelf();
  });
}

class BackgroundEvents {
  static const stateUpdated = "stateUpdated";
  static const addTimer = "addTimer";
  static const playStopTimer = "playStopTimer";
  static const resetTimer = "resetTimer";
  static const clearTimer = "clearTimer";
  static const closeApp = "closeApp";
}

class TimerState {
  List<int> timersSizes = [];
  List<int> timersValues = [];
  int currentTimer = -1;
  bool playing = false;
  bool finished = false;
  bool addedNewAfterFinish = false;

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

class TimerPlayer {
  Timer? timer;
  final timerEndedPlayer = AudioPlayer();
  final timersFinisedPlayer = AudioPlayer();
  ServiceInstance? service;
  TimerState state = TimerState();

  Future<void> initState(ServiceInstance service) async {
    this.service = service;
    state = TimerState();

    service.on(BackgroundEvents.addTimer).listen((data) {
      if (data == null)
      {
        return;
      }
      
      addTimer(data["value"]);
    });

    service.on(BackgroundEvents.clearTimer).listen((data) {
      clearTimer();
    });

    service.on(BackgroundEvents.playStopTimer).listen((data) {
      playStopTimer();
    });

    service.on(BackgroundEvents.resetTimer).listen((data) {
      resetTimer();
    });
    
    await timerEndedPlayer.setAsset('assets/TimerEnded.mp3');
    await timerEndedPlayer.setVolume(0.7);
    await timersFinisedPlayer.setAsset('assets/TimersFinised.mp3');
  }

  Future<void> dispose() async {
    await dropTimer();
    await timerEndedPlayer.dispose();
    await timersFinisedPlayer.dispose();
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
    await timerEndedPlayer.stop();
    await timerEndedPlayer.seek(Duration.zero);
    await timerEndedPlayer.play();
  }

  Future<void> timerFinished() async {    
    await timersFinisedPlayer.stop();
    await timersFinisedPlayer.seek(Duration.zero);
    await timersFinisedPlayer.play();
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
        timerEndNotify();
        state.currentTimer++;
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  TimerState _currentState = TimerState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FlutterBackgroundService().on(BackgroundEvents.stateUpdated).listen((data) {
      if (data == null) {
        return;
      }
      setState(() {
        _currentState = TimerState.fromJson(data);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      exit(0);
    }
  }

  void _addTimer() {
    if (_controller.text.isNotEmpty) {
      var value = int.tryParse(_controller.text);
      if (value != null && value > 0) {
        FlutterBackgroundService().invoke(BackgroundEvents.addTimer, { "value": value });
        _controller.clear();
      }
    }
  }

  void _playStopTimer() {
    FlutterBackgroundService().invoke(BackgroundEvents.playStopTimer);
  }

  void _resetTimer() {
    FlutterBackgroundService().invoke(BackgroundEvents.resetTimer);
  }

  void _clearTimer() {
    FlutterBackgroundService().invoke(BackgroundEvents.clearTimer);
  }

  @override
  Widget build(BuildContext context) {
    // var logger = Logger();
    // logger.d("_MyHomePageState build");

    List<Text> timersViews = [];
    
    TextStyle usedTextStyle = const TextStyle(
      color: Color.fromARGB(255, 216, 106, 98),
      fontSize: 30,
    );

    TextStyle freshTextStyle = const TextStyle(
      color: Color.fromARGB(255, 55, 117, 205),
      fontSize: 30,
    );

    for (int i = 0; i < _currentState.timersValues.length; i++)
    {
      bool used = _currentState.currentTimer >= 0 && i <= _currentState.currentTimer;
      timersViews.add(
        Text(
          _currentState.timersValues[i].toString(),
          style: used ? usedTextStyle : freshTextStyle,
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Таймер Маме"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 50,
                ),
                SizedBox(
                  width: 225,
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter number of secconds',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                FloatingActionButton(
                  onPressed: _addTimer,
                  tooltip: 'addTimer',
                  child: const Icon(Icons.add),
                ),
              ]
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: timersViews
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: _playStopTimer,
                  tooltip: 'playStopTimer',
                  child: Icon(_currentState.playing ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(
                  width: 25,
                ),
                FloatingActionButton(
                  onPressed: _resetTimer,
                  tooltip: 'resetTimer',
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(
                  width: 25,
                ),
                FloatingActionButton(
                  onPressed: _clearTimer,
                  tooltip: 'clearTimer',
                  child: const Icon(Icons.clear),
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }
}
