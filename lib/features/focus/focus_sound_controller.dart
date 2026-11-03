import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:syncfocus/features/focus/ambient_sound.dart';
import 'package:syncfocus/features/focus/focus_timer_controller.dart';

abstract interface class FocusSoundOutput {
  Future<void> play(AmbientSound sound);
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

/// Keeps the selected ambient sound aligned with the active focus phase.
class FocusSoundController {
  FocusSoundController({
    required FocusTimerController timer,
    required this.output,
    AmbientSound Function()? selectedSound,
    bool Function()? isPro,
    this.configuration,
  }) : _timer = timer,
       _selectedSound = selectedSound ?? (() => AmbientSound.rain),
       _isPro = isPro ?? (() => false),
       _lastPhase = timer.phase {
    _timer.addListener(_onTimerChanged);
    configuration?.addListener(_onConfigurationChanged);
  }

  final FocusTimerController _timer;
  final FocusSoundOutput output;
  final AmbientSound Function() _selectedSound;
  final bool Function() _isPro;
  final Listenable? configuration;
  FocusTimerPhase _lastPhase;
  Future<void> _pendingOperations = Future<void>.value();
  bool _disposed = false;
  bool _soundStarted = false;

  @visibleForTesting
  Future<void> get pendingOperations => _pendingOperations;

  void _onTimerChanged() {
    if (_disposed || _timer.phase == _lastPhase) return;
    _lastPhase = _timer.phase;

    switch (_lastPhase) {
      case FocusTimerPhase.running:
        _playSelectedSound();
      case FocusTimerPhase.paused:
        _enqueue(output.pause);
      case FocusTimerPhase.ready ||
          FocusTimerPhase.complete ||
          FocusTimerPhase.breakRunning ||
          FocusTimerPhase.breakPaused ||
          FocusTimerPhase.breakComplete:
        _stopSound();
    }
  }

  void _onConfigurationChanged() {
    if (!_disposed && _timer.phase == FocusTimerPhase.running) {
      _playSelectedSound();
    }
  }

  void _playSelectedSound() {
    final selected = _selectedSound();
    final sound = selected.requiresPro && !_isPro()
        ? AmbientSound.rain
        : selected;
    _soundStarted = true;
    _enqueue(() => output.play(sound));
  }

  void _stopSound() {
    if (!_soundStarted) return;
    _soundStarted = false;
    _enqueue(output.stop);
  }

  void _enqueue(Future<void> Function() operation) {
    _pendingOperations = _pendingOperations.then((_) async {
      try {
        await operation();
      } on Object catch (error, stackTrace) {
        debugPrint('Focus sound could not update: $error\n$stackTrace');
      }
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer.removeListener(_onTimerChanged);
    configuration?.removeListener(_onConfigurationChanged);
    _stopSound();
    await _pendingOperations;
    await output.dispose();
  }
}

/// Plays bundled ambient tracks at the Android media-stream volume.
class JustAudioAmbientOutput implements FocusSoundOutput {
  JustAudioAmbientOutput({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  AmbientSound? _preparedSound;

  Future<void> _prepare(AmbientSound sound) async {
    if (_preparedSound == sound) return;
    await _player.stop();
    await _player.setAsset(sound.assetPath);
    await _player.setLoopMode(LoopMode.one);
    _preparedSound = sound;
  }

  @override
  Future<void> play(AmbientSound sound) async {
    try {
      await _prepare(sound);
      unawaited(_startPlayback());
    } on Object catch (error, stackTrace) {
      debugPrint('Ambient playback failed: $error\n$stackTrace');
    }
  }

  Future<void> _startPlayback() async {
    try {
      await _player.play();
    } on Object catch (error, stackTrace) {
      debugPrint('Ambient playback failed: $error\n$stackTrace');
    }
  }

  @override
  Future<void> pause() async {
    if (_preparedSound == null) return;
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    if (_preparedSound == null) return;
    await _player.stop();
  }

  @override
  Future<void> dispose() => _player.dispose();
}
