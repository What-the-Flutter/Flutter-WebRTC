import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_streaming/data/datasources/remote_datasource.dart';
import 'package:video_streaming/domain/repositories/room_repository.dart';

class RoomRepository implements RoomRepositoryInt {
  final RemoteDataSource _remoteDatasource;

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
    required bool calleeCandidate,
  }) =>
      _remoteDatasource.addCandidateToRoom(
        roomId: roomId,
        candidate: candidate,
        calleeCandidates: calleeCandidate,
      );

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
    required bool listenCallee,
  }) =>
      _remoteDatasource.getCandidatesAddedToRoomStream(
        roomId: roomId,
        listenCallee: listenCallee,
      );
}
