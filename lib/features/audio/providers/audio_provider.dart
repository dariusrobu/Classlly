import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioProvider with ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  DateTime? _recordingStartTime;
  DateTime? get recordingStartTime => _recordingStartTime;

  StreamSubscription? _playerSubscription;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _playerSubscription?.cancel();
    super.dispose();
  }

  Future<String?> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return null;

    final directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    const config = RecordConfig();
    await _recorder.start(config, path: filePath);

    _isRecording = true;
    _recordingStartTime = DateTime.now();
    notifyListeners();
    return filePath;
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    _isRecording = false;
    notifyListeners();
  }

  Future<void> play(String path) async {
    if (path.isEmpty || !File(path).existsSync()) return;

    await _player.setFilePath(path);
    _totalDuration = _player.duration ?? Duration.zero;

    _playerSubscription = _player.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _player.play();
    _isPlaying = true;
    notifyListeners();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        notifyListeners();
      }
    });
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  int get elapsedRecordingMillis {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inMilliseconds;
  }
}
