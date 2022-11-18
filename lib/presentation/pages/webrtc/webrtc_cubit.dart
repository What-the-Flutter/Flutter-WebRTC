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

  Future<void> createRoom() async {
    await _createPeerConnection();

    final offer = await state.peerConnection!.createOffer();
    final roomId = await _interactor.createRoom(offer: offer);
    _registerPeerConnectionListeners(roomId);

    state.localStream?.getTracks().forEach((track) {
      state.peerConnection!.addTrack(track, state.localStream!);
    });

    Logger.printGreen(
      message: 'Room $roomId created with offer',
      filename: 'webrtc_cubit',
      method: 'createRoom',
      line: 39,
    );
    emit(state.copyWith(roomId: roomId));

    await state.peerConnection!.setLocalDescription(offer);

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
      _interactor.getCandidatesAddedToRoomStream(roomId: roomId, listenCaller: false).listen(
        (candidates) {
          for (final candidate in candidates) {
            state.peerConnection?.addCandidate(candidate);
          }
        },
      ),
    ]);
  }

  Future<void> joinRoom(String roomId) async {
    final sessionDescription = await _interactor.getRoomOfferIfExists(roomId: roomId);

    if (sessionDescription != null) {
      await _createPeerConnection();

      _registerPeerConnectionListeners(roomId);

      state.localStream?.getTracks().forEach((track) {
        state.peerConnection!.addTrack(track, state.localStream!);
      });

      await state.peerConnection!.setRemoteDescription(sessionDescription);
      final answer = await state.peerConnection!.createAnswer();
      Logger.printYellow(
        message: 'Answer (Session Description Protocol package) created',
        filename: 'webrtc_cubit',
        method: 'joinRoom',
        line: 82,
      );

      await state.peerConnection!.setLocalDescription(answer);
      await _interactor.setAnswer(roomId: roomId, answer: answer);

      _subscriptions.addAll(
        [
          _interactor.getCandidatesAddedToRoomStream(roomId: roomId, listenCaller: true).listen(
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
          ),
        ],
      );
    }
  }

  Future<void> _createPeerConnection() async {
    final peerConnection = await createPeerConnection(_configuration);
    Logger.printGreen(
      message: 'Peer Connection created',
      filename: 'webrtc_cubit',
      method: 'createRoom',
      line: 115,
    );
    emit(state.copyWith(peerConnection: peerConnection));
  }

  Future<void> enableUserMediaStream() async {
    var stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    emit(
      state.copyWith(
        localStream: stream,
        currentUserShown: true,
      ),
    );
  }

  void enableVideo() {
    if (state.videoDisabled) {
      state.localStream?.getVideoTracks().forEach((track) => track.enabled = true);
      emit(state.copyWith(videoDisabled: false));
    }
  }

  void disableVideo() {
    if (!state.videoDisabled) {
      state.localStream?.getVideoTracks().forEach((track) => track.enabled = false);
      emit(state.copyWith(videoDisabled: true));
    }
  }

  void enableAudio() {
    if (state.audioDisabled) {
      state.localStream?.getAudioTracks().forEach((track) => track.enabled = true);
      emit(state.copyWith(audioDisabled: false));
    }
  }

  void disableAudio() {
    if (!state.audioDisabled) {
      state.localStream?.getAudioTracks().forEach((track) => track.enabled = false);
      emit(state.copyWith(audioDisabled: true));
    }
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

  void _registerPeerConnectionListeners(String roomId) {
    state.peerConnection!.onIceCandidate = (candidate) {
      Logger.printCyan(
        message: 'ICE candidate received: ${candidate.candidate}',
        filename: 'webrtc_cubit',
        method: 'joinRoom(onIceCandidate)',
        line: 190,
      );
      _interactor.addCandidateToRoom(roomId: roomId, candidate: candidate);
    };

    state.peerConnection!.onAddStream = (stream) {
      Logger.printBlue(
        message: 'Remote stream added',
        filename: 'webrtc_cubit',
        method: '_registerPeerConnectionListeners',
        line: 200,
      );
      emit(state.copyWith(remoteStream: stream, companionShown: true));
    };

    state.peerConnection!.onTrack = (event) {
      Logger.printCyan(
        message: 'Track is added to the connection',
        filename: 'webrtc_cubit',
        method: 'joinRoom(onTrack)',
        line: 210,
      );
      event.streams[0].getTracks().forEach((track) => state.remoteStream?.addTrack(track));
    };
  }
}
