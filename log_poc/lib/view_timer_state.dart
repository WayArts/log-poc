class ViewTimerState {
  /// in milliseconds
  List<int> timersValuesMs = [];
  
  // -1 means didnt start
  int currentTimer = -1;
  bool playing = false;
  bool finished = false;

  ViewTimerState();

  ViewTimerState.init(
    this.timersValuesMs,
    this.currentTimer,
    this.playing,
    this.finished,
  );
}
