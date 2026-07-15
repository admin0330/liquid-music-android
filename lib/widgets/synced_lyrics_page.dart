import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/music_models.dart';
import '../services/music_controller.dart';
import 'apple_music_play_button.dart';

class SyncedLyricsPage extends StatefulWidget {
  const SyncedLyricsPage({
    super.key,
    required this.controller,
    required this.track,
  });

  final MusicController controller;
  final MusicTrack track;

  @override
  State<SyncedLyricsPage> createState() => _SyncedLyricsPageState();
}

class _SyncedLyricsPageState extends State<SyncedLyricsPage> {
  final scroll = ScrollController();
  StreamSubscription<Duration>? positionSubscription;
  List<_LyricLine> lines = const [];
  List<GlobalKey> lineKeys = const [];
  Duration position = Duration.zero;
  bool loading = true;
  int activeLine = -1;

  @override
  void initState() {
    super.initState();
    _load();
    positionSubscription = widget.controller.playback.positionStream.listen(
      _onPosition,
    );
  }

  Future<void> _load() async {
    final raw = await widget.controller.lyricsFor(widget.track);
    final duration = widget.track.duration > Duration.zero
        ? widget.track.duration
        : const Duration(minutes: 3, seconds: 30);
    final parsed = _LyricsParser.parse(raw ?? '', duration);
    if (!mounted) return;
    setState(() {
      lines = parsed;
      lineKeys = List.generate(parsed.length, (_) => GlobalKey());
      loading = false;
    });
    _onPosition(widget.controller.playback.player.position);
  }

  void _onPosition(Duration value) {
    if (!mounted) return;
    final next = _activeLineAt(value);
    final changed = next != activeLine;
    setState(() {
      position = value;
      activeLine = next;
    });
    if (changed && next >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = lineKeys[next].currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            alignment: .42,
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  int _activeLineAt(Duration value) {
    var result = -1;
    for (var i = 0; i < lines.length; i++) {
      if (value >= lines[i].start) result = i;
      if (value < lines[i].start) break;
    }
    return result;
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller.playback,
    builder: (context, _) {
      final playback = widget.controller.playback;
      final track = playback.current ?? widget.track;
      return Scaffold(
        backgroundColor: const Color(0xFF1B1014),
        body: Stack(
          children: [
            const Positioned.fill(child: _LyricsBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  _CompactHeader(track: track),
                  Expanded(child: _lyrics()),
                  _PlaybackBar(controller: widget.controller),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _lyrics() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (lines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '这首歌曲没有可用歌词\n本地歌曲支持内嵌 LRC 与逐字时间标签',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 18, height: 1.5),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 34),
      itemCount: lines.length,
      itemBuilder: (_, index) {
        final distance = (index - activeLine).abs();
        return Padding(
          key: lineKeys[index],
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _KaraokeLine(
            line: lines[index],
            active: index == activeLine,
            distance: distance,
            onTap: () => widget.controller.playback.seek(lines[index].start),
          ),
        );
      },
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.track});
  final MusicTrack track;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        _SmallArtwork(track: track),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BottomBackButton extends StatelessWidget {
  const _BottomBackButton();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 42,
    child: IconButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.pop(context),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .12),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(CupertinoIcons.chevron_down, size: 21),
    ),
  );
}

class _SmallArtwork extends StatelessWidget {
  const _SmallArtwork({required this.track});
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    Widget image = const ColoredBox(color: Color(0xFF5A303A));
    final path = track.localCoverPath;
    if (path != null && path.isNotEmpty) {
      image = Image.file(File(path), fit: BoxFit.cover);
    } else if (track.coverUrl?.isNotEmpty == true) {
      image = Image.network(track.coverUrl!, fit: BoxFit.cover);
    }
    return Hero(
      tag: 'lyrics-artwork-${track.id}',
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(dimension: 58, child: image),
      ),
    );
  }
}

class _KaraokeLine extends StatelessWidget {
  const _KaraokeLine({
    required this.line,
    required this.active,
    required this.distance,
    required this.onTap,
  });

  final _LyricLine line;
  final bool active;
  final int distance;
  final VoidCallback onTap;

  double get blur => switch (distance) {
    0 => 0,
    1 => .35,
    2 => .75,
    3 => 1.15,
    _ => 1.65,
  };

  double get opacity => switch (distance) {
    0 => 1,
    1 => .48,
    2 => .28,
    3 => .17,
    _ => .1,
  };

  double get scale => switch (distance) {
    0 => 1,
    1 => .985,
    2 => .97,
    3 => .955,
    _ => .94,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scale,
        alignment: Alignment.centerLeft,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOut,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: Colors.white,
                fontSize: switch (distance) {
                  0 => 31,
                  1 => 28,
                  2 => 26,
                  _ => 25,
                },
                height: 1.18,
                fontWeight: FontWeight.w800,
                letterSpacing: active ? -.7 : -.5,
                shadows: active
                    ? const [Shadow(color: Color(0x55FFFFFF), blurRadius: 18)]
                    : null,
              ),
              child: Text(line.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({required this.controller});
  final MusicController controller;

  @override
  Widget build(BuildContext context) {
    final playback = controller.playback;
    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(left: 16, child: _BottomBackButton()),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: playback.previous,
                color: Colors.white,
                iconSize: 36,
                icon: const Icon(CupertinoIcons.backward_fill),
              ),
              const SizedBox(width: 12),
              AppleMusicPlayButton(
                playing: playback.playing,
                onPressed: playback.toggle,
                color: Colors.white,
                size: 68,
                iconSize: 46,
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: playback.next,
                color: Colors.white,
                iconSize: 36,
                icon: const Icon(CupertinoIcons.forward_fill),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LyricsBackdrop extends StatelessWidget {
  const _LyricsBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5B2936), Color(0xFF26151B), Color(0xFF111114)],
      ),
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: const SizedBox.expand(),
    ),
  );
}

class _LyricLine {
  const _LyricLine({
    required this.text,
    required this.start,
    required this.end,
  });
  final String text;
  final Duration start;
  final Duration end;
}

abstract final class _LyricsParser {
  static final _lineStamp = RegExp(r'^\[(\d{1,3}):(\d{2}(?:\.\d+)?)\](.*)$');
  static final _wordStamp = RegExp(r'<(\d{1,3}):(\d{2}(?:\.\d+)?)>');
  static final _metadata = RegExp(
    r'^\[(ar|al|ti|by|offset|re|ve):',
    caseSensitive: false,
  );

  static List<_LyricLine> parse(String raw, Duration duration) {
    final source = raw
        .replaceAll('\r', '')
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !_metadata.hasMatch(e))
        .toList();
    if (source.isEmpty) return const [];

    final stamped = <({Duration start, String value})>[];
    final plain = <String>[];
    for (final value in source) {
      final match = _lineStamp.firstMatch(value);
      if (match == null) {
        plain.add(value.replaceAll(RegExp(r'<[^>]+>'), ''));
      } else {
        stamped.add((
          start: _time(match.group(1)!, match.group(2)!),
          value: match.group(3)!.trim(),
        ));
      }
    }
    if (stamped.isEmpty) return _plainLines(plain, duration);
    stamped.sort((a, b) => a.start.compareTo(b.start));
    return List.generate(stamped.length, (index) {
      final item = stamped[index];
      final end = index + 1 < stamped.length
          ? stamped[index + 1].start
          : duration;
      return _line(item.value, item.start, end);
    });
  }

  static List<_LyricLine> _plainLines(List<String> values, Duration duration) {
    final slice = Duration(
      milliseconds: duration.inMilliseconds ~/ values.length,
    );
    return List.generate(values.length, (index) {
      final start = slice * index;
      final end = index == values.length - 1 ? duration : slice * (index + 1);
      return _line(values[index], start, end);
    });
  }

  static _LyricLine _line(String value, Duration start, Duration end) {
    final text = value.replaceAll(_wordStamp, '').trim();
    return _LyricLine(text: text, start: start, end: end);
  }

  static Duration _time(String minutes, String seconds) => Duration(
    milliseconds:
        int.parse(minutes) * 60000 + (double.parse(seconds) * 1000).round(),
  );
}
