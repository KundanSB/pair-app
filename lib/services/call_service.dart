import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'pair_channel.dart';

/// Peer-to-peer audio/video calling. Media flows directly between the two
/// devices via free public STUN servers — Supabase only carries small
/// JSON signaling messages, so this costs $0 regardless of call volume.
/// Known gap: no TURN relay configured, so some restrictive NATs may
/// fail to connect. Linux desktop needs extra native build deps beyond
/// Flutter's baseline Linux setup.
class CallService {
  CallService(this._signaling);
  final PairChannel _signaling;

  RTCPeerConnection? _pc;
  MediaStream? localStream;

  void Function(MediaStream stream)? onRemoteStream;
  void Function()? onEnded;

  static const Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  Future<void> start({required bool isCaller, required bool video, String? initialOfferSdp}) async {
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });

    _pc = await createPeerConnection(_config);
    for (final track in localStream!.getTracks()) {
      await _pc!.addTrack(track, localStream!);
    }
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) onRemoteStream?.call(event.streams.first);
    };
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _signaling.send({
        'type': 'candidate', 'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid, 'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };
    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onEnded?.call();
      }
    };

    _signaling.addListener(_handleSignal);

    if (isCaller) {
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      _signaling.send({'type': 'offer', 'sdp': offer.sdp, 'video': video});
    } else if (initialOfferSdp != null) {
      await _pc!.setRemoteDescription(RTCSessionDescription(initialOfferSdp, 'offer'));
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      _signaling.send({'type': 'answer', 'sdp': answer.sdp});
    }
  }

  Future<void> _handleSignal(Map<String, dynamic> payload) async {
    final type = payload['type'];
    if (_pc == null) return;
    if (type == 'answer') {
      await _pc!.setRemoteDescription(RTCSessionDescription(payload['sdp'], 'answer'));
    } else if (type == 'candidate') {
      await _pc!.addCandidate(RTCIceCandidate(payload['candidate'], payload['sdpMid'], payload['sdpMLineIndex']));
    } else if (type == 'hangup' || type == 'decline') {
      onEnded?.call();
    }
  }

  Future<void> toggleMute(bool muted) async {
    for (final track in localStream?.getAudioTracks() ?? []) {
      track.enabled = !muted;
    }
  }

  Future<void> hangUp() async {
    _signaling.send({'type': 'hangup'});
    _signaling.removeListener(_handleSignal);
    for (final track in localStream?.getTracks() ?? []) {
      track.stop();
    }
    await _pc?.close();
    _pc = null;
    localStream = null;
  }
}
