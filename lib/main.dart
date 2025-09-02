import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const FFmpegDemoApp());
}

class FFmpegDemoApp extends StatelessWidget {
  const FFmpegDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFmpeg Kit Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
