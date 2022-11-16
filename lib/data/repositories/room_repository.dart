import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_streaming/data/datasources/remote_datasource.dart';
import 'package:video_streaming/domain/repositories/room_repository.dart';

class RoomRepository implements RoomRepositoryInt {
  final RemoteDataSource _remoteDatasource;
  Future? _lastAddedCandidate;

  RoomRepository(this._remoteDatasource);

  @override
  Future<String> createRoom({required RTCSessionDescription offer}) =>
      _remoteDatasource.createRoom(offer: offer);

  @override
  Future<void> deleteRoom({required String roomId}) => _remoteDatasource.deleteRoom(roomId: roomId);

  @override
  Future<void> addCandidateToRoom({
    required String roomId,
    required RTCIceCandidate candidate,
  }) async {
    if (_lastAddedCandidate != null) {
      _lastAddedCandidate = _lastAddedCandidate!.whenComplete(
        () => _remoteDatasource.addCandidateToRoom(
          roomId: roomId,
          candidate: candidate,
        ),
      );
    } else {
      _lastAddedCandidate = _remoteDatasource.addCandidateToRoom(
        roomId: roomId,
        candidate: candidate,
      );
    }
    await _lastAddedCandidate!;
  }

  @override
  Future<RTCSessionDescription?> getRoomDataIfExists({required String roomId}) =>
      _remoteDatasource.getRoomDataIfExists(roomId: roomId);

  @override
  Future<void> setAnswer({required String roomId, required RTCSessionDescription answer}) =>
      _remoteDatasource.setAnswer(roomId: roomId, answer: answer);

  @override
  Stream<RTCSessionDescription?> getRoomDataStream({required String roomId}) =>
      _remoteDatasource.getRoomDataStream(roomId: roomId);

  @override
  Stream<List<RTCIceCandidate>> getCandidatesAddedToRoomStream({
    required String roomId,
    required bool listenCaller,
  }) =>
      _remoteDatasource.getCandidatesAddedToRoomStream(
        roomId: roomId,
        listenCaller: listenCaller,
      );
}
