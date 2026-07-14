import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass_demo/github_update_service.dart';

void main() {
  group('compareVersions', () {
    test('compares semantic numeric parts', () {
      expect(compareVersions('1.0.1', '1.0.0'), isPositive);
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.2.0', '1.10.0'), isNegative);
      expect(compareVersions('2.0', '1.9.9'), isPositive);
    });
  });

  test('parses the first APK asset from a GitHub release', () {
    final release = GitHubRelease.fromJson({
      'tag_name': 'v1.2.3',
      'body': 'Changes',
      'assets': [
        {
          'name': 'demo.apk',
          'browser_download_url': 'https://example.com/demo.apk',
        },
      ],
    });

    expect(release.version, '1.2.3');
    expect(release.notes, 'Changes');
    expect(release.apkUrl, 'https://example.com/demo.apk');
  });
}
