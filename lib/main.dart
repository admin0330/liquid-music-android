import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import 'github_update_service.dart';

const _ink = Color(0xFF1D1D1F);
const _mutedInk = Color(0xFF6E6E73);
const _musicRed = Color(0xFFFA2D48);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LiquidGlassDemoApp());
}

class LiquidGlassDemoApp extends StatelessWidget {
  const LiquidGlassDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Real Liquid Glass Demo',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(platformBrightness: Brightness.light),
        child: child!,
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _musicRed,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _ink,
          displayColor: _ink,
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: _musicRed,
          textTheme: CupertinoTextThemeData(primaryColor: _ink),
        ),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const DemoScreen(),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with SingleTickerProviderStateMixin {
  final _updates = GitHubUpdateService();
  late final AnimationController _motion;
  int _tab = 0;
  double _intensity = 0.88;
  bool _checking = false;
  String _version = '…';

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await _updates.currentVersion();
    if (mounted) setState(() => _version = version);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result = await _updates.check();
      if (!mounted) return;
      if (!result.hasUpdate) {
        _message('当前已是最新版本（$_version）');
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFFF5F5F7),
        showDragHandle: true,
        builder: (context) => _UpdateSheet(
          release: result.release!,
          currentVersion: result.currentVersion,
          onInstall: () => _install(result.release!),
        ),
      );
    } on UpdateException catch (error) {
      if (mounted) _message(error.message);
    } catch (error) {
      if (mounted) _message('检查更新失败：$error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _install(GitHubRelease release) async {
    Navigator.of(context).pop();
    try {
      final state = await _updates.downloadAndInstall(release.apkUrl);
      if (!mounted) return;
      if (state == InstallStartState.permissionRequired) {
        _message('请允许此应用安装未知应用，然后再次点击检查更新');
      } else {
        _message('正在后台下载；完成后会打开系统安装界面');
      }
    } catch (error) {
      if (mounted) _message('启动更新失败：$error');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedBackdrop(animation: _motion)),
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: _tab == 0
                  ? _home()
                  : _tab == 1
                  ? _settings()
                  : _about(),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: LiquidGlassBottomBar(
                currentIndex: _tab,
                onTap: (index) => setState(() => _tab = index),
                fallbackIntensity: _intensity,
                tint: _musicRed,
                items: const [
                  LiquidGlassBarItem(
                    icon: CupertinoIcons.music_note_2,
                    sfSymbol: 'music.note',
                    label: '现在听',
                  ),
                  LiquidGlassBarItem(
                    icon: CupertinoIcons.slider_horizontal_3,
                    sfSymbol: 'slider.horizontal.3',
                    label: '调节',
                  ),
                  LiquidGlassBarItem(
                    icon: CupertinoIcons.info_circle,
                    sfSymbol: 'info.circle',
                    label: '关于',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _page({required String title, required List<Widget> children}) {
    return ListView(
      key: ValueKey(title),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 132),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _home() {
    return _page(
      title: '音乐',
      children: [
        Text(
          'Liquid Glass · Android 实机效果',
          style: const TextStyle(color: _mutedInk),
        ),
        const SizedBox(height: 24),
        LiquidGlassContainer(
          shape: const LiquidGlassShape.roundedRectangle(30),
          fallbackIntensity: _intensity,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF375F), Color(0xFFBF5AF2)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(CupertinoIcons.waveform, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Midnight Flow',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Flutter Glass Sessions',
                          style: TextStyle(color: _mutedInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.62,
                  minHeight: 4,
                  backgroundColor: Color(0x18000000),
                  valueColor: AlwaysStoppedAnimation(_musicRed),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(CupertinoIcons.backward_fill),
                  Icon(CupertinoIcons.pause_fill, size: 34),
                  Icon(CupertinoIcons.forward_fill),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _metric(
                CupertinoIcons.layers_alt,
                '容器',
                '圆角玻璃',
                const Color(0xFF32ADE6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _metric(CupertinoIcons.bolt_fill, '交互', '可点击', _musicRed),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LiquidGlassContainer(
          shape: const LiquidGlassShape.capsule(),
          height: 62,
          fallbackIntensity: _intensity,
          onTap: _checkForUpdates,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (_checking)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(CupertinoIcons.arrow_down_circle),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '检查 GitHub 更新',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('v$_version', style: const TextStyle(color: _mutedInk)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String title, String subtitle, Color tint) {
    return LiquidGlassContainer(
      height: 130,
      shape: const LiquidGlassShape.roundedRectangle(26),
      tint: tint == _musicRed
          ? const Color(0xFFFFF0F2)
          : const Color(0xFFEDF7FC),
      fallbackIntensity: _intensity,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: _mutedInk)),
        ],
      ),
    );
  }

  Widget _settings() {
    return _page(
      title: '调节效果',
      children: [
        const Text(
          'Android 使用 Flutter 绘制的毛玻璃。拖动滑块观察透明度、模糊和高光变化。',
          style: TextStyle(color: _mutedInk, height: 1.47),
        ),
        const SizedBox(height: 26),
        LiquidGlassContainer(
          shape: const LiquidGlassShape.roundedRectangle(28),
          fallbackIntensity: _intensity,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '降级效果强度',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('${(_intensity * 100).round()}%'),
                ],
              ),
              Slider(
                value: _intensity,
                onChanged: (value) => setState(() => _intensity = value),
              ),
              const Divider(color: Color(0x14000000)),
              const SizedBox(height: 8),
              const Text(
                '提示：Android 上没有 Apple 原生折射和液滴融合，当前页面测试的是该包提供的跨平台 fallback。',
                style: TextStyle(color: _mutedInk, height: 1.47),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _about() {
    return _page(
      title: '关于',
      children: [
        const SizedBox(height: 16),
        LiquidGlassContainer(
          shape: const LiquidGlassShape.roundedRectangle(28),
          fallbackIntensity: _intensity,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Real Liquid Glass Android Demo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text('应用版本：$_version'),
              const Text('更新源：GitHub Releases（自动升级已验证）'),
              const Text('应用 ID：io.github.admin0330.real_liquid_glass_demo'),
              const SizedBox(height: 16),
              const Text(
                '这是测试应用，不采集账号或设备信息。检查更新时只访问 GitHub 公共 API。',
                style: TextStyle(color: _mutedInk, height: 1.47),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackdrop extends AnimatedWidget {
  const _AnimatedBackdrop({required Animation<double> animation})
    : super(listenable: animation);

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = animation.value;
    return CustomPaint(
      painter: _BackdropPainter(t),
      child: const SizedBox.expand(),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F7), Color(0xFFFAFAFC)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    void orb(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.48), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
      );
    }

    orb(
      Offset(size.width * (0.72 + 0.08 * math.sin(t * math.pi)), 90),
      210,
      const Color(0xFFFFAFC1),
    );
    orb(
      Offset(size.width * (0.18 + 0.06 * t), size.height * 0.56),
      190,
      const Color(0xFFFFD1C7),
    );
    orb(
      Offset(size.width * 0.84, size.height * (0.7 + 0.05 * t)),
      160,
      const Color(0xFFC5E8F5),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => oldDelegate.t != t;
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.release,
    required this.currentVersion,
    required this.onInstall,
  });

  final GitHubRelease release;
  final String currentVersion;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '发现新版本',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('v$currentVersion  →  v${release.version}'),
            if (release.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Text(
                    release.notes,
                    style: const TextStyle(color: _mutedInk, height: 1.47),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(CupertinoIcons.arrow_down_circle_fill),
                label: const Text('下载并安装'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
