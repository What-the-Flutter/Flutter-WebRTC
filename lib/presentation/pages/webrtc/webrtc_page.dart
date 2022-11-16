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
      return _fullConversation();
    } else if (state.currentUserShown) {
      return _myVideoFullScreen();
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
              await _cubit.openUserMedia();
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
                    await _cubit.openUserMedia();
                    _cubit.joinRoom(
                      _textEditingController.text,
                      _remoteRenderer,
                    );
                  },
            child: const Text('Open camera and Join room'),
          ),
        ],
      ),
    );
  }

  Widget _myVideoFullScreen() {
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
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: _endCallButton(),
          ),
        ),
      ],
    );
  }

  Widget _fullConversation() {
    const size = 0.3;
    final width = MediaQuery.of(context).size.width * size;
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
          right: 20,
          bottom: 20,
          child: Container(
            width: width,
            height: width * _localRenderer.videoWidth / _localRenderer.videoHeight,
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
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: _endCallButton(),
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
}
