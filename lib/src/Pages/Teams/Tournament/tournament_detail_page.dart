import 'dart:io';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/Tabs/all_tabs.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';
import 'package:TURF_TOWN_/src/theme/tournament_colors.dart';
import 'package:TURF_TOWN_/src/widgets/tournament_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';



class TournamentDetailPage extends StatefulWidget {
  final Tournament tournament;
  final String Function(DateTime) formatDate;
  final String Function(Tournament) getStatus;
  final Color Function(String) getStatusColor;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TournamentDetailPage({
    super.key,
    required this.tournament,
    required this.formatDate,
    required this.getStatus,
    required this.getStatusColor,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _detailTabController;

  final List<String> _tabs = [
    'Stats', 'Matches', 'Leaderboard', 'Points Table', 'Teams', 'About',
  ];

  @override
  void initState() {
    super.initState();
    _detailTabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _detailTabController.dispose();
    super.dispose();
  }

  String get _dateRange =>
      '${widget.formatDate(widget.tournament.startDate)}  →  '
      '${widget.formatDate(widget.tournament.endDate)}';

  @override
  Widget build(BuildContext context) {
    final status = widget.getStatus(widget.tournament);
    final t = widget.tournament;
    final isOwner = t.isOwnedByCurrentUser;

    return Scaffold(
      backgroundColor: TournamentColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: TournamentColors.surface,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            leading: const BackButton(color: Colors.white),
            title: Text(t.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17),
                overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  color: TournamentColors.surfaceSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.onEdit();
                    } else if (value == 'delete') {
                      widget.onDelete();
                      Navigator.pop(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            color: TournamentColors.primaryAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            color: TournamentColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: TournamentColors.error)),
                      ]),
                    ),
                  ],
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: TournamentColors.surface,
                child: TabBar(
                  controller: _detailTabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: TournamentColors.primaryAccent,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: TournamentColors.primaryAccent,
                  unselectedLabelColor: TournamentColors.textSecondary,
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: _tabs
                      .map((label) => Tab(height: 46, child: Text(label)))
                      .toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TournamentColors.surface,
                    TournamentColors.background,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLogo(t),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: TournamentColors.textSecondary,
                                    size: 12),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(_dateRange,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: TournamentColors.textSecondary,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TournamentStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: TournamentColors.textSecondary, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('${t.city} • ${t.ground}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: TournamentColors.textSecondary,
                                fontSize: 12.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FormatBadge(tournamentId: t.tournamentId),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _detailTabController,
          children: [
            StatsTab(tournament: widget.tournament),
            MatchesTab(tournament: widget.tournament),
            LeaderboardTab(tournament: widget.tournament),
            PointsTableTab(tournament: widget.tournament),
            TeamsTab(tournament: widget.tournament),
            AboutTab(tournament: widget.tournament),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Tournament t) {
    final hasLogo = t.logoPath != null && t.logoPath!.isNotEmpty;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasLogo ? null : TournamentColors.accentGradient,
        image: hasLogo
            ? DecorationImage(image: FileImage(File(t.logoPath!)), fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: !hasLogo
          ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 30)
          : null,
    );
  }
}

// ── Format Badge ────────────────────────────────────────────────────────────

class FormatBadge extends StatelessWidget {
  final String tournamentId;
  const FormatBadge({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data?.data() as Map<String, dynamic>?;
        final formatId = data?['format'] as String?;
        if (formatId == null || formatId.isEmpty) return const SizedBox.shrink();

        final fmt = kFormats.firstWhere(
          (f) => f.id == formatId,
          orElse: () => kFormats.first,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: TournamentColors.primaryAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: TournamentColors.primaryAccent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fmt.icon, color: TournamentColors.primaryAccent, size: 13),
              const SizedBox(width: 6),
              Text(fmt.label,
                  style: const TextStyle(
                      color: TournamentColors.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}