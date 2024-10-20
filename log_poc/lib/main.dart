import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import './stress_component.dart';

void main() {
  runApp(const MyApp());
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
  Timer? _timer;
  final List<int> _timersSizes = [];
  List<int> _timersValues = [];
  int _currentTimer = -1;
  final TextEditingController _controller = TextEditingController();
  bool _playing = false;
  bool _finished = false;
  bool _addedNewAfterFinish = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final StressWidget _stressWidget = const StressWidget();

  @override
  void dispose() {
    _dropTimer();
    super.dispose();
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

  void _timerEndNotify()
  {
    _audioPlayer.play(AssetSource('TimerEnded.mp3'), volume: 0.7);
  }

  void _timerFinished()
  {
    _playStopTimer();
    _audioPlayer.play(AssetSource('TimersFinised.mp3'), volume: 1);
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

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.timer)),
                Tab(icon: Icon(Icons.monitor_heart_rounded)),
              ],
            ),
            title: const Text('Sasha Human utility'),
          ),
          body: TabBarView(
            children: [
              Center(
                child : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(
                          width: 50,
                        ),
                        SizedBox(
                          width: 300,
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
              Center(
                child : _stressWidget
              ),
            ],
          ),
        ),
      );
  }
}
