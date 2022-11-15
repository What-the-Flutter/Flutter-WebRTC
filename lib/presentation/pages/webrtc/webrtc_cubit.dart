import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_streaming/domain/interactors/webrtc_interactor.dart';
import 'package:video_streaming/presentation/pages/webrtc/webrtc_state.dart';
import 'package:video_streaming/utils/logger.dart';

class WebrtcCubit extends Cubit<WebrtcState> {
  static final WebrtcState _initialState = WebrtcState();

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  final WebrtcInteractor _interactor;
  final List<StreamSubscription> _subscriptions = [];

  WebrtcCubit(this._interactor) : super(_initialState);

  Future<String> createRoom() async {
    final peerConnection = await createPeerConnection(_configuration);
    Logger.printGreen(
      message: 'Peer Connection created',
      filename: 'webrtc_cubit',
      method: 'createRoom',
      line: 29,
    );
    emit(state.copyWith(peerConnection: peerConnection));
    _registerPeerConnectionListeners(peerConnection);

    state.localStream?.getTracks().forEach((track) {
      peerConnection.addTrack(track, state.localStream!);
    });

    final offer = await peerConnection.createOffer();
    final roomId = await _interactor.createRoom(offer: offer);
    Logger.printGreen(
      message: 'Room $roomId created with offer',
      filename: 'webrtc_cubit',
      method: 'createRoom',
      line: 44,
    );
    emit(state.copyWith(roomId: roomId));

    peerConnection.onIceCandidate = (candidate) {
      Logger.printMagenta(
        message: 'ICE candidate received: ${candidate.candidate}',
        filename: 'webrtc_cubit',
        method: 'createRoom(onIceCandidate)',
        line: 53,
      );
      _interactor.addCandidateToRoom(
        roomId: roomId,
        candidate: candidate,
        calleeCandidate: false,
      );
    };

    await peerConnection.setLocalDescription(offer);

    peerConnection.onTrack = (event) {
      Logger.printMagenta(
        message: 'Track is added to the connection',
        filename: 'webrtc_cubit',
        method: 'createRoom(onTrack)',
        line: 69,
      );
      event.streams[0].getTracks().forEach((track) {
        state.remoteStream?.addTrack(track);
      });
    };

    _startStreamListening(roomId);
    return roomId;
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    emit(state.copyWith(roomId: roomId));
    final sessionDescription = await _interactor.getRoomDataIfExists(roomId: roomId);

    if (sessionDescription != null) {
      final peerConnection = await createPeerConnection(_configuration);
      Logger.printYellow(
        message: 'Room exists, Peer Connection created',
        filename: 'webrtc_cubit',
        method: 'joinRoom',
        line: 90,
      );

      _registerPeerConnectionListeners(peerConnection);

      state.localStream?.getTracks().forEach((track) {
        peerConnection.addTrack(track, state.localStream!);
      });

      peerConnection.onIceCandidate = (candidate) {
        Logger.printCyan(
          message: 'ICE candidate received: ${candidate.candidate}',
          filename: 'webrtc_cubit',
          method: 'joinRoom(onIceCandidate)',
          line: 104,
        );
        _interactor.addCandidateToRoom(
          roomId: roomId,
          candidate: candidate,
          calleeCandidate: true,
        );
      };

      peerConnection.onTrack = (event) {
        Logger.printCyan(
          message: 'Track is added to the connection',
          filename: 'webrtc_cubit',
          method: 'joinRoom(onTrack)',
          line: 118,
        );
        event.streams[0].getTracks().forEach((track) => state.remoteStream?.addTrack(track));
      };

      await peerConnection.setRemoteDescription(sessionDescription);
      final answer = await peerConnection.createAnswer();
      Logger.printYellow(
        message: 'Answer (Session Description Protocol package) created',
        filename: 'webrtc_cubit',
        method: 'joinRoom',
        line: 129,
      );

      await peerConnection.setLocalDescription(answer);
      emit(state.copyWith(peerConnection: peerConnection));
      await _interactor.setAnswer(roomId: roomId, answer: answer);

      _subscriptions.addAll(
        [
          _interactor.getCandidatesAddedToRoomStream(roomId: roomId, listenCallee: false).listen(
            (candidates) {
              for (final candidate in candidates) {
                state.peerConnection?.addCandidate(candidate);
              }
            },
          ),
          _interactor.getRoomDataStream(roomId: roomId).listen(
            (answer) async {
              if (answer == null) {
                emit(state.copyWith(clearAll: true));
              }
            },
          )
        ],
      );
    }
  }

  Future<void> openUserMedia() async {
    var stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    emit(
      state.copyWith(
        localStream: stream,
        currentUserShown: true,
      ),
    );
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    final tracks = localVideo.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (state.remoteStream != null) {
      state.remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (state.peerConnection != null) state.peerConnection!.close();

    if (state.roomId != null) {
      _interactor.deleteRoom(roomId: state.roomId!);
    }

    state.localStream!.dispose();
    state.remoteStream?.dispose();

    for (final subs in _subscriptions) {
      subs.cancel();
    }
    _subscriptions.clear();

    emit(state.copyWith(clearAll: true));
  }

  void _startStreamListening(String roomId) {
    _subscriptions.addAll([
      _interactor.getRoomDataStream(roomId: roomId).listen((answer) async {
        if (answer != null) {
          state.peerConnection?.setRemoteDescription(answer);
        } else {
          if (state.remoteStream != null) {
            emit(state.copyWith(clearAll: true));
          }
        }
      }),
      _interactor.getCandidatesAddedToRoomStream(roomId: roomId, listenCallee: true).listen(
        (candidates) {
          for (final candidate in candidates) {
            state.peerConnection?.addCandidate(candidate);
          }
        },
      ),
    ]);
  }

  void _registerPeerConnectionListeners(RTCPeerConnection peerConnection) {
    peerConnection.onIceGatheringState = (state) {
      Logger.printBlue(
        message: 'ICE gathering state changed: $state',
        filename: 'webrtc_cubit',
        method: '_registerPeerConnectionListeners',
        line: 220,
      );
    };

    peerConnection.onConnectionState = (state) {
      Logger.printBlue(
        message: 'Connection state change: $state',
        filename: 'webrtc_cubit',
        method: '_registerPeerConnectionListeners',
        line: 229,
      );
    };

    peerConnection.onSignalingState = (state) {
      Logger.printBlue(
        message: 'Signaling state change: $state',
        filename: 'webrtc_cubit',
        method: '_registerPeerConnectionListeners',
        line: 238,
      );
    };

    peerConnection.onAddStream = (stream) {
      Logger.printBlue(
        message: 'Remote stream added',
        filename: 'webrtc_cubit',
        method: '_registerPeerConnectionListeners',
        line: 247,
      );
      emit(state.copyWith(remoteStream: stream, companionShown: true));
    };
  }
}
