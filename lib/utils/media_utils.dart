enum MediaType { video, audio, image, other }

MediaType inferMediaType(String path) {
  final ext = path.split('.').last.toLowerCase();
  const videoExt = ['mp4','mov','m4v','mkv','webm','avi'];
  const audioExt = ['mp3','aac','m4a','wav','flac','ogg'];
  const imageExt = ['jpg','jpeg','png','bmp','webp'];
  if (videoExt.contains(ext)) return MediaType.video;
  if (audioExt.contains(ext)) return MediaType.audio;
  if (imageExt.contains(ext)) return MediaType.image;
  return MediaType.other;
}
