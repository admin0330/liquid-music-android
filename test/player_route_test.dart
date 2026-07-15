import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass_demo/main.dart';
import 'package:real_liquid_glass_demo/services/music_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('player uses an opaque, short reverse route', () {
    final controller = MusicController();
    addTearDown(controller.dispose);

    final route = playerRoute(controller);

    expect(route.opaque, isTrue);
    expect(route.transitionDuration, const Duration(milliseconds: 300));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 220));
  });
}
