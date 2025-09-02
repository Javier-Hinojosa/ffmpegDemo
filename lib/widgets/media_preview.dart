import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/media_utils.dart';

class MediaPreview extends StatelessWidget {
  final String? path;
  final MediaType? mediaType;
  final VideoPlayerController? videoController;
  final bool videoReady;
  final AudioPlayer? audioPlayer;

  const MediaPreview({
    super.key,
    required this.path,
    required this.mediaType,
    required this.videoController,
    required this.videoReady,
    required this.audioPlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || mediaType == null) {
      return const Text('Sin archivo seleccionado. Usa "Seleccionar archivo".');
    }

    switch (mediaType) {
      case MediaType.video:
        if (videoController == null || !videoReady) {
          return const Text('Cargando video...');
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: videoController!.value.aspectRatio,
              child: VideoPlayer(videoController!),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => videoController!.play(),
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () => videoController!.pause(),
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () async {
                    await videoController!.pause();
                    await videoController!.seekTo(Duration.zero);
                  },
                ),
              ],
            )
          ],
        );
      case MediaType.audio:
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => audioPlayer?.play(),
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => audioPlayer?.pause(),
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => audioPlayer?.stop(),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(path!, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        );
      case MediaType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: Image.file(File(path!), fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(path!, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      case MediaType.other:
        return Text('Archivo: $path');
      case null:
        return const SizedBox.shrink();
    }
  }
}

