import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:log_poc/view_timer_state.dart';
import 'package:log_poc/timer_controller.dart';

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
  ViewTimerState _currentState = ViewTimerState();
  late Timer _updater;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _updater = Timer.periodic(const Duration (milliseconds: 100), (timer) {
      setState(() {
        _currentState = TimerController.getViewTimerState();
      });
    });
  }

  @override
  void dispose() {
    _updater.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      TimerController.background(false);
    } else {
      TimerController.background(true);
    }

    if (state == AppLifecycleState.detached) {
      // exit(0);
    }
  }

  void _addTimer() {
    if (_controller.text.isNotEmpty) {
      var value = int.tryParse(_controller.text);
      if (value != null && value > 0) {
        _controller.clear();
        TimerController.addTimer(value);
      }
    }
  }

  void _playStopTimer() {
    TimerController.playStopTimer();
  }

  void _resetTimer() {
    TimerController.resetTimer();
  }

  void _clearTimer() {
    TimerController.clearTimer();
  }

  @override
  Widget build(BuildContext context) {
    // var logger = Logger();
    // logger.d("_MyHomePageState build");

    List<Widget> timersViews = [];
    
    TextStyle usedTextStyle = const TextStyle(
      color: Color.fromARGB(203, 216, 106, 98),
      fontSize: 30,
    );

    TextStyle freshTextStyle = const TextStyle(
      color: Color.fromARGB(207, 55, 117, 205),
      fontSize: 30,
    );

    TextStyle currentTextStyle = const TextStyle(
      color: Color.fromARGB(255, 55, 117, 205),
      fontSize: 35,
    );

    TextStyle currentTextStyleAfterDot = const TextStyle(
      color: Color.fromARGB(191, 55, 117, 205),
      fontSize: 15,
    );

    int boxWidth = 20;
    for (int i = 0; i < _currentState.timersValuesMs.length; i++)
    {
      bool used = _currentState.currentTimer >= 0 && i < _currentState.currentTimer || i == _currentState.currentTimer && _currentState.finished;
      bool current = i == _currentState.currentTimer && !used;
      timersViews.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: boxWidth / 1),
            Text(
              "${ _currentState.timersValuesMs[i] ~/ 1000 }",
              style: current ? currentTextStyle : used ? usedTextStyle : freshTextStyle,
            ),
            SizedBox(
              width: boxWidth / 1,
              child: Align(
                alignment: Alignment.bottomLeft, // Элемент будет внизу по центру
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: current && _currentState.timersValuesMs[i] % 1000 > 0 ? [
                    Text(
                      ".${ _currentState.timersValuesMs[i] % 1000 ~/ 100 }",
                      style: currentTextStyleAfterDot,
                    ),
                  ] : []
                ),
              ),
            ),
          ]
        )
      );
    }

    bool withScroll = timersViews.length > 5;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("збс"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            withScroll ?
            Padding(
              padding: const EdgeInsets.all(10.0), // Adds padding on all sides
              child: SizedBox(
                width: 300,
                height: 300,
                child: Container(
                  color: const Color.fromARGB(171, 184, 206, 234), // Set background color here
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: timersViews
                    ),
                  ),
                ),
              ),
            )
            :
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
        )
      ),
    );
  }
}
