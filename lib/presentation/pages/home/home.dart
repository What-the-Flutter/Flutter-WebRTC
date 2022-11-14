import 'package:flutter/material.dart';
import 'package:video_streaming/presentation/pages/webrtc/webrtc_page.dart';

/// https://www.100ms.live/blog/flutter-webrtc

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => WebrtcPage()),
              );
            },
            child: const Text('GO'),
          ),
        ],
      ),
    );
  }
}
