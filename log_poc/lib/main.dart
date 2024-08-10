import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

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
  List<int> _timersSizes = [];
  List<int> _timersValues = [];
  int _currentTimer = -1;
  final TextEditingController _controller = TextEditingController();
  bool _playing = false;

  void _addTimer() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        var value = int.tryParse(_controller.text);
        if (value != null && value > 0) {
          _timersSizes.add(value);
          _timersValues.add(value);
          _controller.clear();
        }
      }
    });
  }

  void _playStopTimer() {
    setState(() {
      _playing = !_playing;
      
    });
  }

  void _resetTimer() {
    setState(() {
      _timersSizes.clear();
      _timersValues.clear();
      _playing = false;
      _currentTimer = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    var logger = Logger();
    logger.d("_MyHomePageState build");

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
              ]
            ),
          ],
        ),
      ),
    );
  }
}
