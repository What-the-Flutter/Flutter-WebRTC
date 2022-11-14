import 'package:flutter/material.dart';
import 'package:video_streaming/presentation/pages/home/home.dart';

class VideoStreamingApp extends StatelessWidget {
  const VideoStreamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'VideoStreamingApp'),
    );
  }
}
