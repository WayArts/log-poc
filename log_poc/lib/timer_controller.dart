// import 'package:json_serializable/json_serializable.dart';
import 'package:localstore/localstore.dart';

import 'package:log_poc/notifications.dart';
import 'package:log_poc/view_timer_state.dart';
import 'package:timezone/timezone.dart' as tz;
 
class TimerState {
  /// Iso8601, "" means not playing
  String startMoment = "";

  /// in milliseconds, updated after timer pauses
  int passedBeforeStart = 0;
  
  /// in seconds
  List<int> timersSizes = [];
  
  /// updated after start
  List<int> notificationIds = [];

  int lastId = 10;

  TimerState();

  TimerState.fromJson(Map<String, dynamic> data)
  {
    startMoment = data['startMoment'];
    passedBeforeStart = data['passedBeforeStart'];
    timersSizes = List.from(data['timersSizes']);
    notificationIds = List.from(data['notificationIds']);
    lastId = data['lastId'];
  }

  Map<String, dynamic> toJson() {
    return {
      'startMoment': startMoment,
      'passedBeforeStart' : passedBeforeStart,
      'timersSizes': timersSizes,
      'notificationIds': notificationIds,
      'lastId': lastId,
    };
  }
}

class EasyTimerState {
  List<int> timersValues = [];
  List<int> timersSizes = [];
  /// in milliseconds
  int totalTimerSize = 0;
  /// in milliseconds
  int passedBeforeStart = 0;
  /// int milliseconds
  int passedTime = 0;
  /// int milliseconds
  int passedAfterStart = 0;
  /// -1 means didnt start
  int currentTimer = -1;
  bool playing = false;
  bool finished = false;
  late DateTime startMoment;
  late DateTime now;

  EasyTimerState();
}

class Pair<A, B> {
  final A first;
  final B second;

  Pair(this.first, this.second);

  @override
  String toString() => '($first, $second)';
}

class TimerController {
  static bool _inited = false;
  static late TimerState _timerState;

  static const String _collectionName = "timer-data";

  static const _notInitedMessage = "TimerController is not inited";
  static const _stateIssue = "something gose wrong with world, DateTime or state are wrong, state issue";

  static const String docId = "1";
  static Future<void> _loadStateFromStorage() async {
    var data = await Localstore.instance.collection(_collectionName).doc(docId).get();
    bool storageEmpty = data == null ? true : data.isEmpty;
    if (!storageEmpty) {
      _timerState = TimerState.fromJson(data);
    } else {
      _timerState = TimerState();
      await Localstore.instance.collection(_collectionName).doc(docId).set(_timerState.toJson());
    }
  }

  static Future<void> _putStaleToStorage() async {
    await Localstore.instance.collection(_collectionName).delete();
    await Localstore.instance.collection(_collectionName).doc().set(_timerState.toJson());
  }

  /// returns temporary but easy to understand state of timer
  static EasyTimerState _getEasyTimerState() {
    EasyTimerState state = EasyTimerState();
    state.timersSizes = _timerState.timersSizes.toList();
    state.passedBeforeStart = _timerState.passedBeforeStart;

    bool timerStarted = _timerState.startMoment != "";
    int passedTimeMs = _timerState.passedBeforeStart;

    if (timerStarted) {
      var startMoment = DateTime.parse(_timerState.startMoment);
      var now = DateTime.now();

      state.startMoment = startMoment;
      state.now = now;

      int passedAfterStart = now.difference(startMoment).inMilliseconds;

      if (passedAfterStart < 0) {
        throw _stateIssue;
      }

      passedTimeMs += passedAfterStart;
    }

    state.passedTime = passedTimeMs;

    int totalTimerSizeMs = 0;
    for (var i = 0; i < _timerState.timersSizes.length; i++) {
      totalTimerSizeMs += 1000 * _timerState.timersSizes[i];
    }
    bool timerFinished = totalTimerSizeMs <= passedTimeMs;
    
    state.totalTimerSize = totalTimerSizeMs;
    state.finished = timerFinished;

    if (timerFinished) {
      state.currentTimer = _timerState.timersSizes.length - 1;
      state.playing = false;
      state.timersValues = List.from(_timerState.timersSizes.map((elem) => 0));
    } else {
      state.timersValues = List.from(_timerState.timersSizes);
      
      if (passedTimeMs > 0) {
        state.currentTimer++;
      }

      for (int i = 0; i < passedTimeMs; i += 1000) {
        while (state.timersValues[state.currentTimer] == 0) {
          state.currentTimer++;
        }

        state.timersValues[state.currentTimer]--;
      }

      state.playing = timerStarted;
    }

    return state;
  }

  static Future<void> _removeAllMessages({bool putStaleToStorage = true}) async {
    await NotificationService.cancelScheduledMessages(_timerState.notificationIds);

    _timerState.notificationIds.clear();

    if (putStaleToStorage) {
      await _putStaleToStorage();
    }
  }

  static Future<void> _pauseTimer({bool putStaleToStorage = true}) async {
    var easyState = _getEasyTimerState();
    
    if (easyState.playing) {
      _timerState.passedBeforeStart = easyState.passedTime;
    } else if (easyState.finished) {
      _timerState.passedBeforeStart = easyState.totalTimerSize;
    } else {
      return;
    }

    _timerState.startMoment = "";

    await _removeAllMessages(putStaleToStorage: false);

    if (putStaleToStorage) {
      await _putStaleToStorage();
    }
  }

  static Future<void> _playTimer({bool putStaleToStorage = true}) async {
    var easyState = _getEasyTimerState();
    
    if (easyState.playing || easyState.totalTimerSize <= 0) {
      return;
    } else if (easyState.finished) {
      _timerState.passedBeforeStart = 0;
      _timerState.startMoment = "";
      _timerState.notificationIds.clear();
    }

    _timerState.startMoment = DateTime.now().toIso8601String();
    easyState = _getEasyTimerState();

    int millisecondsShift = -easyState.passedTime;
    List<Pair<int, tz.TZDateTime>> timerFinishedMoments = [];
    for (var i = 0; i < _timerState.timersSizes.length; i++) {
      millisecondsShift += _timerState.timersSizes[i] * 1000;

      if (millisecondsShift < 0) {
        continue;
      }

      timerFinishedMoments.add(
        Pair<int, tz.TZDateTime>(
          i,
          tz.TZDateTime.now(tz.local).add(Duration(milliseconds: millisecondsShift))
        )
      );
    }

    for (var i = 0; i < timerFinishedMoments.length - 1; i++) {
      NotificationService.scheduleNotification(
        ++_timerState.lastId,
        "${_timerState.timersSizes[timerFinishedMoments[i].first]} seconds timer",
        "Timer ended",
        timerFinishedMoments[i].second,
        sound: NotificationSounds.timerEnded
      );
    }

    if (timerFinishedMoments.isNotEmpty) {
      var totalDuration = Duration(milliseconds: easyState.totalTimerSize);
      NotificationService.scheduleNotification(
        ++_timerState.lastId,
        "Timer finished",
        "last timer ${_timerState.timersSizes[timerFinishedMoments.last.first]} seconds, total duration = ${totalDuration.inHours} : ${totalDuration.inMinutes} : ${totalDuration.inSeconds}",
        timerFinishedMoments.last.second,
        sound: NotificationSounds.timersFinised
      );
    }

    if (putStaleToStorage) {
      await _putStaleToStorage();
    }
  }

  static Future<void> init() async {
    if (_inited) {
      return;
    }
    
    await _loadStateFromStorage();

    _inited = true;
  }

  static ViewTimerState getViewTimerState() {
    if (!_inited) {
      throw Exception(_notInitedMessage);
    }

    var easyState = _getEasyTimerState();


    ViewTimerState state = ViewTimerState.init(
      easyState.timersValues.toList(),
      easyState.currentTimer,
      easyState.playing
    );

    return state;
  }

  static Future<void> addTimer(int value) async {
    if (!_inited) {
      throw Exception(_notInitedMessage);
    }

    if (value > 0) {
      var state = _getEasyTimerState();

      if (state.finished && _timerState.startMoment != "")
      {
        await _pauseTimer(putStaleToStorage: false);
      }

      _timerState.timersSizes.add(value);

      await _putStaleToStorage();
    }
  }

  static Future<void> playStopTimer() async {
    if (!_inited) {
      throw Exception(_notInitedMessage);
    }
    
    var state = _getEasyTimerState();

    if (state.timersSizes.isEmpty) {
      return;
    }

    if (state.playing) {
      await _pauseTimer();
    } else {
      await _playTimer();
    }
  }

  static Future<void> resetTimer() async {
    if (!_inited) {
      throw Exception(_notInitedMessage);
    }

    _removeAllMessages(putStaleToStorage: false);

    var newState = TimerState();
    _timerState.passedBeforeStart = newState.passedBeforeStart;
    _timerState.startMoment = newState.startMoment;
    await _putStaleToStorage();
  }

  static Future<void> clearTimer() async {
    if (!_inited) {
      throw Exception(_notInitedMessage);
    }

    _removeAllMessages(putStaleToStorage: false);
    
    var newState = TimerState();
    _timerState.passedBeforeStart = newState.passedBeforeStart;
    _timerState.startMoment = newState.startMoment;
    _timerState.timersSizes = newState.timersSizes;

    await _putStaleToStorage();
  }
}
