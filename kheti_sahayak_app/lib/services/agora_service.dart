import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

enum CallState { idle, connecting, connected, reconnecting, ended, failed }

class AgoraCallConfig {
  final String channelName;
  final String token;
  final int uid;
  final String appId;
  final bool isVideoCall;

  AgoraCallConfig({
    required this.channelName,
    required this.token,
    required this.uid,
    required this.appId,
    this.isVideoCall = true,
  });
}

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  AgoraCallConfig? _currentConfig;
  
  final _callStateController = StreamController<CallState>.broadcast();
  final _remoteUserController = StreamController<int?>.broadcast();
  final _callStatsController = StreamController<RtcStats>.broadcast();
  final _networkQualityController = StreamController<NetworkQuality>.broadcast();

  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<int?> get remoteUserStream => _remoteUserController.stream;
  Stream<RtcStats> get callStatsStream => _callStatsController.stream;
  Stream<NetworkQuality> get networkQualityStream => _networkQualityController.stream;

  CallState _callState = CallState.idle;
  CallState get callState => _callState;
  
  int? _remoteUid;
  int? get remoteUid => _remoteUid;
  
  bool _isMuted = false;
  bool get isMuted => _isMuted;
  
  bool _isCameraOff = false;
  bool get isCameraOff => _isCameraOff;
  
  bool _isSpeakerOn = true;
  bool get isSpeakerOn => _isSpeakerOn;
  
  bool _isFrontCamera = true;
  bool get isFrontCamera => _isFrontCamera;

  RtcEngine? get engine => _engine;

  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  Future<AgoraCallConfig?> fetchCallToken({
    required String consultationId,
    required bool isVideoCall,
  }) async {
    try {
      final response = await ApiService().dio.post(
        '/consultations/$consultationId/call-token',
        data: {'isVideoCall': isVideoCall},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return AgoraCallConfig(
          channelName: data['channelName'],
          token: data['token'],
          uid: data['uid'],
          appId: data['appId'],
          isVideoCall: isVideoCall,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching call token: $e');
      return null;
    }
  }

  Future<bool> initializeEngine(AgoraCallConfig config) async {
    try {
      _currentConfig = config;
      _updateCallState(CallState.connecting);

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: config.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _registerEventHandlers();

      if (config.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }
      await _engine!.enableAudio();
      await _engine!.setEnableSpeakerphone(_isSpeakerOn);

      return true;
    } catch (e) {
      debugPrint('Error initializing Agora engine: $e');
      _updateCallState(CallState.failed);
      return false;
    }
  }

  void _registerEventHandlers() {
    _engine?.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint('Local user ${connection.localUid} joined channel');
        _updateCallState(CallState.connected);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint('Remote user $remoteUid joined');
        _remoteUid = remoteUid;
        _remoteUserController.add(remoteUid);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint('Remote user $remoteUid left: $reason');
        _remoteUid = null;
        _remoteUserController.add(null);
        if (reason == UserOfflineReasonType.userOfflineQuit) {
          _updateCallState(CallState.ended);
        }
      },
      onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
        debugPrint('Connection state changed: $state, reason: $reason');
        switch (state) {
          case ConnectionStateType.connectionStateConnecting:
            _updateCallState(CallState.connecting);
            break;
          case ConnectionStateType.connectionStateConnected:
            _updateCallState(CallState.connected);
            break;
          case ConnectionStateType.connectionStateReconnecting:
            _updateCallState(CallState.reconnecting);
            break;
          case ConnectionStateType.connectionStateFailed:
            _updateCallState(CallState.failed);
            break;
          case ConnectionStateType.connectionStateDisconnected:
            _updateCallState(CallState.ended);
            break;
        }
      },
      onRtcStats: (RtcConnection connection, RtcStats stats) {
        _callStatsController.add(stats);
      },
      onNetworkQuality: (RtcConnection connection, int remoteUid, QualityType txQuality, QualityType rxQuality) {
        _networkQualityController.add(NetworkQuality(
          txQuality: txQuality,
          rxQuality: rxQuality,
        ));
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint('Agora error: $err - $msg');
        if (err == ErrorCodeType.errTokenExpired || 
            err == ErrorCodeType.errInvalidToken) {
          _updateCallState(CallState.failed);
        }
      },
    ));
  }

  Future<bool> joinChannel() async {
    if (_engine == null || _currentConfig == null) return false;

    try {
      await _engine!.joinChannel(
        token: _currentConfig!.token,
        channelId: _currentConfig!.channelName,
        uid: _currentConfig!.uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: _currentConfig!.isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: _currentConfig!.isVideoCall,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error joining channel: $e');
      _updateCallState(CallState.failed);
      return false;
    }
  }

  Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
      _updateCallState(CallState.ended);
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _engine?.muteLocalVideoStream(_isCameraOff);
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> switchCamera() async {
    _isFrontCamera = !_isFrontCamera;
    await _engine?.switchCamera();
  }

  void _updateCallState(CallState state) {
    _callState = state;
    _callStateController.add(state);
  }

  Future<void> dispose() async {
    await leaveChannel();
    await _engine?.release();
    _engine = null;
    _currentConfig = null;
    _remoteUid = null;
    _isMuted = false;
    _isCameraOff = false;
    _isSpeakerOn = true;
    _isFrontCamera = true;
    _updateCallState(CallState.idle);
  }

  void disposeStreams() {
    _callStateController.close();
    _remoteUserController.close();
    _callStatsController.close();
    _networkQualityController.close();
  }
}

class NetworkQuality {
  final QualityType txQuality;
  final QualityType rxQuality;

  NetworkQuality({required this.txQuality, required this.rxQuality});

  String get displayText {
    final avgQuality = (txQuality.index + rxQuality.index) ~/ 2;
    switch (avgQuality) {
      case 0:
      case 1:
        return 'Excellent';
      case 2:
        return 'Good';
      case 3:
        return 'Poor';
      case 4:
        return 'Bad';
      default:
        return 'Unknown';
    }
  }

  bool get isGood => txQuality.index <= 2 && rxQuality.index <= 2;
}
