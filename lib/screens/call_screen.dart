import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/models.dart';
import '../services/call_service.dart';
import '../services/pair_channel.dart';

/// Video/audio call UI. Both the caller and the callee land here — see
/// HomeScreen's incoming-call listener for how the callee gets here with
/// the offer's SDP already captured (that handoff is the trickiest part
/// of the whole calling feature; see ENGINEERING_HANDOFF.md §5).
class CallScreen extends StatefulWidget {
  final Pairing pairing;
  final bool isCaller;
  final bool video;
  final String? initialOfferSdp; // required when isCaller == false

  const CallScreen({
    super.key,
    required this.pairing,
    required this.isCaller,
    this.video = true,
    this.initialOfferSdp,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallService _callService;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _connecting = true;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _callService = CallService(PairChannel('call', widget.pairing.id));
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _callService.onRemoteStream = (stream) {
      if (!mounted) return;
      setState(() {
        _remoteRenderer.srcObject = stream;
        _connecting = false;
      });
    };
    _callService.onEnded = () {
      if (mounted) Navigator.of(context).pop();
    };

    await _callService.start(
      isCaller: widget.isCaller,
      video: widget.video,
      initialOfferSdp: widget.initialOfferSdp,
    );
    if (mounted) setState(() => _localRenderer.srcObject = _callService.localStream);
  }

  Future<void> _hangUp() async {
    await _callService.hangUp();
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _callService.toggleMute(_muted);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
          if (_connecting)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('Connecting...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          if (widget.video)
            Positioned(
              right: 16, top: 40, width: 110, height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
            ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: Colors.white24,
                  tooltip: _muted ? 'Unmute microphone' : 'Mute microphone',
                  onPressed: _toggleMute,
                  child: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white),
                ),
                const SizedBox(width: 24),
                FloatingActionButton(
                  heroTag: 'hangup',
                  backgroundColor: Colors.red,
                  tooltip: 'End call',
                  onPressed: _hangUp,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
