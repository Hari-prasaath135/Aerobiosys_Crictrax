// lib/src/Pages/Teams/player_stats_page.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:TURF_TOWN_/src/utils/name_formatter.dart';
import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/models/player_stats_model.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/player_stats_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────────────────

class PlayerStatsPage extends StatefulWidget {
  final TeamMember player;
  const PlayerStatsPage({super.key, required this.player});

  @override
  State<PlayerStatsPage> createState() => _PlayerStatsPageState();
}

class _PlayerStatsPageState extends State<PlayerStatsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _floodlightController;
  late final AnimationController _silhouetteController;
  late final AnimationController _nameAnimController;
  late final AnimationController _pulseController;

  late final Animation<double> _floodlightAnim;
  late final Animation<double> _silhouetteFade;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _pulseAnim;

  PlayerStats? _stats;
  bool _isLoading = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _currentTab = _tabController.index);
      }
    });

    _floodlightController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _floodlightAnim =
        CurvedAnimation(parent: _floodlightController, curve: Curves.easeOut);

    _silhouetteController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _silhouetteFade =
        CurvedAnimation(parent: _silhouetteController, curve: Curves.easeIn);

    _nameAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _nameOpacity =
        CurvedAnimation(parent: _nameAnimController, curve: Curves.easeIn);
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _nameAnimController, curve: Curves.easeOut));

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _floodlightController.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _silhouetteController.forward().then((_) {
            if (mounted) _nameAnimController.forward();
          });
        }
      });
    });

    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _floodlightController.dispose();
    _silhouetteController.dispose();
    _nameAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await PlayerStatsService.instance
          .fetchStatsForPlayer(widget.player.playerId);
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _stats = const PlayerStats(); _isLoading = false; });
    }
  }

  String get _silhouettePath {
    switch (_currentTab) {
      case 1: return 'assets/images/bowler_silhoutte.png';
      case 2: return 'assets/images/wicketkeeper_silhoutte.png';
      default: return 'assets/images/player_silhouette.png';
    }
  }

  // ── FIXED: restored correct page build method ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF080D2E), Color(0xFF000000)],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildHeroSection(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00C4FF)),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _BattingTab(stats: _stats!),
                          _BowlingTab(stats: _stats!),
                          _FieldingTab(stats: _stats!),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'Player Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floodlightAnim,
              builder: (_, __) => CustomPaint(
                painter: _DualFloodlightPainter(progress: _floodlightAnim.value),
              ),
            ),
          ),
          Positioned(
            bottom: 58,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 140,
                height: 195,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(70),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C4FF)
                          .withOpacity(0.18 * _pulseAnim.value),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 52,
            child: FadeTransition(
              opacity: _silhouetteFade,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          const Color(0xFF00C4FF)
                              .withOpacity(0.55 * _pulseAnim.value),
                          BlendMode.srcATop,
                        ),
                        child: ImageFiltered(
                          imageFilter: _blurFilter(8),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _silhouetteImage(
                              height: 215,
                              path: _silhouettePath,
                              key: ValueKey('glow_blue_$_currentTab'),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            const Color(0xFFFFE566)
                                .withOpacity(0.40 * _pulseAnim.value),
                            BlendMode.srcATop,
                          ),
                          child: ImageFiltered(
                            imageFilter: _blurFilter(10),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _silhouetteImage(
                                height: 215,
                                path: _silhouettePath,
                                key: ValueKey('glow_gold_$_currentTab'),
                              ),
                            ),
                          ),
                        ),
                      ),
                      child!,
                    ],
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _silhouetteImage(
                    height: 215,
                    path: _silhouettePath,
                    key: ValueKey('sharp_$_currentTab'),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 170,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C4FF)
                          .withOpacity(0.50 * _pulseAnim.value),
                      blurRadius: 24,
                      spreadRadius: 8,
                    ),
                  ],
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: FadeTransition(
              opacity: _nameOpacity,
              child: SlideTransition(
                position: _nameSlide,
                child: Column(
                  children: [
                    Text(
                     formatPlayerName(widget.player.playerName).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5.0,
                        shadows: [
                          Shadow(color: Color(0xFF00C4FF), blurRadius: 16),
                          Shadow(color: Color(0xFF00C4FF), blurRadius: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All-Time Career Stats',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _silhouetteImage({required double height, String? path, Key? key}) {
    return ColorFiltered(
      key: key,
      colorFilter: const ColorFilter.matrix(<double>[
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image.asset(
        path ?? 'assets/images/player_silhouette.png',
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  ImageFilter _blurFilter(double sigma) =>
      ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00C4FF).withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF00C4FF).withOpacity(0.5), width: 1),
        ),
        labelColor: const Color(0xFF00C4FF),
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '🏏  Batting'),
          Tab(text: '🎯  Bowling'),
          Tab(text: '🧤  Fielding'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Floodlight Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DualFloodlightPainter extends CustomPainter {
  final double progress;
  const _DualFloodlightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final tx = size.width / 2;
    final ty = size.height - 52 - 107;

    _drawBeam(canvas,
        origin: Offset(size.width * 0.05, 0),
        target: Offset(tx, ty),
        color: const Color(0xFF00C4FF),
        spreadHalf: 0.18,
        opacity: 0.70);

    _drawBeam(canvas,
        origin: Offset(size.width * 0.95, 0),
        target: Offset(tx, ty),
        color: const Color(0xFFFFE566),
        spreadHalf: 0.16,
        opacity: 0.58);
  }

  void _drawBeam(Canvas canvas,
      {required Offset origin,
      required Offset target,
      required Color color,
      required double spreadHalf,
      required double opacity}) {
    final dx = target - origin;
    final angle = math.atan2(dx.dy, dx.dx);
    final length = dx.distance * 1.25;

    Offset pt(double a) => Offset(
          origin.dx + length * math.cos(a),
          origin.dy + length * math.sin(a),
        );

    final outerPath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(pt(angle - spreadHalf).dx, pt(angle - spreadHalf).dy)
      ..lineTo(pt(angle + spreadHalf).dx, pt(angle + spreadHalf).dy)
      ..close();

    canvas.drawPath(
        outerPath,
        Paint()
          ..shader = LinearGradient(colors: [
            color.withOpacity(opacity * progress),
            color.withOpacity(0.0),
          ]).createShader(Rect.fromPoints(origin, target))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
          ..style = PaintingStyle.fill);

    final inner = spreadHalf * 0.30;
    final innerPath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(pt(angle - inner).dx, pt(angle - inner).dy)
      ..lineTo(pt(angle + inner).dx, pt(angle + inner).dy)
      ..close();

    canvas.drawPath(
        innerPath,
        Paint()
          ..shader = LinearGradient(colors: [
            color.withOpacity((opacity * 0.95) * progress),
            color.withOpacity(0.05 * progress),
          ]).createShader(Rect.fromPoints(origin, target))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DualFloodlightPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Batting Tab
// ─────────────────────────────────────────────────────────────────────────────

class _BattingTab extends StatelessWidget {
  final PlayerStats stats;
  const _BattingTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final boundaryRuns = stats.totalFours * 4 + stats.totalSixes * 6;
    final nonBoundaryRuns = (stats.totalRuns - boundaryRuns).clamp(0, 999999);

    final items = <Widget>[
      _AnimatedStatCard(
        index: 0,
        child: Row(children: [
          _HeroStat(
              label: 'Total Runs',
              value: '${stats.totalRuns}',
              icon: Icons.sports_cricket,
              color: const Color(0xFF00C4FF)),
          const SizedBox(width: 12),
          _HeroStat(
              label: 'Innings',
              value: '${stats.totalInnings}',
              icon: Icons.format_list_numbered,
              color: const Color(0xFF7C4DFF)),
        ]),
      ),
      _AnimatedStatCard(
        index: 1,
        child: Row(children: [
          _HeroStat(
              label: '100s',
              value: '${stats.hundreds}',
              icon: Icons.emoji_events,
              color: const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          _HeroStat(
              label: '50s',
              value: '${stats.fifties}',
              icon: Icons.star_half,
              color: const Color(0xFFFFA000)),
        ]),
      ),

      // ── FIXED: _BattingRadarChart directly, SizedBox width constraint added inside the widget ──
      _AnimatedStatCard(
        index: 2,
        child: _ChartCard(
          title: 'Batting Profile',
          child: _BattingRadarChart(stats: stats),
        ),
      ),

      _AnimatedStatCard(
        index: 3,
        child: _ChartCard(
          title: 'Runs Source Breakdown',
          child: _RunsBreakdownChart(
            fours: stats.totalFours * 4,
            sixes: stats.totalSixes * 6,
            other: nonBoundaryRuns,
          ),
        ),
      ),
      _AnimatedStatCard(
        index: 4,
        child: _ChartCard(
          title: 'Key Metrics',
          child: Row(children: [
            Expanded(
              child: _RingGauge(
                label: 'Batting Avg',
                value: stats.battingAverage,
                max: 100,
                color: const Color(0xFF00C4FF),
                unit: '',
              ),
            ),
            Container(width: 1, height: 100, color: Colors.white.withOpacity(0.08)),
            Expanded(
              child: _RingGauge(
                label: 'Strike Rate',
                value: stats.strikeRate,
                max: 200,
                color: const Color(0xFF7C4DFF),
                unit: '',
              ),
            ),
            Container(width: 1, height: 100, color: Colors.white.withOpacity(0.08)),
            Expanded(
              child: _RingGauge(
                label: 'Not Outs',
                value: stats.notOuts.toDouble(),
                max: (stats.totalInnings.clamp(1, 999)).toDouble(),
                color: const Color(0xFF00E676),
                unit: '',
                displayValue: '${stats.notOuts}',
              ),
            ),
          ]),
        ),
      ),
      _AnimatedStatCard(
        index: 5,
        child: _StatSection(
          title: 'Shot Breakdown',
          children: [
            _StatRow(
                label: 'Balls Faced',
                value: '${stats.totalBallsFaced}',
                subtitle: 'Total deliveries received'),
            _StatRow(
                label: 'Fours',
                value: '${stats.totalFours}',
                subtitle: 'Boundary hits'),
            _StatRow(
                label: 'Sixes',
                value: '${stats.totalSixes}',
                subtitle: 'Over the fence'),
            _StatRow(
              label: 'Boundary %',
              value: stats.totalRuns == 0
                  ? '0.0%'
                  : '${((boundaryRuns / stats.totalRuns.clamp(1, 999999)) * 100).toStringAsFixed(1)}%',
              subtitle: 'Runs from boundaries',
            ),
          ],
        ),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => items[i],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bowling Tab
// ─────────────────────────────────────────────────────────────────────────────

class _BowlingTab extends StatelessWidget {
  final PlayerStats stats;
  const _BowlingTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final overs = stats.totalBallsBowled ~/ 6;
    final rem = stats.totalBallsBowled % 6;
    final oversStr = '$overs.$rem';

    final items = <Widget>[
      _AnimatedStatCard(
        index: 0,
        child: Row(children: [
          _HeroStat(
              label: 'Wickets',
              value: '${stats.totalWickets}',
              icon: Icons.sports_cricket,
              color: const Color(0xFF00E676)),
          const SizedBox(width: 12),
          _HeroStat(
              label: 'Overs Bowled',
              value: oversStr,
              icon: Icons.rotate_right,
              color: const Color(0xFF00C4FF)),
        ]),
      ),
      _AnimatedStatCard(
        index: 1,
        child: Row(children: [
          _HeroStat(
              label: 'Runs Given',
              value: '${stats.totalRunsConceded}',
              icon: Icons.trending_up,
              color: const Color(0xFFFF5252)),
          const SizedBox(width: 12),
          _HeroStat(
              label: 'Maidens',
              value: '${stats.totalMaidens}',
              icon: Icons.lock_outline,
              color: const Color(0xFF7C4DFF)),
        ]),
      ),
      _AnimatedStatCard(
        index: 2,
        child: _ChartCard(
          title: 'Bowling Efficiency',
          child: Row(children: [
            Expanded(
              child: _RingGauge(
                label: 'Economy',
                value: stats.economyRate,
                max: 12,
                color: const Color(0xFF00E676),
                unit: '',
                invertFill: true,
              ),
            ),
            Container(width: 1, height: 100, color: Colors.white.withOpacity(0.08)),
            Expanded(
              child: _RingGauge(
                label: 'Bowling Avg',
                value: stats.totalWickets == 0 ? 0 : stats.bowlingAverage,
                max: 60,
                color: const Color(0xFF00C4FF),
                unit: '',
                displayValue: stats.totalWickets == 0
                    ? '—'
                    : stats.bowlingAverage.toStringAsFixed(1),
                invertFill: true,
              ),
            ),
            Container(width: 1, height: 100, color: Colors.white.withOpacity(0.08)),
            Expanded(
              child: _RingGauge(
                label: 'Strike Rate',
                value: stats.totalWickets == 0 ? 0 : stats.bowlingStrikeRate,
                max: 60,
                color: const Color(0xFF7C4DFF),
                unit: '',
                displayValue: stats.totalWickets == 0
                    ? '—'
                    : stats.bowlingStrikeRate.toStringAsFixed(1),
                invertFill: true,
              ),
            ),
          ]),
        ),
      ),
      _AnimatedStatCard(
        index: 3,
        child: _ChartCard(
          title: 'Wickets vs Runs Conceded',
          child: SizedBox(
            height: 140,
            child: _BowlingCompareChart(
              wickets: stats.totalWickets,
              runsConceded: stats.totalRunsConceded,
              maidens: stats.totalMaidens,
            ),
          ),
        ),
      ),
      _AnimatedStatCard(
        index: 4,
        child: _StatSection(
          title: 'Efficiency Metrics',
          children: [
            _StatRow(
                label: 'Economy Rate',
                value: stats.economyRate.toStringAsFixed(2),
                subtitle: 'Runs conceded per over'),
            _StatRow(
                label: 'Bowling Average',
                value: stats.totalWickets == 0
                    ? '—'
                    : stats.bowlingAverage.toStringAsFixed(2),
                subtitle: 'Runs per wicket'),
            _StatRow(
                label: 'Bowling Strike Rate',
                value: stats.totalWickets == 0
                    ? '—'
                    : stats.bowlingStrikeRate.toStringAsFixed(1),
                subtitle: 'Balls per wicket'),
            _StatRow(
                label: 'Maiden Rate',
                value: overs == 0
                    ? '0.0%'
                    : '${((stats.totalMaidens / overs) * 100).toStringAsFixed(1)}%',
                subtitle: 'Maidens as % of overs'),
          ],
        ),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => items[i],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Fielding Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FieldingTab extends StatelessWidget {
  final PlayerStats stats;
  const _FieldingTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.catches + stats.stumpings + stats.runOuts;

    final items = <Widget>[
      _AnimatedStatCard(
        index: 0,
        child: Row(children: [
          _HeroStat(
              label: 'Total Dismissals',
              value: '$total',
              icon: Icons.sports_handball,
              color: const Color(0xFF00C4FF)),
          const SizedBox(width: 12),
          _HeroStat(
              label: 'Catches',
              value: '${stats.catches}',
              icon: Icons.back_hand,
              color: const Color(0xFF00E676)),
        ]),
      ),
      _AnimatedStatCard(
        index: 1,
        child: Row(children: [
          _HeroStat(
              label: 'Stumpings',
              value: '${stats.stumpings}',
              icon: Icons.sports_cricket,
              color: const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          _HeroStat(
              label: 'Run Outs',
              value: '${stats.runOuts}',
              icon: Icons.directions_run,
              color: const Color(0xFFFF5252)),
        ]),
      ),

      // ── FIXED: explicit SizedBox height added for donut chart ──
      _AnimatedStatCard(
        index: 2,
        child: _ChartCard(
          title: 'Dismissal Distribution',
          child: SizedBox(
            height: 220,
            child: _DismissalDonutChart(
              catches: stats.catches,
              stumpings: stats.stumpings,
              runOuts: stats.runOuts,
            ),
          ),
        ),
      ),

      _AnimatedStatCard(
        index: 3,
        child: _ChartCard(
          title: 'Contribution Per Type',
          child: SizedBox(
            height: 130,
            child: _FieldingBarsChart(
              catches: stats.catches,
              stumpings: stats.stumpings,
              runOuts: stats.runOuts,
            ),
          ),
        ),
      ),
      _AnimatedStatCard(
        index: 4,
        child: _StatSection(
          title: 'Breakdown',
          children: [
            _StatRow(
                label: 'Catches',
                value: '${stats.catches}',
                subtitle: 'Direct catches taken'),
            _StatRow(
                label: 'Stumpings',
                value: '${stats.stumpings}',
                subtitle: 'Wicketkeeper dismissals'),
            _StatRow(
                label: 'Run Outs',
                value: '${stats.runOuts}',
                subtitle: 'Direct throw dismissals'),
            _StatRow(
                label: 'Total Contributions',
                value: '$total',
                subtitle: 'All fielding dismissals'),
          ],
        ),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => items[i],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart: Batting Radar
// ─────────────────────────────────────────────────────────────────────────────

class _BattingRadarChart extends StatefulWidget {
  final PlayerStats stats;
  const _BattingRadarChart({required this.stats});

  @override
  State<_BattingRadarChart> createState() => _BattingRadarChartState();
}

class _BattingRadarChartState extends State<_BattingRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── FIXED: SizedBox with width: double.infinity wraps CustomPaint ──
  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final values = [
      (s.battingAverage / 80).clamp(0.0, 1.0),
      (s.strikeRate / 180).clamp(0.0, 1.0),
      ((s.hundreds * 10 + s.fifties * 2) / 60).clamp(0.0, 1.0),
      ((s.totalFours + s.totalSixes * 2) / 200).clamp(0.0, 1.0),
      (s.totalInnings / 80).clamp(0.0, 1.0),
      (1 - (s.totalWickets / (s.totalInnings.clamp(1, 99999)))).clamp(0.0, 1.0),
    ];
    final labels = ['Average', 'Strike\nRate', 'Milestones', 'Boundaries', 'Experience', 'Consistency'];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: double.infinity,
        height: 220,
        child: CustomPaint(
          painter: _RadarPainter(
            values: values,
            labels: labels,
            progress: _anim.value,
            fillColor: const Color(0xFF00C4FF),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double progress;
  final Color fillColor;

  const _RadarPainter({
    required this.values,
    required this.labels,
    required this.progress,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final count = values.length;
    const gridLevels = 4;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var level = 1; level <= gridLevels; level++) {
      final r = radius * level / gridLevels;
      final path = Path();
      for (var i = 0; i < count; i++) {
        final angle = (2 * math.pi * i / count) - math.pi / 2;
        final pt = Offset(center.dx + r * math.cos(angle),
            center.dy + r * math.sin(angle));
        if (i == 0) path.moveTo(pt.dx, pt.dy);
        else path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final spokePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.8;
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) - math.pi / 2;
      canvas.drawLine(
          center,
          Offset(center.dx + radius * math.cos(angle),
              center.dy + radius * math.sin(angle)),
          spokePaint);
    }

    final animatedValues = values.map((v) => v * progress).toList();
    final dataPath = Path();
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) - math.pi / 2;
      final r = radius * animatedValues[i];
      final pt = Offset(center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle));
      if (i == 0) dataPath.moveTo(pt.dx, pt.dy);
      else dataPath.lineTo(pt.dx, pt.dy);
    }
    dataPath.close();

    canvas.drawPath(dataPath,
        Paint()
          ..color = fillColor.withOpacity(0.18)
          ..style = PaintingStyle.fill);
    canvas.drawPath(dataPath,
        Paint()
          ..color = fillColor.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) - math.pi / 2;
      final r = radius * animatedValues[i];
      final pt = Offset(center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle));
      canvas.drawCircle(pt, 3.5, Paint()..color = fillColor);
      canvas.drawCircle(pt, 3.5,
          Paint()
            ..color = Colors.white.withOpacity(0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.70),
      fontSize: 10,
      fontFamily: 'Poppins',
    );
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) - math.pi / 2;
      final labelR = radius + 20;
      final pos = Offset(center.dx + labelR * math.cos(angle),
          center.dy + labelR * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress || old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart: Runs Breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _RunsBreakdownChart extends StatefulWidget {
  final int fours;
  final int sixes;
  final int other;
  const _RunsBreakdownChart(
      {required this.fours, required this.sixes, required this.other});

  @override
  State<_RunsBreakdownChart> createState() => _RunsBreakdownChartState();
}

class _RunsBreakdownChartState extends State<_RunsBreakdownChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.fours + widget.sixes + widget.other).clamp(1, 999999);
    final segments = [
      _BarSegment(label: '4s', value: widget.fours, color: const Color(0xFF00C4FF)),
      _BarSegment(label: '6s', value: widget.sixes, color: const Color(0xFFFFD700)),
      _BarSegment(label: 'Running', value: widget.other, color: const Color(0xFF7C4DFF)),
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    children: segments.map((seg) {
                      final rawFrac = seg.value / total;
                      final flexVal = (rawFrac * 1000).round();
                      if (flexVal <= 0) return const SizedBox.shrink();
                      return Expanded(
                        flex: flexVal,
                        child: Opacity(
                          opacity: _anim.value,
                          child: Container(
                            color: seg.color,
                            alignment: Alignment.center,
                            child: rawFrac > 0.10
                                ? Text(
                                    '${seg.value}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: segments.map((seg) {
                  final pct = (seg.value / total * 100).toStringAsFixed(1);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: seg.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${seg.label} · $pct%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontFamily: 'Poppins',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              if (widget.fours == 0 && widget.sixes == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Center(
                    child: Text(
                      'No boundary data recorded yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.30),
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BarSegment {
  final String label;
  final int value;
  final Color color;
  const _BarSegment(
      {required this.label, required this.value, required this.color});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart: Ring Gauge
// ─────────────────────────────────────────────────────────────────────────────

class _RingGauge extends StatefulWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String unit;
  final String? displayValue;
  final bool invertFill;

  const _RingGauge({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.unit,
    this.displayValue,
    this.invertFill = false,
  });

  @override
  State<_RingGauge> createState() => _RingGaugeState();
}

class _RingGaugeState extends State<_RingGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (widget.value / widget.max).clamp(0.0, 1.0);
    final effectiveFraction = widget.invertFill ? (1 - fraction) : fraction;

    final display = widget.displayValue ??
        (widget.value % 1 == 0
            ? '${widget.value.toInt()}'
            : widget.value.toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: _RingPainter(
                  fraction: effectiveFraction * _anim.value,
                  color: widget.color,
                ),
                child: Center(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    const strokeWidth = 7.0;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart: Bowling Compare bars
// ─────────────────────────────────────────────────────────────────────────────

class _BowlingCompareChart extends StatefulWidget {
  final int wickets;
  final int runsConceded;
  final int maidens;
  const _BowlingCompareChart(
      {required this.wickets,
      required this.runsConceded,
      required this.maidens});

  @override
  State<_BowlingCompareChart> createState() => _BowlingCompareChartState();
}

class _BowlingCompareChartState extends State<_BowlingCompareChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      _HBarRow(
          label: 'Wickets',
          value: widget.wickets,
          max: (widget.wickets + 1).clamp(5, 99999),
          color: const Color(0xFF00E676)),
      _HBarRow(
          label: 'Runs Given',
          value: widget.runsConceded,
          max: (widget.runsConceded + 1).clamp(100, 99999),
          color: const Color(0xFFFF5252)),
      _HBarRow(
          label: 'Maidens',
          value: widget.maidens,
          max: (widget.maidens + 1).clamp(5, 99999),
          color: const Color(0xFF7C4DFF)),
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rows.map((row) => _buildHBar(row)).toList(),
        ),
      ),
    );
  }

  Widget _buildHBar(_HBarRow row) {
    final frac = (row.value / row.max * _anim.value).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(row.label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontFamily: 'Poppins',
                  fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 18, color: Colors.white.withOpacity(0.07)),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: row.color.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('${row.value}',
              style: TextStyle(
                  color: row.color,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _HBarRow {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _HBarRow(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart: Dismissal Donut
// ─────────────────────────────────────────────────────────────────────────────

class _DismissalDonutChart extends StatefulWidget {
  final int catches;
  final int stumpings;
  final int runOuts;
  const _DismissalDonutChart(
      {required this.catches, required this.stumpings, required this.runOuts});

  @override
  State<_DismissalDonutChart> createState() => _DismissalDonutChartState();
}

class _DismissalDonutChartState extends State<_DismissalDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (widget.catches + widget.stumpings + widget.runOuts).clamp(1, 999999);
    final segments = [
      _DonutSegment(label: 'Catches', value: widget.catches, color: const Color(0xFF00E676)),
      _DonutSegment(label: 'Stumpings', value: widget.stumpings, color: const Color(0xFFFFD700)),
      _DonutSegment(label: 'Run Outs', value: widget.runOuts, color: const Color(0xFFFF5252)),
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        children: [
          // ── FIXED: explicit SizedBox so CustomPaint has bounded width & height ──
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: segments,
                total: total,
                progress: _anim.value,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                  ),
                ),
                Text(
                  'Total dismissals',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.40),
                    fontFamily: 'Poppins',
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                ...segments.map((seg) {
                  final pct = (seg.value / total * 100).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: seg.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(seg.label,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontFamily: 'Poppins',
                                  fontSize: 11)),
                        ),
                        Text('$pct%',
                            style: TextStyle(
                                color: seg.color,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 11)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  final String label;
  final int value;
  final Color color;
  const _DonutSegment(
      {required this.label, required this.value, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final int total;
  final double progress;
  const _DonutPainter(
      {required this.segments, required this.total, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 22.0;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * progress - gap;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += (seg.value / total) * 2 * math.pi * progress;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chart: Fielding horizontal bars
// ─────────────────────────────────────────────────────────────────────────────

class _FieldingBarsChart extends StatefulWidget {
  final int catches;
  final int stumpings;
  final int runOuts;
  const _FieldingBarsChart(
      {required this.catches, required this.stumpings, required this.runOuts});

  @override
  State<_FieldingBarsChart> createState() => _FieldingBarsChartState();
}

class _FieldingBarsChartState extends State<_FieldingBarsChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal =
        math.max(math.max(widget.catches, widget.stumpings), widget.runOuts)
            .clamp(1, 99999);
    final rows = [
      _HBarRow(label: 'Catches', value: widget.catches, max: maxVal, color: const Color(0xFF00E676)),
      _HBarRow(label: 'Stumpings', value: widget.stumpings, max: maxVal, color: const Color(0xFFFFD700)),
      _HBarRow(label: 'Run Outs', value: widget.runOuts, max: maxVal, color: const Color(0xFFFF5252)),
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rows.map((row) {
            final frac = (row.value / row.max * _anim.value).clamp(0.0, 1.0);
            return Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(row.label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.60),
                          fontFamily: 'Poppins',
                          fontSize: 11)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 22, color: Colors.white.withOpacity(0.07)),
                        FractionallySizedBox(
                          widthFactor: frac,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: row.color.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text('${row.value}',
                      style: TextStyle(
                          color: row.color,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                      textAlign: TextAlign.right),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bubble scroll animation wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedStatCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedStatCard({required this.index, required this.child});

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable UI widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title,
                style: const TextStyle(
                  color: Color(0xFF00C4FF),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                )),
          ),
          const Divider(color: Color(0xFF2A2D35), height: 1),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2026),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontFamily: 'Poppins')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _StatSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Text(title,
                style: const TextStyle(
                    color: Color(0xFF00C4FF),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ),
          const Divider(color: Color(0xFF2A2D35), height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  const _StatRow(
      {required this.label, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontFamily: 'Poppins')),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF00C4FF),
                  fontSize: 18,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}