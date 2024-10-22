import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'heart_bpm_service.dart';

class StressWidget extends StatefulWidget {
  const StressWidget({super.key});

  @override
  State<StressWidget> createState() => _StressWidgetState();
}

const int _defaultStressBpm = 80;
const int _maxStressBpm = 250;

class _StressWidgetState extends State<StressWidget> {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _controller = TextEditingController();
  final HeartBpmService _bpmService = HeartBpmService();


  int _currentBpm = 0;
  int _stressBpm = _defaultStressBpm;
  bool _itIsStress = false;
  bool _connected = false;
  bool _connecting = false;

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
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        _updateBpm();
      });
    });
  }

  void _stressStartedNotify()
  {
    _audioPlayer.play(AssetSource('TimerEnded.mp3'), volume: 0.7);
  }

  void _stressFinishedNotify()
  {
    _audioPlayer.play(AssetSource('TimersFinised.mp3'), volume: 1);
  }

  void _updateBpm() {
    if (!_connected)
    {
      return;
    }

    int bpm = _bpmService.getBpm();
    _connected = bpm >= 0;

    if (_connected)
    {
      _currentBpm = bpm;
      bool itIsStress = _currentBpm < _stressBpm;

      if (_itIsStress != itIsStress)
      {
        if (itIsStress)
        {
          _stressStartedNotify();
        }
        else
        {
          _stressFinishedNotify();
        }

        _itIsStress = itIsStress;
      }
    }
  }

  void _setStressBpm() {
    setState(() {
      if (_controller.text.isEmpty)
      {
        _stressBpm = _defaultStressBpm;
      }
      else
      {
        var value = int.tryParse(_controller.text);
        if (value != null && value > 0) {
          _stressBpm = value > _maxStressBpm ? _maxStressBpm : value;
          _controller.clear();
        }
      }
    });
  }

  void _connect()
  {
    _connecting = true;

    setState(() {});
    () async {
      _connected = await _bpmService.connect();
      _connecting = false;
      setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    
    TextStyle stressTextStyle = const TextStyle(
      color: Color.fromARGB(255, 216, 106, 98),
      fontSize: 40,
    );

    TextStyle relaxTextStyle = const TextStyle(
      color: Color.fromARGB(255, 55, 117, 205),
      fontSize: 35,
    );

    return Column(
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
                decoration: InputDecoration(
                  labelText: 'enter stress BPM | current = $_stressBpm',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            FloatingActionButton(
              onPressed: _setStressBpm,
              tooltip: 'setStressBpm',
              child: const Icon(Icons.arrow_right_alt_rounded),
            ),
          ]
        ),
        const SizedBox(
          height: 30,
        ),
        Text(
          _connected ? _currentBpm.toString() : _connecting ? "..connecting.." : "disconnected",
          style: _itIsStress || !_connected && !_connecting ? stressTextStyle : relaxTextStyle,
        ),
        const SizedBox(
          height: 30,
        ),
        Visibility(       
          visible: !_connected && !_connecting,
          child:
          RawMaterialButton(
            onPressed: _connect,
            fillColor: const Color.fromARGB(255, 0, 0, 0),
            shape: const StadiumBorder(),
            constraints: const BoxConstraints.tightFor(
              width: 100,
              height: 20,
            ),
            child: const Text(
              "connect to device",
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 10,
              ),
            ),
          ),
          // FloatingActionButton(
          //   onPressed: _connect,
          //   tooltip: 'connect',
          //   child: const Text(
          //     "connect to device",
          //     style: TextStyle(
          //       color: Color.fromARGB(255, 0, 0, 0),
          //       fontSize: 10,
          //     ),
          //   ),
          // ),
        ),
      ],
    );
  }
}