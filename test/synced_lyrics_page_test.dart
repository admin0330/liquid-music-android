import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass_demo/models/music_models.dart';
import 'package:real_liquid_glass_demo/services/music_controller.dart';
import 'package:real_liquid_glass_demo/widgets/synced_lyrics_page.dart';

void main() {
  testWidgets('a downward drag from the top dismisses the lyrics page', (
    tester,
  ) async {
    final controller = MusicController();
    addTearDown(controller.dispose);
    const track = MusicTrack(
      id: 'lyrics-test',
      title: '愛琴海',
      artist: '周杰倫',
      album: '太陽之子',
      source: MusicSourceKind.local,
      duration: Duration(minutes: 3, seconds: 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-lyrics'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SyncedLyricsPage(
                      controller: controller,
                      track: track,
                      initialLyrics:
                          '[00:00.00]第一行\n[00:05.00]第二行\n[00:10.00]第三行',
                    ),
                  ),
                ),
                child: const Text('打开歌词'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-lyrics')));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.chevron_down), findsNothing);
    final dismissRegion = find.byKey(
      const ValueKey('lyrics-top-dismiss-region'),
    );
    expect(dismissRegion, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(dismissRegion));
    await gesture.moveBy(const Offset(0, 120));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('open-lyrics')), findsOneWidget);
    expect(dismissRegion, findsNothing);
  });
}
