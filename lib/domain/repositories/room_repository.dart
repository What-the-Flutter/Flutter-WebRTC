import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class RoomRepositoryInt {
  Future<String> createRoom({required RTCSessionDescription offer});

  Future<void> deleteRoom({required String roomId});

  Future<void> addCandidateToRoom({required String roomId, required RTCIceCandidate candidate});

  Future<RTCSessionDescription?> getRoomOfferIfExists({required String roomId});

  Future<void> setAnswer({required String roomId, required RTCSessionDescription answer});

  Stream<RTCSessionDescription?> getRoomDataStream({required String roomId});

  Stream<List<RTCIceCandidate>> getCandidatesAddedToRoomStream({
    required String roomId,
    required bool listenCaller,
  });
}
