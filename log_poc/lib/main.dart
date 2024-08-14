import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Background Service',
      initialNotificationContent: 'Running background tasks',
      foregroundServiceNotificationId: 888,
      foregroundServiceType: AndroidForegroundType.mediaPlayback,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class BackgroundEvents {
  final onClose = 'onClose';
  final onStart = 'onStart';
  final onTimarTick = 'onTimarTick';

}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final player = TimerPlayer();

  player.initState(service);

  service.on(method)
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

  Map<String, dynamic> toJson() {
    return {
      'TimerState': this
    };
    // return {
    //   'timersSizes': timersSizes,
    // };
    // timersSizes,
    // this.timersValues,
    // this.currentTimer,
    // this.playing,
    // this.finished,
    // this.addedNewAfterFinish
  }
}

class TimerPlayer {
  Timer? _timer;
  final _timerEndedPlayer = AudioPlayer();
  final _timersFinisedPlayer = AudioPlayer();
  ServiceInstance? _service;

  void initState(ServiceInstance service) async {
    TimerState s = TimerState();
    s.addedNewAfterFinish;
    _service = service;
    () async {
      await _timerEndedPlayer.setAsset('assets/TimerEnded.mp3');
      await _timerEndedPlayer.setVolume(0.7);
      await _timersFinisedPlayer.setAsset('assets/TimersFinised.mp3');
    } ();
  }

  void dispose() {
    _dropTimer();
    _timerEndedPlayer.dispose();
    _timersFinisedPlayer.dispose();
  }

  void _dropTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _updateTimer();
      });
    });
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

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState()
  {
    super.initState();
    () async {
      await _timerEndedPlayer.setAsset('assets/TimerEnded.mp3');
      await _timerEndedPlayer.setVolume(0.7);
      await _timersFinisedPlayer.setAsset('assets/TimersFinised.mp3');
    } ();
  }

  @override
  void dispose() {
    _dropTimer();
    _timerEndedPlayer.dispose();
    _timersFinisedPlayer.dispose();
    super.dispose();
  }

  void _timerEndNotify()
  {
    () async {
      await _timerEndedPlayer.stop();
      await _timerEndedPlayer.seek(Duration.zero);
      await _timerEndedPlayer.play();
    } ();
  }

  void _timerFinished()
  {
    _playStopTimer();
    () async {
      await _timersFinisedPlayer.stop();
      await _timersFinisedPlayer.seek(Duration.zero);
      await _timersFinisedPlayer.play();
    } ();
    _finished = true;
  }

  void _updateTimer() {
    _timersValues[_currentTimer]--;

    if (_timersValues[_currentTimer] == 0)
    {      
      if (_currentTimer + 1 < _timersSizes.length)
      {
        _timerEndNotify();
        _currentTimer++;
      } else {
        _timerFinished();
      }
    }   
  }

  void _addTimer() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        var value = int.tryParse(_controller.text);
        if (value != null && value > 0) {
          _timersSizes.add(value);
          _timersValues.add(value);
          _controller.clear();
          if (_finished)
          {
            _addedNewAfterFinish = true;
          }
        }
      }
    });
  }

  void _playStopTimer() {
    setState(() {
      if (_finished)
      {
        if (_addedNewAfterFinish)
        {
          _addedNewAfterFinish = false;
          _finished = false;
          _currentTimer++;
        } else {
          _resetTimer();
        }
      }

      if (_timersSizes.isEmpty) {
        return;
      }

      _playing = !_playing;

      if (_playing) {
        if (_currentTimer < 0) {
          _currentTimer = 0;
        }
        
        _startTimer();
      } else {
        _dropTimer();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _timersValues = List.from(_timersSizes);
      _playing = false;
      _finished = false;
      _addedNewAfterFinish = false;
      _currentTimer = -1;
      _dropTimer();
    });
  }

  void _clearTimer() {
    setState(() {
      _timersSizes.clear();
      _timersValues.clear();
      _playing = false;
      _finished = false;
      _addedNewAfterFinish = false;
      _currentTimer = -1;
      _dropTimer();
    });
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

    for (int i = 0; i < _timersValues.length; i++)
    {
      bool used = _currentTimer >= 0 && i <= _currentTimer;
      timersViews.add(
        Text(
          _timersValues[i].toString(),
          style: used ? usedTextStyle : freshTextStyle,
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("збс"),
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
                  child: Icon(_playing ? Icons.pause : Icons.play_arrow),
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
