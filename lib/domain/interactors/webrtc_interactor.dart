import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_streaming/domain/repositories/room_repository.dart';

class WebrtcInteractor {
  final RoomRepositoryInt _roomRepository;

  WebrtcInteractor(this._roomRepository);

  Future<String> createRoom({required RTCSessionDescription offer}) =>
      _roomRepository.createRoom(offer: offer);

  Future<void> deleteRoom({required String roomId}) => _roomRepository.deleteRoom(roomId: roomId);

  Future<void> addCandidateToRoom({
    required String roomId,
    required RTCIceCandidate candidate,
    required bool calleeCandidates,
  }) =>
      _roomRepository.addCandidateToRoom(
        roomId: roomId,
        candidate: candidate,
        calleeCandidates: calleeCandidates,
      );

  Future<RTCSessionDescription?> getRoomDataIfExists({required String roomId}) =>
      _roomRepository.getRoomDataIfExists(roomId: roomId);

  Future<void> setAnswer({required String roomId, required RTCSessionDescription answer}) =>
      _roomRepository.setAnswer(roomId: roomId, answer: answer);

  Stream<RTCSessionDescription?> getRoomDataStream({required String roomId}) =>
      _roomRepository.getRoomDataStream(roomId: roomId);

  Stream<List<RTCIceCandidate>> getCandidatesAddedToRoomStream({
    required String roomId,
    required bool calleeCandidates,
  }) =>
      _roomRepository.getCandidatesAddedToRoomStream(
        roomId: roomId,
        calleeCandidates: calleeCandidates,
      );
}
