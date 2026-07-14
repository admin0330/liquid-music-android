import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class GitHubUpdateService {
  static const _channel = MethodChannel('real_liquid_glass_demo/updater');
  static const _latestRelease =
      'https://api.github.com/repos/admin0330/real-liquid-glass-android-demo/releases/latest';

  Future<String> currentVersion() async =>
      await _channel.invokeMethod<String>('getAppVersion') ?? '0.0.0';

  Future<UpdateCheckResult> check() async {
    final current = await currentVersion();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(Uri.parse(_latestRelease));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'liquid-music-android');
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw UpdateException('GitHub 返回 ${response.statusCode}，请稍后再试');
      }
      final release = GitHubRelease.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
      return UpdateCheckResult(
        currentVersion: current,
        release: release,
        hasUpdate: compareVersions(release.version, current) > 0,
      );
    } on SocketException {
      throw const UpdateException('无法连接 GitHub，请检查网络');
    } on FormatException {
      throw const UpdateException('GitHub Release 数据格式无效');
    } finally {
      client.close(force: true);
    }
  }

  Future<InstallStartState> downloadAndInstall(String apkUrl) async {
    final value = await _channel.invokeMethod<String>('downloadAndInstall', {
      'url': apkUrl,
    });
    return value == 'permissionRequired'
        ? InstallStartState.permissionRequired
        : InstallStartState.started;
  }
}

class GitHubRelease {
  const GitHubRelease({
    required this.version,
    required this.notes,
    required this.apkUrl,
  });
  final String version;
  final String notes;
  final String apkUrl;

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final assets = (json['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    Map<String, dynamic>? apk;
    for (final asset in assets) {
      if ((asset['name'] as String? ?? '').toLowerCase().endsWith('.apk')) {
        apk = asset;
        break;
      }
    }
    final url = apk?['browser_download_url'] as String? ?? '';
    if (tag.isEmpty || url.isEmpty) {
      throw const FormatException('Release is missing a tag or APK asset');
    }
    return GitHubRelease(
      version: tag.replaceFirst(RegExp(r'^[vV]'), ''),
      notes: json['body'] as String? ?? '',
      apkUrl: url,
    );
  }
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.hasUpdate,
    this.release,
  });
  final String currentVersion;
  final bool hasUpdate;
  final GitHubRelease? release;
}

enum InstallStartState { started, permissionRequired }

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

int compareVersions(String left, String right) {
  List<int> parts(String value) => value
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
  final a = parts(left);
  final b = parts(right);
  final length = mathMax(a.length, b.length);
  for (var i = 0; i < length; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}

int mathMax(int a, int b) => a > b ? a : b;
