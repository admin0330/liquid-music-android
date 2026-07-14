import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/music_models.dart';

class DownloadService {
  Future<MusicTrack> download(
    MusicTrack track, {
    void Function(double progress)? onProgress,
  }) async {
    if (track.localPath != null || track.playUrl == null) return track;
    final support = await getApplicationSupportDirectory();
    final folder = Directory('${support.path}${Platform.pathSeparator}offline');
    await folder.create(recursive: true);
    final ext = (track.suffix?.isNotEmpty == true ? track.suffix : 'audio')!;
    final target = File(
      '${folder.path}${Platform.pathSeparator}${track.id}.$ext',
    );
    final request = await HttpClient().getUrl(Uri.parse(track.playUrl!));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('下载失败：HTTP ${response.statusCode}');
    }
    final sink = target.openWrite();
    var received = 0;
    final total = response.contentLength;
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.close();
    }
    return track.copyWith(localPath: target.path);
  }
}
