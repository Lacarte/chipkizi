import 'dart:async';
import 'package:intl/intl.dart' show DateFormat;
import 'package:chipkizi/models/recording.dart';
import 'package:chipkizi/values/status_code.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_sound/flutter_sound.dart';

const _tag = 'RecordingModel:';

abstract class RecordingModel extends Model {
  final Firestore _database = Firestore.instance;

  StreamSubscription _recorderSubscription;
  StreamSubscription _playerSubscription;
  FlutterSound flutterSound = FlutterSound();

  StatusCode _uploadStatus;
  StatusCode get uploadStatus => _uploadStatus;
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String _recorderTxt = '00:00:00';
  String get recorderTxt => _recorderTxt;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  String _playerTxt = '00:00:00';
  String get playerText => _playerTxt;

  double _recorderProgress = 0.0;
  double get recorderProgress => _recorderProgress;

//  FlutterSound flutterSound;

//  flutterSound.setSubscriptionDuration(0.01);

  Future<StatusCode> handleSubmit(Recording recording) async {
    print('$_tag at handle submit recording');
  }

  Future<StatusCode> _uploadRecording(Recording recoding) async {
    // TODO: handle recording
  }

  Future<StatusCode> deleteRecording(Recording recoding) async {
    // TODO: handle delete recording
  }

  Future<void> startRecording() async {
    print('$_tag at startRecording');
    try {
      String path = await flutterSound.startRecorder(null);
      print('startRecorder: $path');

      _recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
        DateTime now = DateTime.now();
        DateTime recordingLimitDate = now.add(Duration(seconds: 30));
        DateTime date =
            DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());

        String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
        _recorderTxt = txt.substring(0, 8);
        int lapsedTime = date.second;
        int totalTime = 30;
        _recorderProgress = lapsedTime / totalTime;
        if (_recorderTxt == '00:30:00') stopRecording();

        print('$_recorderProgress');
        notifyListeners();
      });

      _isRecording = true;
      notifyListeners();
    } catch (err) {
      print('startRecorder error: $err');
    }
  }

  Future<void> stopRecording() async {
    print('$_tag at stopRecording');
    try {
      String result = await flutterSound.stopRecorder();
      print('stopRecorder: $result');

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }

      this._isRecording = false;
      notifyListeners();
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  Future<void> playPlayback() async {
    String path = await flutterSound.startPlayer(null);
    await flutterSound.setVolume(1.0);
    print('startPlayer: $path');

    try {
      _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt());
          String txt = DateFormat('mm:ss:SS', 'en_US').format(date);

          this._isPlaying = true;
          this._playerTxt = txt.substring(0, 8);
          _isPaused = false;
          notifyListeners();
        }
      });
    } catch (err) {
      print('error: $err');
    }
  }

  Future<void> pausePlayback() async {
    String result = await flutterSound.pausePlayer();
    _isPaused = true;
    notifyListeners();
    print('pausePlayer: $result');
  }

  Future<void> resumePlayback() async {
    String result = await flutterSound.resumePlayer();
    _isPaused = false;
    notifyListeners();
    print('resumePlayer: $result');
  }

  Future<void> stopPlayback() async {
    try {
      String result = await flutterSound.stopPlayer();
      print('stopPlayer: $result');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }

      this._isPlaying = false;
      _isPaused = false;
      _playerTxt = '00:00:00';
      notifyListeners();
    } catch (err) {
      print('error: $err');
    }
  }
}