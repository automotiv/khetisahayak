import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/consultation.dart';
import 'package:kheti_sahayak_app/services/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final Consultation consultation;

  const VideoCallScreen({Key? key, required this.consultation}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  final AgoraService _agoraService = AgoraService();
  
  bool _showControls = true;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _hideControlsTimer;
  
  Offset _localVideoPosition = const Offset(16, 100);
  late AnimationController _pulseController;
  
  CallState _callState = CallState.idle;
  int? _remoteUid;
  NetworkQuality? _networkQuality;
  
  StreamSubscription<CallState>? _callStateSubscription;
  StreamSubscription<int?>? _remoteUserSubscription;
  StreamSubscription<NetworkQuality>? _networkQualitySubscription;

  static const Color _primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initializeAnimations();
    _subscribeToStreams();
    _initializeCall();
  }

  void _setupSystemUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _subscribeToStreams() {
    _callStateSubscription = _agoraService.callStateStream.listen((state) {
      if (mounted) {
        setState(() => _callState = state);
        if (state == CallState.connected) {
          _startCallTimer();
          _resetHideControlsTimer();
        } else if (state == CallState.ended || state == CallState.failed) {
          _handleCallEnded();
        }
      }
    });

    _remoteUserSubscription = _agoraService.remoteUserStream.listen((uid) {
      if (mounted) {
        setState(() => _remoteUid = uid);
      }
    });

    _networkQualitySubscription = _agoraService.networkQualityStream.listen((quality) {
      if (mounted) {
        setState(() => _networkQuality = quality);
      }
    });
  }

  Future<void> _initializeCall() async {
    final hasPermissions = await _agoraService.requestPermissions();
    if (!hasPermissions) {
      _showPermissionDeniedDialog();
      return;
    }

    final config = await _agoraService.fetchCallToken(
      consultationId: widget.consultation.id,
      isVideoCall: true,
    );

    if (config == null) {
      _showErrorDialog('Failed to get call token. Please try again.');
      return;
    }

    final initialized = await _agoraService.initializeEngine(config);
    if (!initialized) {
      _showErrorDialog('Failed to initialize video call. Please try again.');
      return;
    }

    await _agoraService.joinChannel();
  }

  void _handleCallEnded() {
    _callTimer?.cancel();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _hideControlsTimer?.cancel();
    _pulseController.dispose();
    _callStateSubscription?.cancel();
    _remoteUserSubscription?.cancel();
    _networkQualitySubscription?.cancel();
    _agoraService.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _callState == CallState.connected) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _resetHideControlsTimer();
    }
  }

  String get _formattedDuration {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            _buildRemoteVideo(),
            if (_callState == CallState.connecting || 
                _callState == CallState.reconnecting) 
              _buildConnectingOverlay(),
            _buildLocalVideoPreview(),
            if (_showControls) _buildTopBar(),
            _buildCallDuration(),
            if (_showControls) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_remoteUid != null && _agoraService.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(uid: _remoteUid!),
          connection: RtcConnection(channelId: widget.consultation.id),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _primaryGreen.withOpacity(0.3),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                border: Border.all(color: Colors.white24, width: 3),
              ),
              child: Center(
                child: Text(
                  widget.consultation.expertName
                      .split(' ')
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .take(2)
                      .join(),
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.consultation.expertName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              widget.consultation.expertSpecialization,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white60,
              ),
            ),
            if (_callState == CallState.connected && _remoteUid == null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Waiting for expert to join...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingOverlay() {
    final isReconnecting = _callState == CallState.reconnecting;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (_pulseController.value * 0.1),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isReconnecting ? Colors.orange : _primaryGreen)
                          .withOpacity(0.3),
                      border: Border.all(
                        color: isReconnecting ? Colors.orange : _primaryGreen,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      isReconnecting ? Icons.wifi_off : Icons.phone_in_talk,
                      color: isReconnecting ? Colors.orange : _primaryGreen,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              isReconnecting ? 'Reconnecting...' : 'Connecting...',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isReconnecting
                  ? 'Please wait while we restore the connection'
                  : 'Please wait while we connect you to ${widget.consultation.expertName}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideoPreview() {
    return Positioned(
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _localVideoPosition += details.delta;
          });
        },
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: _agoraService.isCameraOff ? Colors.grey[800] : Colors.grey[700],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _agoraService.isCameraOff
                ? const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 36,
                    ),
                  )
                : _agoraService.engine != null
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _agoraService.engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white38,
                          size: 48,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 16,
          16,
          16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _showEndCallDialog(),
            ),
            const Spacer(),
            if (_networkQuality != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _networkQuality!.isGood
                      ? Colors.green.withOpacity(0.8)
                      : Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _networkQuality!.isGood ? Icons.signal_cellular_4_bar : Icons.signal_cellular_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _networkQuality!.displayText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _callState == CallState.connected
                    ? Colors.green.withOpacity(0.8)
                    : Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _callState == CallState.connected ? 'Connected' : 'Connecting',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallDuration() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _callState == CallState.connecting ? Colors.orange : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _callState == CallState.connecting ? 'Connecting...' : _formattedDuration,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _agoraService.isMuted ? Icons.mic_off : Icons.mic,
              label: _agoraService.isMuted ? 'Unmute' : 'Mute',
              isActive: !_agoraService.isMuted,
              onPressed: () async {
                await _agoraService.toggleMute();
                setState(() {});
              },
            ),
            _buildControlButton(
              icon: _agoraService.isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _agoraService.isCameraOff ? 'Camera On' : 'Camera Off',
              isActive: !_agoraService.isCameraOff,
              onPressed: () async {
                await _agoraService.toggleCamera();
                setState(() {});
              },
            ),
            _buildEndCallButton(),
            _buildControlButton(
              icon: _agoraService.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              label: _agoraService.isSpeakerOn ? 'Speaker' : 'Earpiece',
              isActive: _agoraService.isSpeakerOn,
              onPressed: () async {
                await _agoraService.toggleSpeaker();
                setState(() {});
              },
            ),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              label: 'Flip',
              isActive: true,
              onPressed: () async {
                await _agoraService.switchCamera();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white24 : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isActive ? Colors.white38 : Colors.white12,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white60,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showEndCallDialog,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'End',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permissions Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Camera and microphone permissions are required for video calls. Please enable them in settings.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEndCallDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Call?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to end this call?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'End Call',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _agoraService.leaveChannel();
      Navigator.pop(context);
    }
  }
}
