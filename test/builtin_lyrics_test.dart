import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass_demo/data/builtin_lyrics.dart';

void main() {
  test('matches 愛琴海 in traditional and simplified Chinese', () {
    expect(
      builtinLyricsFor(title: '愛琴海', artist: '周杰倫'),
      startsWith('[00:14.16]'),
    );
    expect(
      builtinLyricsFor(title: '爱琴海', artist: 'Jay Chou'),
      contains('[03:19.32]'),
    );
  });

  test('does not attach the lyrics to another track', () {
    expect(builtinLyricsFor(title: '晴天', artist: '周杰倫'), isNull);
  });
}
