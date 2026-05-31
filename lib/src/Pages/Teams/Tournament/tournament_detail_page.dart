import 'dart:io';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/Tabs/all_tabs.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';
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
      '${widget.formatDate(widget.tournament.startDate)} to '
      '${widget.formatDate(widget.tournament.endDate)}';

  @override
  Widget build(BuildContext context) {
    final status = widget.getStatus(widget.tournament);
    final statusColor = widget.getStatusColor(status);
    final t = widget.tournament;
    final isOwner = t.isOwnedByCurrentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF1A237E),
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            leading: const BackButton(color: Colors.white),
            title: Text(t.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
                overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  color: const Color(0xFF1A1A2E),
                  icon: const Icon(Icons.more_vert, color: Colors.white),
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
                            color: Color(0xFF00BCD4), size: 18),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: const Color(0xFF1A237E),
                child: TabBar(
                  controller: _detailTabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: const Color(0xFF00BCD4),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF00BCD4),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
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
              color: const Color(0xFF1A237E),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D0D1A),
                          border: Border.all(
                              color: const Color(0xFF00BCD4), width: 2),
                          image: (t.logoPath != null && t.logoPath!.isNotEmpty)
                              ? DecorationImage(
                                  image: FileImage(File(t.logoPath!)),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: (t.logoPath == null || t.logoPath!.isEmpty)
                            ? const Icon(Icons.emoji_events,
                                color: Color(0xFF00BCD4), size: 32)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(_dateRange,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: statusColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
            color: const Color(0xFF00BCD4).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fmt.icon, color: const Color(0xFF00BCD4), size: 13),
              const SizedBox(width: 6),
              Text(fmt.label,
                  style: const TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
} 