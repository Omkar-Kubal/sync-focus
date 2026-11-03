import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfocus/features/focus/ambient_sound.dart';
import 'package:syncfocus/features/focus/focus_sound_controller.dart';
import 'package:syncfocus/features/focus/focus_timer_controller.dart';

class _RecordingFocusSoundOutput implements FocusSoundOutput {
  final events = <String>[];

  @override
  Future<void> play(AmbientSound sound) async =>
      events.add('play:${sound.name}');

  @override
  Future<void> pause() async => events.add('pause');

  @override
  Future<void> stop() async => events.add('stop');

  @override
  Future<void> dispose() async => events.add('dispose');
}

Future<void> _settleAudioEvents() => Future<void>.delayed(Duration.zero);

class _PendingPlayAudioPlayer extends AudioPlayer {
  final playStarted = Completer<void>();
  final playback = Completer<void>();
  int pauseCount = 0;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async => null;

  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> play() {
    playStarted.complete();
    return playback.future;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> dispose() async {
    if (!playback.isCompleted) playback.complete();
    await super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ambient output can pause while playback remains active', () async {
    final player = _PendingPlayAudioPlayer();
    final output = JustAudioAmbientOutput(player: player);

    final play = output.play(AmbientSound.rain);
    try {
      await player.playStarted.future.timeout(const Duration(seconds: 1));
      final returnedBeforePlaybackEnded = await play
          .then((_) => true)
          .timeout(const Duration(milliseconds: 100), onTimeout: () => false);

      expect(returnedBeforePlaybackEnded, isTrue);
      await output.pause();
      expect(player.pauseCount, 1);
    } finally {
      if (!player.playback.isCompleted) player.playback.complete();
      await output.dispose();
    }
  });

  test('rain follows focus start, pause, resume, and reset', () async {
    final timer = FocusTimerController();
    final output = _RecordingFocusSoundOutput();
    final sound = FocusSoundController(timer: timer, output: output);

    timer.start();
    await _settleAudioEvents();
    expect(output.events, ['play:rain']);

    timer.pause();
    await _settleAudioEvents();
    expect(output.events, ['play:rain', 'pause']);

    timer.start();
    await _settleAudioEvents();
    expect(output.events, ['play:rain', 'pause', 'play:rain']);

    timer.reset();
    await _settleAudioEvents();
    expect(output.events, ['play:rain', 'pause', 'play:rain', 'stop']);

    await sound.dispose();
    timer.dispose();
  });

  test('rain stops when a focus session completes', () async {
    var now = DateTime(2026, 11, 2, 12);
    final timer = FocusTimerController(now: () => now);
    final output = _RecordingFocusSoundOutput();
    final sound = FocusSoundController(timer: timer, output: output);

    timer.setDurationMinutes(5);
    timer.start();
    await _settleAudioEvents();

    now = now.add(const Duration(minutes: 5));
    timer.refresh();
    await _settleAudioEvents();

    expect(timer.phase, FocusTimerPhase.complete);
    expect(output.events, ['play:rain', 'stop']);

    await sound.dispose();
    timer.dispose();
  });

  test(
    'premium sound stays on Rain for Free and follows Pro selection',
    () async {
      final timer = FocusTimerController();
      final output = _RecordingFocusSoundOutput();
      var selected = AmbientSound.ocean;
      var isPro = false;
      final configuration = ChangeNotifier();
      final sound = FocusSoundController(
        timer: timer,
        output: output,
        selectedSound: () => selected,
        isPro: () => isPro,
        configuration: configuration,
      );

      timer.start();
      await _settleAudioEvents();
      expect(output.events, ['play:rain']);

      isPro = true;
      configuration.notifyListeners();
      await _settleAudioEvents();
      expect(output.events, ['play:rain', 'play:ocean']);

      timer.pause();
      timer.start();
      await _settleAudioEvents();
      expect(output.events.last, 'play:ocean');

      await sound.dispose();
      configuration.dispose();
      timer.dispose();
    },
  );

  test('ambient sound stops when the focus phase becomes a break', () async {
    var now = DateTime(2026, 11, 2, 12);
    final timer = FocusTimerController(now: () => now);
    final output = _RecordingFocusSoundOutput();
    final sound = FocusSoundController(timer: timer, output: output);

    timer.setDurationMinutes(5);
    timer.start();
    now = now.add(const Duration(minutes: 5));
    timer.refresh();
    timer.startBreak(breakDurationMinutes: 5);
    await _settleAudioEvents();

    expect(output.events, ['play:rain', 'stop']);

    await sound.dispose();
    timer.dispose();
  });
}
