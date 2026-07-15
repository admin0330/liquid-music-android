import 'package:flutter/cupertino.dart';

class AppleMusicPlayButton extends StatefulWidget {
  const AppleMusicPlayButton({
    super.key,
    required this.playing,
    required this.onPressed,
    this.color = const Color(0xFF1D1D1F),
    this.size = 76,
    this.iconSize = 50,
  });

  final bool playing;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final double iconSize;

  @override
  State<AppleMusicPlayButton> createState() => _AppleMusicPlayButtonState();
}

class _AppleMusicPlayButtonState extends State<AppleMusicPlayButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.playing ? '暂停' : '播放',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) {
        setState(() => pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: pressed ? .84 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: SizedBox.square(
          dimension: widget.size,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              reverseDuration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: .72, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: Icon(
                widget.playing
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                key: ValueKey(widget.playing),
                color: widget.color,
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
