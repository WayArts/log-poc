class ViewTimerState {
  List<int> timersValues = [];
  int currentTimer = -1;
  bool playing = false;

  ViewTimerState();

  ViewTimerState.init(
    this.timersValues,
    this.currentTimer,
    this.playing,
  );
}
