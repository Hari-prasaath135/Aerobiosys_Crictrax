// lib/src/Pages/Teams/player_stats_page.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/models/player_stats_model.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/player_stats_service.dart';
import 'dart:ui' as ui show ImageFilter;
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 1) Floodlight sweeps in: 1200ms
    _floodlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _floodlightAnim = CurvedAnimation(
      parent: _floodlightController,
      curve: Curves.easeOut,
    );

    // 2) Silhouette fades in: 900ms, starts 400ms after floodlight
    _silhouetteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _silhouetteFade = CurvedAnimation(
      parent: _silhouetteController,
      curve: Curves.easeIn,
    );

    // 3) Name slides up + fades: 600ms, after silhouette
    _nameAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _nameOpacity = CurvedAnimation(
      parent: _nameAnimController,
      curve: Curves.easeIn,
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _nameAnimController,
      curve: Curves.easeOut,
    ));

    // 4) Continuous rim-glow pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation sequence
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
                        child: CircularProgressIndicator(color: Color(0xFF00C4FF)),
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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

          // ── Layer 1: Floodlight beams (behind everything) ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floodlightAnim,
              builder: (_, __) => CustomPaint(
                painter: _DualFloodlightPainter(progress: _floodlightAnim.value),
              ),
            ),
          ),

          // ── Layer 2: Silhouette body ambient glow (behind image) ──
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

          // ── Layer 3: Silhouette image with fade-in ──
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
                      // Rim-light outline glow — painted as a blurred copy behind
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          const Color(0xFF00C4FF).withOpacity(0.55 * _pulseAnim.value),
                          BlendMode.srcATop,
                        ),
                        child: ImageFiltered(
                          imageFilter: _blurFilter(8),
                          child: _silhouetteImage(height: 215),
                        ),
                      ),
                      // Gold right-side rim glow
                      Positioned(
                        right: 0,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            const Color(0xFFFFE566).withOpacity(0.40 * _pulseAnim.value),
                            BlendMode.srcATop,
                          ),
                          child: ImageFiltered(
                            imageFilter: _blurFilter(10),
                            child: _silhouetteImage(height: 215),
                          ),
                        ),
                      ),
                      // Actual sharp black silhouette on top
                      child!,
                    ],
                  );
                },
                child: _silhouetteImage(height: 215),
              ),
            ),
          ),

          // ── Layer 4: Ground glow ──
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

          // ── Layer 5: Player name + subtitle ──
          Positioned(
            bottom: 0,
            child: FadeTransition(
              opacity: _nameOpacity,
              child: SlideTransition(
                position: _nameSlide,
                child: Column(
                  children: [
                    Text(
                      widget.player.playerName.toUpperCase(),
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

  // Pure black silhouette — inverts white→black, makes white bg transparent
Widget _silhouetteImage({required double height}) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      // Zero out R, G, B channels entirely → pure black pixels
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      0, 0, 0, 0, 0,
      // Keep original alpha channel intact
      0, 0, 0, 1, 0,
    ]),
    child: Image.asset(
      'assets/images/player_silhouette.png',
      height: height,
      fit: BoxFit.contain,
    ),
  );
}
  // Helper: ImageFilter blur
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
          border: Border.all(color: const Color(0xFF00C4FF).withOpacity(0.5), width: 1),
        ),
        labelColor: const Color(0xFF00C4FF),
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 13),
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
//  Dual Floodlight Painter — beams aimed precisely at silhouette centre
// ─────────────────────────────────────────────────────────────────────────────

class _DualFloodlightPainter extends CustomPainter {
  final double progress;
  const _DualFloodlightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    // Silhouette mid-body: bottom=52, height=215 → centre at height - 52 - 107
    final tx = size.width / 2;
    final ty = size.height - 52 - 107;

    _drawBeam(canvas, origin: Offset(size.width * 0.05, 0),
        target: Offset(tx, ty), color: const Color(0xFF00C4FF),
        spreadHalf: 0.18, opacity: 0.70);

    _drawBeam(canvas, origin: Offset(size.width * 0.95, 0),
        target: Offset(tx, ty), color: const Color(0xFFFFE566),
        spreadHalf: 0.16, opacity: 0.58);
  }

  void _drawBeam(Canvas canvas, {
    required Offset origin, required Offset target,
    required Color color, required double spreadHalf, required double opacity,
  }) {
    final dx = target - origin;
    final angle = math.atan2(dx.dy, dx.dx);
    final length = dx.distance * 1.25;

    Offset pt(double a) => Offset(
      origin.dx + length * math.cos(a),
      origin.dy + length * math.sin(a),
    );

    // Outer soft beam
    final outerPath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(pt(angle - spreadHalf).dx, pt(angle - spreadHalf).dy)
      ..lineTo(pt(angle + spreadHalf).dx, pt(angle + spreadHalf).dy)
      ..close();

    canvas.drawPath(outerPath, Paint()
      ..shader = LinearGradient(colors: [
        color.withOpacity(opacity * progress),
        color.withOpacity(0.0),
      ]).createShader(Rect.fromPoints(origin, target))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill);

    // Inner bright core
    final inner = spreadHalf * 0.30;
    final innerPath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(pt(angle - inner).dx, pt(angle - inner).dy)
      ..lineTo(pt(angle + inner).dx, pt(angle + inner).dy)
      ..close();

    canvas.drawPath(innerPath, Paint()
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
//  Batting Tab  — bubble scroll animation
// ─────────────────────────────────────────────────────────────────────────────

class _BattingTab extends StatelessWidget {
  final PlayerStats stats;
  const _BattingTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _AnimatedStatCard(index: 0, child: Row(children: [
        _HeroStat(label: 'Total Runs', value: '${stats.totalRuns}',
            icon: Icons.sports_cricket, color: const Color(0xFF00C4FF)),
        const SizedBox(width: 12),
        _HeroStat(label: 'Innings', value: '${stats.totalInnings}',
            icon: Icons.format_list_numbered, color: const Color(0xFF7C4DFF)),
      ])),
      _AnimatedStatCard(index: 1, child: Row(children: [
        _HeroStat(label: '100s', value: '${stats.hundreds}',
            icon: Icons.emoji_events, color: const Color(0xFFFFD700)),
        const SizedBox(width: 12),
        _HeroStat(label: '50s', value: '${stats.fifties}',
            icon: Icons.star_half, color: const Color(0xFFFFA000)),
      ])),
      _AnimatedStatCard(index: 2, child: _StatSection(
        title: 'Performance Metrics',
        children: [
          _StatRow(label: 'Batting Average',
              value: stats.battingAverage.toStringAsFixed(2),
              subtitle: 'Runs per dismissal'),
          _StatRow(label: 'Strike Rate',
              value: stats.strikeRate.toStringAsFixed(1),
              subtitle: 'Runs per 100 balls'),
          _StatRow(label: 'Not Outs',
              value: '${stats.notOuts}', subtitle: 'Times not dismissed'),
        ],
      )),
      _AnimatedStatCard(index: 3, child: _StatSection(
        title: 'Shot Breakdown',
        children: [
          _StatRow(label: 'Balls Faced',
              value: '${stats.totalBallsFaced}',
              subtitle: 'Total deliveries received'),
          _StatRow(label: 'Fours',
              value: '${stats.totalFours}', subtitle: 'Boundary hits'),
          _StatRow(label: 'Sixes',
              value: '${stats.totalSixes}', subtitle: 'Over the fence'),
          _StatRow(
            label: 'Boundary %',
            value: stats.totalBallsFaced == 0
                ? '0.0%'
                : '${(((stats.totalFours * 4 + stats.totalSixes * 6) /
                    stats.totalRuns.clamp(1, 99999)) * 100).toStringAsFixed(1)}%',
            subtitle: 'Runs from boundaries',
          ),
        ],
      )),
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
//  Bowling Tab  — bubble scroll
// ─────────────────────────────────────────────────────────────────────────────

class _BowlingTab extends StatelessWidget {
  final PlayerStats stats;
  const _BowlingTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final overs = stats.totalBallsBowled ~/ 6;
    final rem   = stats.totalBallsBowled % 6;
    final oversStr = '$overs.$rem';

    final items = <Widget>[
      _AnimatedStatCard(index: 0, child: Row(children: [
        _HeroStat(label: 'Wickets', value: '${stats.totalWickets}',
            icon: Icons.sports_cricket, color: const Color(0xFF00E676)),
        const SizedBox(width: 12),
        _HeroStat(label: 'Overs Bowled', value: oversStr,
            icon: Icons.rotate_right, color: const Color(0xFF00C4FF)),
      ])),
      _AnimatedStatCard(index: 1, child: Row(children: [
        _HeroStat(label: 'Runs Given', value: '${stats.totalRunsConceded}',
            icon: Icons.trending_up, color: const Color(0xFFFF5252)),
        const SizedBox(width: 12),
        _HeroStat(label: 'Maidens', value: '${stats.totalMaidens}',
            icon: Icons.lock_outline, color: const Color(0xFF7C4DFF)),
      ])),
      _AnimatedStatCard(index: 2, child: _StatSection(
        title: 'Efficiency Metrics',
        children: [
          _StatRow(label: 'Economy Rate',
              value: stats.economyRate.toStringAsFixed(2),
              subtitle: 'Runs conceded per over'),
          _StatRow(label: 'Bowling Average',
              value: stats.totalWickets == 0 ? '—' : stats.bowlingAverage.toStringAsFixed(2),
              subtitle: 'Runs per wicket'),
          _StatRow(label: 'Bowling Strike Rate',
              value: stats.totalWickets == 0 ? '—' : stats.bowlingStrikeRate.toStringAsFixed(1),
              subtitle: 'Balls per wicket'),
          _StatRow(label: 'Maiden Rate',
              value: overs == 0 ? '0.0%' : '${((stats.totalMaidens / overs) * 100).toStringAsFixed(1)}%',
              subtitle: 'Maidens as % of overs'),
        ],
      )),
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
//  Fielding Tab  — bubble scroll
// ─────────────────────────────────────────────────────────────────────────────

class _FieldingTab extends StatelessWidget {
  final PlayerStats stats;
  const _FieldingTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.catches + stats.stumpings + stats.runOuts;
    final items = <Widget>[
      _AnimatedStatCard(index: 0, child: Row(children: [
        _HeroStat(label: 'Total Dismissals', value: '$total',
            icon: Icons.sports_handball, color: const Color(0xFF00C4FF)),
        const SizedBox(width: 12),
        _HeroStat(label: 'Catches', value: '${stats.catches}',
            icon: Icons.back_hand, color: const Color(0xFF00E676)),
      ])),
      _AnimatedStatCard(index: 1, child: Row(children: [
        _HeroStat(label: 'Stumpings', value: '${stats.stumpings}',
            icon: Icons.sports_cricket, color: const Color(0xFFFFD700)),
        const SizedBox(width: 12),
        _HeroStat(label: 'Run Outs', value: '${stats.runOuts}',
            icon: Icons.directions_run, color: const Color(0xFFFF5252)),
      ])),
      _AnimatedStatCard(index: 2, child: _StatSection(
        title: 'Breakdown',
        children: [
          _StatRow(label: 'Catches', value: '${stats.catches}',
              subtitle: 'Direct catches taken'),
          _StatRow(label: 'Stumpings', value: '${stats.stumpings}',
              subtitle: 'Wicketkeeper dismissals'),
          _StatRow(label: 'Run Outs', value: '${stats.runOuts}',
              subtitle: 'Direct throw dismissals'),
          _StatRow(label: 'Total Contributions', value: '$total',
              subtitle: 'All fielding dismissals'),
        ],
      )),
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
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    // Staggered delay per card index
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
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable UI components
// ─────────────────────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HeroStat({
    required this.label, required this.value,
    required this.icon, required this.color,
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
                Text(value, style: TextStyle(
                  color: color, fontSize: 22,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                )),
                Text(label, style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11, fontFamily: 'Poppins',
                )),
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
            child: Text(title, style: const TextStyle(
              color: Color(0xFF00C4FF), fontSize: 13,
              fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
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
  const _StatRow({required this.label, required this.value, required this.subtitle});

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
              Text(label, style: const TextStyle(
                color: Colors.white, fontSize: 14,
                fontFamily: 'Poppins', fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11, fontFamily: 'Poppins',
              )),
            ],
          ),
          Text(value, style: const TextStyle(
            color: Color(0xFF00C4FF), fontSize: 18,
            fontFamily: 'Poppins', fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}