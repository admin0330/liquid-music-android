enum MusicSourceKind { local, subsonic }

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.source,
    this.albumId,
    this.artistId,
    this.coverUrl,
    this.playUrl,
    this.localPath,
    this.localCoverPath,
    this.suffix,
    this.duration = Duration.zero,
    this.bitRate,
    this.sampleRate,
    this.bitDepth,
    this.trackNumber,
    this.size,
    this.lyrics,
    this.favorite = false,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final MusicSourceKind source;
  final String? albumId;
  final String? artistId;
  final String? coverUrl;
  final String? playUrl;
  final String? localPath;
  final String? localCoverPath;
  final String? suffix;
  final Duration duration;
  final int? bitRate;
  final int? sampleRate;
  final int? bitDepth;
  final int? trackNumber;
  final int? size;
  final String? lyrics;
  final bool favorite;

  Uri get playbackUri {
    if (localPath != null && localPath!.isNotEmpty) return Uri.file(localPath!);
    return Uri.parse(playUrl!);
  }

  Uri? get artworkUri {
    if (localCoverPath != null && localCoverPath!.isNotEmpty) {
      return Uri.file(localCoverPath!);
    }
    if (coverUrl != null && coverUrl!.isNotEmpty) return Uri.parse(coverUrl!);
    return null;
  }

  bool get isLossless {
    final format = suffix?.toLowerCase();
    return const {'flac', 'alac', 'wav', 'aiff', 'aif', 'ape'}.contains(format);
  }

  String get qualityLabel {
    final parts = <String>[(suffix ?? 'audio').toUpperCase()];
    if (bitDepth != null) parts.add('$bitDepth-bit');
    if (sampleRate != null) {
      final khz = sampleRate! / 1000;
      parts.add(
        '${khz == khz.roundToDouble() ? khz.toStringAsFixed(0) : khz.toStringAsFixed(1)} kHz',
      );
    } else if (bitRate != null) {
      final kbps = bitRate! > 10000 ? bitRate! ~/ 1000 : bitRate!;
      parts.add('$kbps kbps');
    }
    return parts.join(' · ');
  }

  MusicTrack copyWith({
    String? localPath,
    String? localCoverPath,
    String? lyrics,
    bool? favorite,
  }) => MusicTrack(
    id: id,
    title: title,
    artist: artist,
    album: album,
    source: source,
    albumId: albumId,
    artistId: artistId,
    coverUrl: coverUrl,
    playUrl: playUrl,
    localPath: localPath ?? this.localPath,
    localCoverPath: localCoverPath ?? this.localCoverPath,
    suffix: suffix,
    duration: duration,
    bitRate: bitRate,
    sampleRate: sampleRate,
    bitDepth: bitDepth,
    trackNumber: trackNumber,
    size: size,
    lyrics: lyrics ?? this.lyrics,
    favorite: favorite ?? this.favorite,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'source': source.name,
    'albumId': albumId,
    'artistId': artistId,
    'coverUrl': coverUrl,
    'playUrl': playUrl,
    'localPath': localPath,
    'localCoverPath': localCoverPath,
    'suffix': suffix,
    'durationMs': duration.inMilliseconds,
    'bitRate': bitRate,
    'sampleRate': sampleRate,
    'bitDepth': bitDepth,
    'trackNumber': trackNumber,
    'size': size,
    'lyrics': lyrics,
    'favorite': favorite,
  };

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
    id: json['id'] as String,
    title: json['title'] as String? ?? '未知歌曲',
    artist: json['artist'] as String? ?? '未知艺人',
    album: json['album'] as String? ?? '未知专辑',
    source: MusicSourceKind.values.byName(
      json['source'] as String? ?? MusicSourceKind.local.name,
    ),
    albumId: json['albumId'] as String?,
    artistId: json['artistId'] as String?,
    coverUrl: json['coverUrl'] as String?,
    playUrl: json['playUrl'] as String?,
    localPath: json['localPath'] as String?,
    localCoverPath: json['localCoverPath'] as String?,
    suffix: json['suffix'] as String?,
    duration: Duration(
      milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
    ),
    bitRate: (json['bitRate'] as num?)?.toInt(),
    sampleRate: (json['sampleRate'] as num?)?.toInt(),
    bitDepth: (json['bitDepth'] as num?)?.toInt(),
    trackNumber: (json['trackNumber'] as num?)?.toInt(),
    size: (json['size'] as num?)?.toInt(),
    lyrics: json['lyrics'] as String?,
    favorite: json['favorite'] as bool? ?? false,
  );
}

class MusicAlbum {
  const MusicAlbum({
    required this.id,
    required this.name,
    required this.artist,
    this.artistId,
    this.coverUrl,
    this.year,
    this.songCount = 0,
    this.duration = Duration.zero,
    this.tracks = const [],
  });

  final String id;
  final String name;
  final String artist;
  final String? artistId;
  final String? coverUrl;
  final int? year;
  final int songCount;
  final Duration duration;
  final List<MusicTrack> tracks;

  MusicAlbum copyWith({List<MusicTrack>? tracks}) => MusicAlbum(
    id: id,
    name: name,
    artist: artist,
    artistId: artistId,
    coverUrl: coverUrl,
    year: year,
    songCount: tracks?.length ?? songCount,
    duration: duration,
    tracks: tracks ?? this.tracks,
  );
}

class MusicArtist {
  const MusicArtist({
    required this.id,
    required this.name,
    this.albumCount = 0,
    this.coverUrl,
  });
  final String id;
  final String name;
  final int albumCount;
  final String? coverUrl;
}

class MusicPlaylist {
  const MusicPlaylist({
    required this.id,
    required this.name,
    this.songCount = 0,
    this.duration = Duration.zero,
    this.coverUrl,
    this.tracks = const [],
  });
  final String id;
  final String name;
  final int songCount;
  final Duration duration;
  final String? coverUrl;
  final List<MusicTrack> tracks;

  MusicPlaylist copyWith({List<MusicTrack>? tracks}) => MusicPlaylist(
    id: id,
    name: name,
    songCount: tracks?.length ?? songCount,
    duration: duration,
    coverUrl: coverUrl,
    tracks: tracks ?? this.tracks,
  );
}

class MusicSearchResult {
  const MusicSearchResult({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
  });
  final List<MusicTrack> tracks;
  final List<MusicAlbum> albums;
  final List<MusicArtist> artists;
}

class SubsonicConfig {
  const SubsonicConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
  });
  final String serverUrl;
  final String username;
  final String password;
  String get normalizedServer =>
      serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
}
