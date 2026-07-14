import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/music_models.dart';

class SubsonicException implements Exception {
  const SubsonicException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SubsonicService {
  SubsonicService(this.config);

  final SubsonicConfig config;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);
  late final String _salt = _randomSalt();
  late final String _token = md5
      .convert(utf8.encode('${config.password}$_salt'))
      .toString();

  Map<String, String> get _auth => {
    'u': config.username,
    't': _token,
    's': _salt,
    'v': '1.16.1',
    'c': 'liquid_music',
    'f': 'json',
  };

  Uri endpoint(String name, [Map<String, String> params = const {}]) {
    return Uri.parse(
      '${config.normalizedServer}/rest/$name.view',
    ).replace(queryParameters: {..._auth, ...params});
  }

  Uri streamUri(String id) => endpoint('stream', {'id': id, 'format': 'raw'});
  Uri coverUri(String id, {int size = 600}) =>
      endpoint('getCoverArt', {'id': id, 'size': '$size'});

  Future<void> ping() async => _request('ping');

  Future<List<MusicAlbum>> albums({
    String type = 'newest',
    int size = 40,
  }) async {
    final body = await _request('getAlbumList2', {
      'type': type,
      'size': '$size',
    });
    final list = _list(_map(body['albumList2'])['album']);
    return list.map((json) => _album(_map(json))).toList();
  }

  Future<MusicAlbum> album(String id) async {
    final body = await _request('getAlbum', {'id': id});
    final json = _map(body['album']);
    final tracks = _list(
      json['song'],
    ).map((song) => _track(_map(song))).toList();
    return _album(json).copyWith(tracks: tracks);
  }

  Future<List<MusicPlaylist>> playlists() async {
    final body = await _request('getPlaylists');
    return _list(
      _map(body['playlists'])['playlist'],
    ).map((item) => _playlist(_map(item))).toList();
  }

  Future<MusicPlaylist> playlist(String id) async {
    final body = await _request('getPlaylist', {'id': id});
    final json = _map(body['playlist']);
    final tracks = _list(
      json['entry'],
    ).map((song) => _track(_map(song))).toList();
    return _playlist(json).copyWith(tracks: tracks);
  }

  Future<MusicSearchResult> search(String query) async {
    if (query.trim().isEmpty) return const MusicSearchResult();
    final body = await _request('search3', {
      'query': query.trim(),
      'songCount': '50',
      'albumCount': '25',
      'artistCount': '25',
    });
    final result = _map(body['searchResult3']);
    return MusicSearchResult(
      tracks: _list(result['song']).map((e) => _track(_map(e))).toList(),
      albums: _list(result['album']).map((e) => _album(_map(e))).toList(),
      artists: _list(result['artist']).map((e) => _artist(_map(e))).toList(),
    );
  }

  Future<List<MusicTrack>> favorites() async {
    final body = await _request('getStarred2');
    return _list(
      _map(body['starred2'])['song'],
    ).map((e) => _track(_map(e), favorite: true)).toList();
  }

  Future<void> setFavorite(String id, bool value) =>
      _request(value ? 'star' : 'unstar', {'id': id});

  Future<String?> lyricsFor(MusicTrack track) async {
    try {
      final body = await _request('getLyrics', {
        'artist': track.artist,
        'title': track.title,
      });
      return _map(body['lyrics'])['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _request(
    String method, [
    Map<String, String> params = const {},
  ]) async {
    try {
      final request = await _client.getUrl(endpoint(method, params));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SubsonicException('服务器返回 HTTP ${response.statusCode}');
      }
      final root = _map(jsonDecode(text));
      final data = _map(root['subsonic-response']);
      if (data['status'] != 'ok') {
        final error = _map(data['error']);
        throw SubsonicException(error['message'] as String? ?? '音乐服务器请求失败');
      }
      return data;
    } on SocketException {
      throw const SubsonicException('无法连接音乐服务器，请检查地址和网络');
    } on HandshakeException {
      throw const SubsonicException('HTTPS 证书校验失败');
    } on FormatException {
      throw const SubsonicException('服务器返回了无法识别的数据');
    }
  }

  MusicTrack _track(Map<String, dynamic> json, {bool favorite = false}) {
    final id = '${json['id'] ?? ''}';
    final coverId = '${json['coverArt'] ?? json['albumId'] ?? ''}';
    return MusicTrack(
      id: id,
      title: '${json['title'] ?? '未知歌曲'}',
      artist: '${json['artist'] ?? '未知艺人'}',
      album: '${json['album'] ?? '未知专辑'}',
      source: MusicSourceKind.subsonic,
      albumId: json['albumId']?.toString(),
      artistId: json['artistId']?.toString(),
      coverUrl: coverId.isEmpty ? null : coverUri(coverId).toString(),
      playUrl: streamUri(id).toString(),
      suffix:
          json['suffix']?.toString() ??
          json['contentType']?.toString().split('/').last,
      duration: Duration(seconds: _int(json['duration'])),
      bitRate: _intOrNull(json['bitRate']),
      bitDepth: _intOrNull(json['bitDepth']),
      sampleRate: _intOrNull(json['samplingRate']),
      trackNumber: _intOrNull(json['track']),
      size: _intOrNull(json['size']),
      favorite: favorite || json['starred'] != null,
    );
  }

  MusicAlbum _album(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}';
    final coverId = '${json['coverArt'] ?? id}';
    return MusicAlbum(
      id: id,
      name: '${json['name'] ?? json['title'] ?? '未知专辑'}',
      artist: '${json['artist'] ?? '未知艺人'}',
      artistId: json['artistId']?.toString(),
      coverUrl: coverId.isEmpty ? null : coverUri(coverId).toString(),
      year: _intOrNull(json['year']),
      songCount: _int(json['songCount']),
      duration: Duration(seconds: _int(json['duration'])),
    );
  }

  MusicArtist _artist(Map<String, dynamic> json) => MusicArtist(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? '未知艺人'}',
    albumCount: _int(json['albumCount']),
    coverUrl: json['coverArt'] == null
        ? null
        : coverUri('${json['coverArt']}').toString(),
  );

  MusicPlaylist _playlist(Map<String, dynamic> json) => MusicPlaylist(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? '未命名歌单'}',
    songCount: _int(json['songCount']),
    duration: Duration(seconds: _int(json['duration'])),
    coverUrl: json['coverArt'] == null
        ? null
        : coverUri('${json['coverArt']}').toString(),
  );

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};
  static List<dynamic> _list(Object? value) => value is List ? value : const [];
  static int _int(Object? value) => _intOrNull(value) ?? 0;
  static int? _intOrNull(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');
  static String _randomSalt() {
    const chars = 'abcdef0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
