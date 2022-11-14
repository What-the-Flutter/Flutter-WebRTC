import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_streaming/domain/interactors/webrtc_interactor.dart';
import 'package:video_streaming/presentation/pages/webrtc/webrtc_state.dart';

class WebrtcCubit extends Cubit<WebrtcState> {
  static final WebrtcState _initialState = WebrtcState();

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  final WebrtcInteractor _interactor;
  final List<StreamSubscription> _subscriptions = [];

  WebrtcCubit(this._interactor) : super(_initialState);

  /// Green print color
  Future<String> createRoom() async {
    final peerConnection = await createPeerConnection(_configuration);
    emit(state.copyWith(peerConnection: peerConnection));
    _registerPeerConnectionListeners(peerConnection);

    state.localStream?.getTracks().forEach((track) {
      peerConnection.addTrack(track, state.localStream!);
    });

    final offer = await peerConnection.createOffer();

    final roomId = await _interactor.createRoom(offer: offer);
    emit(state.copyWith(roomId: roomId));

    peerConnection.onIceCandidate = (candidate) {
      _interactor.addCandidateToRoom(
        roomId: roomId,
        candidate: candidate,
        calleeCandidates: false,
      );
    };

    await peerConnection.setLocalDescription(offer);

    emit(state.copyWith(currentRoomText: 'Current room is $roomId - You are the caller!'));

    peerConnection.onTrack = (event) {
      event.streams[0].getTracks().forEach((track) {
        state.remoteStream?.addTrack(track);
      });
    };

    _startStreamListening(roomId);
    return roomId;
  }

  /// Yellow print color
  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    emit(state.copyWith(roomId: roomId));
    final sessionDescription = await _interactor.getRoomDataIfExists(roomId: roomId);

    if (sessionDescription != null) {
      final peerConnection = await createPeerConnection(_configuration);

      _registerPeerConnectionListeners(peerConnection);

      state.localStream?.getTracks().forEach((track) {
        peerConnection.addTrack(track, state.localStream!);
      });

      peerConnection.onIceCandidate = (candidate) {
        _interactor.addCandidateToRoom(
          roomId: roomId,
          candidate: candidate,
          calleeCandidates: true,
        );
      };

      peerConnection.onTrack = (event) {
        event.streams[0].getTracks().forEach((track) async {
          final stream = state.remoteStream ?? await createLocalMediaStream('key');
          emit(state.copyWith(remoteStream: stream..addTrack(track), companionShown: true));
        });
      };

      await peerConnection.setRemoteDescription(sessionDescription);

      final answer = await peerConnection.createAnswer();

      await peerConnection.setLocalDescription(answer);

      emit(state.copyWith(peerConnection: peerConnection));

      await _interactor.setAnswer(roomId: roomId, answer: answer);

      _subscriptions.addAll(
        [
          _interactor
              .getCandidatesAddedToRoomStream(roomId: roomId, calleeCandidates: false)
              .listen(
            (candidates) {
              final peerConnection = state.peerConnection;
              for (final candidate in candidates) {
                peerConnection?.addCandidate(candidate);
              }
              emit(state.copyWith(peerConnection: peerConnection));
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
          emit(
            state.copyWith(peerConnection: state.peerConnection?..setRemoteDescription(answer)),
          );
        } else {
          if (state.remoteStream != null) {
            emit(state.copyWith(clearAll: true));
          }
        }
      }),
      _interactor
          .getCandidatesAddedToRoomStream(roomId: roomId, calleeCandidates: true)
          .listen((candidates) {
        final peerConnection = state.peerConnection;
        for (final candidate in candidates) {
          peerConnection?.addCandidate(candidate);
        }
        emit(state.copyWith(peerConnection: peerConnection));
      }),
    ]);
  }

  void _registerPeerConnectionListeners(RTCPeerConnection peerConnection) {
    peerConnection.onIceGatheringState = (state) {
      print('\x1b[36mICE gathering state changed: $state\x1b[0m');
    };

    peerConnection.onConnectionState = (state) {
      print('\x1b[36mConnection state change: $state\x1b[0m');
    };

    peerConnection.onSignalingState = (state) {
      print('\x1b[36mSignaling state change: $state\x1b[0m');
    };

    peerConnection.onIceGatheringState = (state) {
      print('\x1b[36mICE connection state change: $state\x1b[0m');
    };

    peerConnection.onAddStream = (stream) {
      print('\x1b[36mAdd remote stream\x1b[0m');
      emit(state.copyWith(remoteStream: stream, companionShown: true));
    };
  }
}
