import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebrtcState {
  final String? currentRoomText;
  final String? roomId;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final RTCPeerConnection? peerConnection;
  final bool cleared;
  final bool currentUserShown;
  final bool companionShown;

  WebrtcState({
    this.currentRoomText,
    this.roomId,
    this.localStream,
    this.remoteStream,
    this.peerConnection,
    this.cleared = false,
    this.currentUserShown = false,
    this.companionShown = false,
  });

  WebrtcState copyWith({
    String? currentRoomText,
    String? roomId,
    MediaStream? localStream,
    MediaStream? remoteStream,
    RTCPeerConnection? peerConnection,
    bool? currentUserShown,
    bool? companionShown,
    bool clearCurrentRoomText = false,
    bool clearRoomId = false,
    bool clearLocalStream = false,
    bool clearRemoteStream = false,
    bool clearPeerConnection = false,
    bool clearAll = false,
  }) {
    return WebrtcState(
      cleared: clearAll,
      currentRoomText:
          clearAll || clearCurrentRoomText ? null : currentRoomText ?? this.currentRoomText,
      roomId: clearAll || clearRoomId ? null : roomId ?? this.roomId,
      localStream: clearAll || clearLocalStream ? null : localStream ?? this.localStream,
      remoteStream: clearAll || clearRemoteStream ? null : remoteStream ?? this.remoteStream,
      peerConnection:
          clearAll || clearPeerConnection ? null : peerConnection ?? this.peerConnection,
      currentUserShown: clearAll ? false : (currentUserShown ?? this.currentUserShown),
      companionShown: clearAll ? false : (companionShown ?? this.companionShown),
    );
  }
}