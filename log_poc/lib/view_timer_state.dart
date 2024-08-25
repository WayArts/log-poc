class ViewTimerState {
  List<int> timersValues = [];
  
  // -1 means didnt start
  int currentTimer = -1;
  bool playing = false;

  ViewTimerState();

  ViewTimerState.init(
    this.timersValues,
    this.currentTimer,
    this.playing,
  );
}
