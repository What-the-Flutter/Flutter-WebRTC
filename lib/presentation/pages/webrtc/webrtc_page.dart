import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_streaming/di/injector.dart';
import 'package:video_streaming/presentation/pages/webrtc/webrtc_cubit.dart';
import 'package:video_streaming/presentation/pages/webrtc/webrtc_state.dart';

class WebrtcPage extends StatefulWidget {
  WebrtcPage({Key? key}) : super(key: key);

  @override
  _WebrtcPageState createState() => _WebrtcPageState();
}

class _WebrtcPageState extends State<WebrtcPage> {
  static const int roomIdLength = 20;
  static const double _defaultPadding = 20;

  final WebrtcCubit _cubit = i.get();

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    _textEditingController.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebrtcCubit, WebrtcState>(
      bloc: _cubit,
      listenWhen: (prev, next) =>
          prev.localStream != next.localStream ||
          prev.remoteStream != next.remoteStream ||
          prev.roomId != next.roomId ||
          next.cleared,
      listener: (context, state) {
        if (state.cleared) {
          _localRenderer.initialize();
          _remoteRenderer.initialize();
          _textEditingController.text = '';
        } else {
          if (state.localStream != null || _localRenderer.srcObject != state.localStream) {
            _localRenderer.srcObject = state.localStream!;
          }
          if (state.remoteStream != null || _remoteRenderer.srcObject != state.remoteStream) {
            _remoteRenderer.srcObject = state.remoteStream!;
          }
          if (state.roomId != null && state.roomId != _textEditingController.text) {
            _textEditingController.text = state.roomId!;
          }
        }
        setState(() {});
      },
      builder: (context, state) {
        return Scaffold(
          body: _getContent(state),
        );
      },
    );
  }

  Widget _getContent(WebrtcState state) {
    if (state.currentUserShown && state.companionShown) {
      return _fullConversation(
        cameraEnabled: !state.videoDisabled,
        microEnabled: !state.audioDisabled,
      );
    } else if (state.currentUserShown) {
      return _myVideoFullScreen(
        cameraEnabled: !state.videoDisabled,
        microEnabled: !state.audioDisabled,
      );
    } else {
      return _emptyPage();
    }
  }

  Widget _emptyPage() {
    final buttonIsNotActive =
        _textEditingController.text.isEmpty || _textEditingController.text.length != roomIdLength;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              await _cubit.enableUserMediaStream();
              await _cubit.createRoom();
              setState(() {});
            },
            child: const Text('Open camera and Create room'),
          ),
          const SizedBox(height: 32),
          const Text('Join the following Room: '),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: TextField(
              maxLength: roomIdLength,
              controller: _textEditingController,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: buttonIsNotActive
                ? null
                : const ButtonStyle().copyWith(
                    backgroundColor: const MaterialStatePropertyAll(Colors.grey),
                  ),
            onPressed: buttonIsNotActive
                ? null
                : () async {
                    await _cubit.enableUserMediaStream();
                    _cubit.joinRoom(_textEditingController.text);
                  },
            child: const Text('Open camera and Join room'),
          ),
        ],
      ),
    );
  }

  Widget _myVideoFullScreen({
    required bool cameraEnabled,
    required bool microEnabled,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: RTCVideoView(
            _localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).viewPadding.top,
          left: 0,
          right: 0,
          child: TextField(
            readOnly: true,
            textAlign: TextAlign.center,
            controller: _textEditingController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        Positioned(
          bottom: _defaultPadding,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ..._mediaButtons(cameraEnabled: cameraEnabled, microEnabled: microEnabled),
              _endCallButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fullConversation({
    required bool cameraEnabled,
    required bool microEnabled,
  }) {
    const previewSize = 0.3;
    final previewWidth = MediaQuery.of(context).size.width * previewSize;
    return Stack(
      children: [
        Positioned.fill(
          child: RTCVideoView(
            _remoteRenderer,
            mirror: false,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        Positioned(
          right: _defaultPadding,
          bottom: _defaultPadding,
          child: Container(
            width: previewWidth,
            height: previewWidth * _localRenderer.videoWidth / _localRenderer.videoHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.blueAccent),
            ),
            clipBehavior: Clip.hardEdge,
            child: RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
        Positioned(
          bottom: _defaultPadding,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ..._mediaButtons(cameraEnabled: cameraEnabled, microEnabled: microEnabled),
              _endCallButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _endCallButton() {
    return FloatingActionButton(
      onPressed: () => _cubit.hangUp(_localRenderer),
      backgroundColor: Colors.red,
      child: const Icon(
        Icons.phone,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _mediaButtons({required bool microEnabled, required bool cameraEnabled}) {
    return [
      FloatingActionButton(
        onPressed: () {
          if (cameraEnabled) {
            _cubit.disableVideo();
          } else {
            _cubit.enableVideo();
          }
        },
        backgroundColor: cameraEnabled ? Colors.blueAccent : Colors.white,
        child: Icon(
          cameraEnabled ? Icons.videocam : Icons.videocam_off,
          color: cameraEnabled ? Colors.white : Colors.red,
        ),
      ),
      FloatingActionButton(
        onPressed: () {
          if (microEnabled) {
            _cubit.disableAudio();
          } else {
            _cubit.enableAudio();
          }
        },
        backgroundColor: microEnabled ? Colors.blueAccent : Colors.white,
        child: Icon(
          microEnabled ? Icons.mic : Icons.mic_off,
          color: microEnabled ? Colors.white : Colors.red,
        ),
      ),
    ];
  }
}
