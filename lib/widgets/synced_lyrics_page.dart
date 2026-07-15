import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/music_models.dart';
import '../services/music_controller.dart';

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
      padding: const EdgeInsets.fromLTRB(26, 100, 26, 180),
      itemCount: lines.length,
      itemBuilder: (_, index) {
        final distance = (index - activeLine).abs();
        return Padding(
          key: lineKeys[index],
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _KaraokeLine(
            line: lines[index],
            position: position,
            active: index == activeLine,
            near: distance == 1,
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
    padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
    child: Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .12),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(CupertinoIcons.chevron_down),
        ),
        const Spacer(),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _SmallArtwork(track: track),
      ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(dimension: 58, child: image),
    );
  }
}

class _KaraokeLine extends StatelessWidget {
  const _KaraokeLine({
    required this.line,
    required this.position,
    required this.active,
    required this.near,
    required this.onTap,
  });

  final _LyricLine line;
  final Duration position;
  final bool active;
  final bool near;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return GestureDetector(
        onTap: onTap,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: near ? .35 : .9,
            sigmaY: near ? .35 : .9,
          ),
          child: AnimatedOpacity(
            opacity: near ? .38 : .16,
            duration: const Duration(milliseconds: 360),
            child: Text(
              line.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                height: 1.18,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        children: [
          for (final token in line.tokens)
            _KaraokeToken(token: token, position: position),
        ],
      ),
    );
  }
}

class _KaraokeToken extends StatelessWidget {
  const _KaraokeToken({required this.token, required this.position});
  final _LyricToken token;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final elapsed = position - token.start;
    final span = token.end - token.start;
    final progress = span.inMilliseconds <= 0
        ? 1.0
        : (elapsed.inMilliseconds / span.inMilliseconds).clamp(0.0, 1.0);
    final future = progress <= 0;
    final current = progress > 0 && progress < 1;
    final blur = future ? 1.7 : (current ? (1 - progress) * 1.2 : 0.0);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      style: TextStyle(
        color: future
            ? Colors.white.withValues(alpha: .28)
            : Colors.white.withValues(alpha: .72 + progress * .28),
        fontSize: 31,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
        shadows: current
            ? const [Shadow(color: Color(0x99FFFFFF), blurRadius: 18)]
            : null,
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Text(token.text),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .2),
            border: const Border(top: BorderSide(color: Color(0x24FFFFFF))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: playback.previous,
                color: Colors.white,
                iconSize: 30,
                icon: const Icon(CupertinoIcons.backward_fill),
              ),
              const SizedBox(width: 18),
              AnimatedContainer(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    playback.playing ? 32 : 20,
                  ),
                ),
                child: IconButton(
                  onPressed: playback.toggle,
                  color: const Color(0xFF24151A),
                  iconSize: 30,
                  icon: Icon(
                    playback.playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              IconButton(
                onPressed: playback.next,
                color: Colors.white,
                iconSize: 30,
                icon: const Icon(CupertinoIcons.forward_fill),
              ),
            ],
          ),
        ),
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
    required this.tokens,
  });
  final String text;
  final Duration start;
  final Duration end;
  final List<_LyricToken> tokens;
}

class _LyricToken {
  const _LyricToken({
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
    final matches = _wordStamp.allMatches(value).toList();
    if (matches.isNotEmpty) {
      final tokens = <_LyricToken>[];
      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        final tokenStart = _time(match.group(1)!, match.group(2)!);
        final tokenEnd = i + 1 < matches.length
            ? _time(matches[i + 1].group(1)!, matches[i + 1].group(2)!)
            : end;
        final textEnd = i + 1 < matches.length
            ? matches[i + 1].start
            : value.length;
        final text = value.substring(match.end, textEnd);
        if (text.isNotEmpty) {
          tokens.add(_LyricToken(text: text, start: tokenStart, end: tokenEnd));
        }
      }
      return _LyricLine(
        text: tokens.map((e) => e.text).join(),
        start: start,
        end: end,
        tokens: tokens,
      );
    }

    final glyphs = value.runes.map(String.fromCharCode).toList();
    if (glyphs.isEmpty) {
      return _LyricLine(text: value, start: start, end: end, tokens: const []);
    }
    final span = end - start;
    final unit = span.inMilliseconds / glyphs.length;
    final tokens = List.generate(glyphs.length, (index) {
      return _LyricToken(
        text: glyphs[index],
        start: start + Duration(milliseconds: (unit * index).round()),
        end: start + Duration(milliseconds: (unit * (index + 1)).round()),
      );
    });
    return _LyricLine(text: value, start: start, end: end, tokens: tokens);
  }

  static Duration _time(String minutes, String seconds) => Duration(
    milliseconds:
        int.parse(minutes) * 60000 + (double.parse(seconds) * 1000).round(),
  );
}
