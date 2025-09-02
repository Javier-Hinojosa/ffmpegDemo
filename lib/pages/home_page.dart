import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import '../utils/media_utils.dart';
import '../utils/paths.dart';
import '../widgets/media_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _output = '';
  bool _isProcessing = false;
  String? _selectedPath;
  MediaType? _mediaType;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  AudioPlayer? _audioPlayer;
  String? _downloadsPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initDownloads();
  }

  Future<void> _initDownloads() async {
    final p = await getDownloadsPath();
    setState(() { _downloadsPath = p; });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withReadStream: true, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    String? path = file.path;

    if (path == null) {
      final downloads = await getDownloadsPath();
      final safeName = (file.name.isNotEmpty ? file.name : 'picked_${DateTime.now().millisecondsSinceEpoch}');
      final destPath = '$downloads/$safeName';
      final outFile = File(destPath);
      if (file.readStream != null) {
        final sink = outFile.openWrite();
        await for (final chunk in file.readStream!) {
          sink.add(chunk);
        }
        await sink.close();
      } else if (file.bytes != null) {
        await outFile.writeAsBytes(file.bytes!);
      } else {
        return;
      }
      path = destPath;
    }

    await _videoController?.pause();
    await _videoController?.dispose();
    _videoController = null;
    _videoReady = false;
    await _audioPlayer?.stop();

    final type = inferMediaType(path);

    setState(() {
      _selectedPath = path;
      _mediaType = type;
    });

    if (type == MediaType.video) {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      controller.setLooping(true);
      setState(() {
        _videoController = controller;
        _videoReady = controller.value.isInitialized;
      });
    } else if (type == MediaType.audio) {
      try { await _audioPlayer?.setFilePath(path); } catch (_) {}
    }
  }

  Future<void> _runFFmpegCommand(String command) async {
    setState(() { _isProcessing = true; _output = 'Ejecutando...'; });
    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();
        final state = await session.getState();
        setState(() {
          _output += '\n\nFinalizado. Estado: $state, Código: $returnCode';
          _isProcessing = false;
        });
      },
      (log) {
        setState(() { _output += '\n${log.getMessage()}'; });
      },
      (statistics) {
        final time = statistics.getTime();
        setState(() { _output += '\n[stats] time=${(time / 1000).toStringAsFixed(2)}s'; });
      },
    );
  }

  Future<void> _convertVideo() async {
    if (_selectedPath == null) { setState(() { _output = 'Primero selecciona un archivo.'; }); return; }
    final downloads = await getDownloadsPath();
    final input = _selectedPath!;
    final outPath = await uniquePath(downloads, 'video_converted.mp4');
    await _runFFmpegCommand('-y -i "$input" -vf "scale=320:240" -c:v libx264 -crf 23 -preset veryfast "$outPath"');
    setState(() { _selectedPath = outPath; _mediaType = MediaType.video; });
    try {
      final controller = VideoPlayerController.file(File(outPath));
      await controller.initialize();
      controller.setLooping(true);
      setState(() {
        _videoController?.dispose();
        _videoController = controller;
        _videoReady = controller.value.isInitialized;
      });
    } catch (_) {}
  }

  Future<void> _extractImage() async {
    if (_selectedPath == null) { setState(() { _output = 'Primero selecciona un archivo.'; }); return; }
    final downloads = await getDownloadsPath();
    final input = _selectedPath!;
    final outPath = await uniquePath(downloads, 'frame.jpg');
    await _runFFmpegCommand('-y -i "$input" -ss 00:00:01 -vframes 1 "$outPath"');
    setState(() { _selectedPath = outPath; _mediaType = MediaType.image; });
  }

  Future<void> _extractAudioMp3() async {
    if (_selectedPath == null) { setState(() { _output = 'Primero selecciona un archivo.'; }); return; }
    final downloads = await getDownloadsPath();
    final input = _selectedPath!;
    final outPath = await uniquePath(downloads, 'audio.mp3');
    await _runFFmpegCommand('-y -i "$input" -vn -c:a libmp3lame -q:a 2 "$outPath"');
    setState(() { _selectedPath = outPath; _mediaType = MediaType.audio; });
    try { await _audioPlayer?.setFilePath(outPath); } catch (_) {}
  }

  Future<void> _getMetadata() async {
    if (_selectedPath == null) { setState(() { _output = 'Primero selecciona un archivo.'; }); return; }
    setState(() { _isProcessing = true; _output = 'Obteniendo metadatos...'; });
    await FFprobeKit.getMediaInformation(_selectedPath!).then((infoSession) async {
      final info = await infoSession.getMediaInformation();
      setState(() {
        _output = info?.getAllProperties().toString() ?? 'No se encontraron metadatos.';
        _isProcessing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('FFmpeg Kit Demo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_downloadsPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Guardando en: $_downloadsPath', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ListView(
                shrinkWrap: true,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Seleccionar archivo'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _runFFmpegCommand('-version'),
                    child: const Text('Versión FFmpeg'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _convertVideo,
                    child: const Text('Convertir video (320x240)'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _extractImage,
                    child: const Text('Extraer imagen de video'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _extractAudioMp3,
                    child: const Text('Extraer audio (MP3)'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _getMetadata,
                    child: const Text('Obtener metadatos'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MediaPreview(
                path: _selectedPath,
                mediaType: _mediaType,
                videoController: _videoController,
                videoReady: _videoReady,
                audioPlayer: _audioPlayer,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: SingleChildScrollView(child: Text(_output, style: const TextStyle(fontSize: 12))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

