import 'package:TURF_TOWN_/src/Pages/Teams/scoreboard_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/cricket_scorer_screen.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:TURF_TOWN_/src/Menus/setting.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:TURF_TOWN_/src/Pages/Teams/cricket_scorer_screen.dart';
import 'package:TURF_TOWN_/src/models/match_history.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum MatchFilter { all, onProgress, paused, completed }

class _HistoryPageState extends State<HistoryPage> with WidgetsBindingObserver {
  List<MatchHistory> _completedMatches = [];
  List<MatchHistory> _pausedMatches = [];
  List<MatchHistory> _onProgressMatches = [];
  bool _isLoading = true;
  MatchFilter _selectedFilter = MatchFilter.all;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addObserver(this);
    _loadMatchHistories();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('📱 HistoryPage lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 HistoryPage: App resumed — reloading match histories...');
      _loadMatchHistories();
    }
  }

Future<void> _loadMatchHistories() async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    await MatchHistory.loadFromFirestore();
    MatchHistory.cleanupStaleEntries();

    final allMatches = MatchHistory.getAll();

    // ✅ Preload innings for all matches so scorecard works offline
    await Future.wait(
      allMatches.map((match) => Innings.loadForMatch(match.matchId)),
    );

    debugPrint('📋 Total matches in DB: ${allMatches.length}');

    _onProgressMatches = allMatches
        .where((match) => match.isOnProgress && !match.isCompleted)
        .toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

    _pausedMatches = allMatches
        .where((match) => match.isPaused && !match.isOnProgress && !match.isCompleted)
        .toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

    _completedMatches = allMatches
        .where((match) => match.isCompleted && !match.isPaused)
        .toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

    if (mounted) setState(() => _isLoading = false);
  } catch (e) {
    debugPrint('❌ Error loading match histories: $e');
    if (mounted) setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF140088),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Cricket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Scorer',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.headphones,
                              color: Colors.white, size: 24),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(CupertinoIcons.headphones,
                                        color: Color(0xFF140088)),
                                    const SizedBox(width: 10),
                                    const Text('Support'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'For any queries or support, please contact us:',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.email,
                                            size: 20, color: Color(0xFF140088)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SelectableText(
                                            'antony.cyril@aerobiosys.com',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.business,
                                            size: 20, color: Color(0xFF140088)),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Aerobiosys Innovation Pvt.Ltd',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings,
                              color: Colors.white, size: 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Section
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FILTER MATCHES',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', MatchFilter.all),
                          const SizedBox(width: 10),
                          _buildFilterChip(
                              'OnProgress', MatchFilter.onProgress),
                          const SizedBox(width: 10),
                          _buildFilterChip('Paused', MatchFilter.paused),
                          const SizedBox(width: 10),
                          _buildFilterChip(
                              'Completed', MatchFilter.completed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Matches List with PageView
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : (_pausedMatches.isEmpty &&
                            _completedMatches.isEmpty &&
                            _onProgressMatches.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No match history yet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Completed and paused matches will appear here',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _selectedFilter = MatchFilter.values[index];
                              });
                            },
                            children: [
                              _buildMatchList(showAll: true),
                              _buildMatchList(showOnProgress: true),
                              _buildMatchList(showPaused: true),
                              _buildMatchList(showCompleted: true),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchList({
    bool showAll = false,
    bool showOnProgress = false,
    bool showPaused = false,
    bool showCompleted = false,
  }) {
    final hasMatches = showAll
        ? (_onProgressMatches.isNotEmpty ||
            _pausedMatches.isNotEmpty ||
            _completedMatches.isNotEmpty)
        : showOnProgress
            ? _onProgressMatches.isNotEmpty
            : showPaused
                ? _pausedMatches.isNotEmpty
                : _completedMatches.isNotEmpty;

    if (!hasMatches) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              showAll
                  ? 'No matches yet'
                  : showOnProgress
                      ? 'No on-progress matches'
                      : showPaused
                          ? 'No paused matches'
                          : 'No completed matches',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadMatchHistories();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── OnProgress Matches Section ──
          if ((showAll || showOnProgress) && _onProgressMatches.isNotEmpty) ...[
            if (showAll)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ON PROGRESS MATCHES - TAP TO CONTINUE',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            if (showAll) const SizedBox(height: 12),
            ..._onProgressMatches.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOnProgressMatchCard(match),
                )),
            if (showAll) const SizedBox(height: 24),
          ],

          // ── Paused Matches Section ──
          if ((showAll || showPaused) && _pausedMatches.isNotEmpty) ...[
            if (showAll)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A4A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PAUSED MATCHES - TAP TO RESUME',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            if (showAll) const SizedBox(height: 12),
            ..._pausedMatches.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPausedMatchCard(match),
                )),
            if (showAll) const SizedBox(height: 24),
          ],

          // ── Completed Matches Section ──
          if ((showAll || showCompleted) && _completedMatches.isNotEmpty) ...[
            if (showAll)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A4A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'COMPLETED MATCHES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            if (showAll) const SizedBox(height: 12),
            ..._completedMatches.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMatchHistoryCard(match),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildOnProgressMatchCard(MatchHistory matchHistory) {
    final teamA = Team.getById(matchHistory.teamAId);
    final teamB = Team.getById(matchHistory.teamBId);
    final team1Color = _getTeamColor(matchHistory.teamAId);
    final team2Color = _getTeamColor(matchHistory.teamBId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matchHistory.matchType.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMatchDate(matchHistory.matchDate),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (matchHistory.matchStartTime != null)
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 10, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(matchHistory.matchStartTime!),
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams
          _buildTeamRow(
            teamA?.teamName ?? 'Team A',
            team1Color,
            '${matchHistory.team1Runs}/${matchHistory.team1Wickets}',
            '(${matchHistory.team1Overs.toStringAsFixed(1)})',
            textColor: Colors.white,
          ),
          const SizedBox(height: 10),
          _buildTeamRow(
            teamB?.teamName ?? 'Team B',
            team2Color,
            '${matchHistory.team2Runs}/${matchHistory.team2Wickets}',
            '(${matchHistory.team2Overs.toStringAsFixed(1)})',
            textColor: Colors.white,
          ),
          const SizedBox(height: 12),

          // In-Progress Banner
          GestureDetector(
            onTap: () => _resumeMatch(matchHistory),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4CAF50), width: 1),
              ),
              child: const Text(
                '🟢 IN PROGRESS - TAP TO CONTINUE',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OnProgress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToScorecard(matchHistory),
                child: const Text(
                  'Scorecard',
                  style:
                      TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share,
                    size: 18, color: Color(0xFF4CAF50)),
                onPressed: () => _shareMatchAsPDF(matchHistory),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFF4CAF50)),
                onPressed: () => _showDeleteConfirmation(matchHistory),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryCard(MatchHistory matchHistory) {
    final teamA = Team.getById(matchHistory.teamAId);
    final teamB = Team.getById(matchHistory.teamBId);
    final team1Color = _getTeamColor(matchHistory.teamAId);
    final team2Color = _getTeamColor(matchHistory.teamBId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Header with Date and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matchHistory.matchType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMatchDate(matchHistory.matchDate),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (matchHistory.matchStartTime != null &&
                  matchHistory.matchEndTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 10, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(matchHistory.matchStartTime!),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '↓',
                      style: TextStyle(color: Colors.black38, fontSize: 8),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 10, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(matchHistory.matchEndTime!),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams
          _buildTeamRow(
            teamA?.teamName ?? 'Team A',
            team1Color,
            '${matchHistory.team1Runs}/${matchHistory.team1Wickets}',
            '(${matchHistory.team1Overs.toStringAsFixed(1)})',
          ),
          const SizedBox(height: 10),
          _buildTeamRow(
            teamB?.teamName ?? 'Team B',
            team2Color,
            '${matchHistory.team2Runs}/${matchHistory.team2Wickets}',
            '(${matchHistory.team2Overs.toStringAsFixed(1)})',
          ),
          const SizedBox(height: 12),

          // Result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              matchHistory.result,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          // Match Duration
          if (matchHistory.matchStartTime != null &&
              matchHistory.matchEndTime != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Duration: ${_formatDuration(matchHistory.matchStartTime!, matchHistory.matchEndTime!)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToScorecard(matchHistory),
                child: const Text(
                  'Scorecard',
                  style: TextStyle(color: Colors.blue, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share,
                    size: 18, color: Colors.black54),
                onPressed: () => _shareMatchAsPDF(matchHistory),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.black54),
                onPressed: () => _showDeleteConfirmation(matchHistory),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPausedMatchCard(MatchHistory matchHistory) {
    final teamA = Team.getById(matchHistory.teamAId);
    final teamB = Team.getById(matchHistory.teamBId);
    final team1Color = _getTeamColor(matchHistory.teamAId);
    final team2Color = _getTeamColor(matchHistory.teamBId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C54),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Header with Date and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matchHistory.matchType.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMatchDate(matchHistory.matchDate),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (matchHistory.matchStartTime != null &&
                  matchHistory.matchEndTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 10, color: Color(0xFFFFD700)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(matchHistory.matchStartTime!),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '⏸',
                      style:
                          TextStyle(color: Color(0xFFFFD700), fontSize: 8),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 10, color: Color(0xFFFFD700)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(matchHistory.matchEndTime!),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else if (matchHistory.matchStartTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 10, color: Color(0xFFFFD700)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(matchHistory.matchStartTime!),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Started',
                      style:
                          TextStyle(color: Color(0xFFFFD700), fontSize: 8),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams
          _buildTeamRow(
            teamA?.teamName ?? 'Team A',
            team1Color,
            '${matchHistory.team1Runs}/${matchHistory.team1Wickets}',
            '(${matchHistory.team1Overs.toStringAsFixed(1)})',
            textColor: Colors.white,
          ),
          const SizedBox(height: 10),
          _buildTeamRow(
            teamB?.teamName ?? 'Team B',
            team2Color,
            '${matchHistory.team2Runs}/${matchHistory.team2Wickets}',
            '(${matchHistory.team2Overs.toStringAsFixed(1)})',
            textColor: Colors.white,
          ),
          const SizedBox(height: 12),

          // Paused Status Banner
          GestureDetector(
            onTap: () => _resumeMatch(matchHistory),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: const Color(0xFFFFD700), width: 1),
              ),
              child: const Text(
                '⏸ PAUSED - TAP TO RESUME',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Match Duration (time elapsed before pause)
          if (matchHistory.matchStartTime != null &&
              matchHistory.matchEndTime != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Color(0xFFFFD700)),
                  const SizedBox(width: 6),
                  Text(
                    'Duration before pause: ${_formatDuration(matchHistory.matchStartTime!, matchHistory.matchEndTime!)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Paused',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _navigateToScorecard(matchHistory),
                child: const Text(
                  'Scorecard',
                  style: TextStyle(
                      color: Color(0xFFFFD700), fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share,
                    size: 18, color: Color(0xFFFFD700)),
                onPressed: () => _shareMatchAsPDF(matchHistory),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFFFD700)),
                onPressed: () => _showDeleteConfirmation(matchHistory),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resumeMatch(MatchHistory matchHistory) {
    if (matchHistory.pausedState == null ||
        matchHistory.pausedState!.isEmpty) {
      final innings = Innings.getFirstInnings(matchHistory.matchId);
      if (innings == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Match state not available to resume'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final score = Score.getByInningsId(innings.inningsId);
      if (score == null ||
          score.strikeBatsmanId.isEmpty ||
          score.currentBowlerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Match data incomplete, cannot resume'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CricketScorerScreen(
            matchId: matchHistory.matchId,
            inningsId: innings.inningsId,
            strikeBatsmanId: score.strikeBatsmanId,
            nonStrikeBatsmanId: score.nonStrikeBatsmanId,
            bowlerId: score.currentBowlerId,
            isResumed: true,
          ),
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> stateMap =
          jsonDecode(matchHistory.pausedState!);
      final String inningsId =
          stateMap['inningsId'] ?? matchHistory.matchId;
      final String strikeBatsmanId = stateMap['strikeBatsmanId'] ?? '';
      final String nonStrikeBatsmanId =
          stateMap['nonStrikeBatsmanId'] ?? '';
      final String bowlerId = stateMap['bowlerId'] ?? '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CricketScorerScreen(
            matchId: matchHistory.matchId,
            inningsId: inningsId,
            strikeBatsmanId: strikeBatsmanId,
            nonStrikeBatsmanId: nonStrikeBatsmanId,
            bowlerId: bowlerId,
            isResumed: true,
          ),
        ),
      );
    } catch (e) {
      print('Error parsing paused state: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resuming match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

Future<void> _navigateToScorecard(MatchHistory matchHistory) async {
  // First try from cache
  var innings = Innings.getFirstInnings(matchHistory.matchId);

  // If not in cache, try loading from Firestore
  if (innings == null) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Load innings for this match from Firestore
      await Innings.loadForMatch(matchHistory.matchId);

      if (Navigator.canPop(context)) Navigator.pop(context);

      innings = Innings.getFirstInnings(matchHistory.matchId);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint('❌ Error loading innings: $e');
    }
  }

  if (innings != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreboardPage(
          matchId: matchHistory.matchId,
          inningsId: innings!.inningsId,
        ),
      ),
    );
  } else {
    // Fallback: navigate with matchId only, let ScoreboardPage handle loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loading scorecard data...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // Still navigate — ScoreboardPage may handle its own data loading
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreboardPage(
          matchId: matchHistory.matchId,
          inningsId: matchHistory.matchId, // fallback: use matchId as inningsId
        ),
      ),
    );
  }
}

  Future<void> _shareMatchAsPDF(MatchHistory matchHistory) async {
    final shareOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Match Scorecard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.pop(context, 'whatsapp'),
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.blue),
              title: const Text('Messages'),
              onTap: () => Navigator.pop(context, 'messages'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: Colors.purple),
              title: const Text('Instagram'),
              onTap: () => Navigator.pop(context, 'instagram'),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Other'),
              onTap: () => Navigator.pop(context, 'other'),
            ),
          ],
        ),
      ),
    );

    if (shareOption == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final teamA = Team.getById(matchHistory.teamAId);
      final teamB = Team.getById(matchHistory.teamBId);

      final allInnings = Innings.getByMatchId(matchHistory.matchId);
      final firstInnings = allInnings.isNotEmpty ? allInnings[0] : null;
      final secondInnings =
          allInnings.length > 1 ? allInnings[1] : null;

      final firstInningsScore = firstInnings != null
          ? Score.getByInningsId(firstInnings.inningsId)
          : null;
      final secondInningsScore = secondInnings != null
          ? Score.getByInningsId(secondInnings.inningsId)
          : null;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: PdfColors.blue900,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CRICKET MATCH SCORECARD',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      matchHistory.matchType.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border:
                      pw.Border.all(color: PdfColors.grey400, width: 2),
                ),
                child: pw.Column(
                  children: [
                    _buildPDFTeamRow(
                      teamA?.teamName ?? 'Team A',
                      matchHistory.team1Runs,
                      matchHistory.team1Wickets,
                      matchHistory.team1Overs,
                      firstInningsScore?.totalExtras ?? 0,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Divider(thickness: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 20),
                    _buildPDFTeamRow(
                      teamB?.teamName ?? 'Team B',
                      matchHistory.team2Runs,
                      matchHistory.team2Wickets,
                      matchHistory.team2Overs,
                      secondInningsScore?.totalExtras ?? 0,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(
                      color: PdfColors.green700, width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MATCH RESULT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      matchHistory.result,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
              if (firstInnings != null && firstInningsScore != null) ...[
                pw.SizedBox(height: 40),
                pw.Text(
                  'FIRST INNINGS - ${firstInnings.battingTeamId == matchHistory.teamAId ? teamA?.teamName ?? "Team A" : teamB?.teamName ?? "Team B"}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 15),
                _buildInningsDetails(firstInnings, firstInningsScore),
              ],
              if (secondInnings != null &&
                  secondInningsScore != null) ...[
                pw.SizedBox(height: 40),
                pw.Text(
                  'SECOND INNINGS - ${secondInnings.battingTeamId == matchHistory.teamAId ? teamA?.teamName ?? "Team A" : teamB?.teamName ?? "Team B"}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 15),
                _buildInningsDetails(secondInnings, secondInningsScore),
              ],
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Generated by Cricket Scorer App',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  DateTime.now().toString().split('.')[0],
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final fileName =
          'match_${matchHistory.matchId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Navigator.canPop(context)) Navigator.pop(context);

      final shareText =
          '🏏 Cricket Match Result\n${teamA?.teamName ?? 'Team A'} vs ${teamB?.teamName ?? 'Team B'}';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Cricket Match Scorecard',
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing match: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error generating PDF: $e');
    }
  }

  pw.Widget _buildInningsDetails(Innings innings, Score score) {
    final batsmen = Batsman.getByInningsId(innings.inningsId);
    final bowlers = Bowler.getByInningsId(innings.inningsId);

    final battingStats = <Map<String, dynamic>>[];
    for (final batsman in batsmen) {
      final player = TeamMember.getByPlayerId(batsman.playerId);
      battingStats.add({
        'playerName': player?.teamName ?? 'Unknown',
        'runs': batsman.runs,
        'balls': batsman.ballsFaced,
        'fours': batsman.fours,
        'sixes': batsman.sixes,
        'strikeRate': batsman.strikeRate,
      });
    }

    final bowlingStats = <Map<String, dynamic>>[];
    for (final bowler in bowlers) {
      final player = TeamMember.getByPlayerId(bowler.playerId);
      bowlingStats.add({
        'playerName': player?.teamName ?? 'Unknown',
        'overs': bowler.overs,
        'maidens': bowler.maidens,
        'runs': bowler.runsConceded,
        'wickets': bowler.wickets,
        'economy': bowler.economy,
      });
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (battingStats.isNotEmpty) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BATTING',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Text(
                'Extras: ${score.extrasDisplay}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Batsman', isHeader: true),
                  _buildTableCell('R', isHeader: true),
                  _buildTableCell('B', isHeader: true),
                  _buildTableCell('4s', isHeader: true),
                  _buildTableCell('6s', isHeader: true),
                  _buildTableCell('SR', isHeader: true),
                ],
              ),
              ...battingStats.map((stat) => pw.TableRow(
                    children: [
                      _buildTableCell(stat['playerName'] ?? 'Unknown'),
                      _buildTableCell(stat['runs']?.toString() ?? '0'),
                      _buildTableCell(stat['balls']?.toString() ?? '0'),
                      _buildTableCell(stat['fours']?.toString() ?? '0'),
                      _buildTableCell(stat['sixes']?.toString() ?? '0'),
                      _buildTableCell(
                          stat['strikeRate']?.toStringAsFixed(1) ??
                              '0.0'),
                    ],
                  )),
            ],
          ),
        ],
        if (battingStats.isNotEmpty && bowlingStats.isNotEmpty)
          pw.SizedBox(height: 30),
        if (bowlingStats.isNotEmpty) ...[
          pw.Text(
            'BOWLING',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Bowler', isHeader: true),
                  _buildTableCell('O', isHeader: true),
                  _buildTableCell('M', isHeader: true),
                  _buildTableCell('R', isHeader: true),
                  _buildTableCell('W', isHeader: true),
                  _buildTableCell('Econ', isHeader: true),
                ],
              ),
              ...bowlingStats.map((stat) => pw.TableRow(
                    children: [
                      _buildTableCell(stat['playerName'] ?? 'Unknown'),
                      _buildTableCell(
                          stat['overs']?.toStringAsFixed(1) ?? '0.0'),
                      _buildTableCell(
                          stat['maidens']?.toString() ?? '0'),
                      _buildTableCell(stat['runs']?.toString() ?? '0'),
                      _buildTableCell(
                          stat['wickets']?.toString() ?? '0'),
                      _buildTableCell(
                          stat['economy']?.toStringAsFixed(2) ?? '0.00'),
                    ],
                  )),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight:
              isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildPDFTeamRow(
      String teamName, int runs, int wickets, double overs, int extras) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            teamName,
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '$runs/$wickets',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '(${overs.toStringAsFixed(1)} overs)',
                style: pw.TextStyle(
                    fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Extras: $extras',
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, MatchFilter filter) {
    final isSelected = _selectedFilter == filter;
    int count = 0;

    if (filter == MatchFilter.onProgress) {
      count = _onProgressMatches.length;
    } else if (filter == MatchFilter.paused) {
      count = _pausedMatches.length;
    } else if (filter == MatchFilter.completed) {
      count = _completedMatches.length;
    } else {
      count = _onProgressMatches.length +
          _pausedMatches.length +
          _completedMatches.length;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            filter.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700)
              : const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black26 : Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color:
                      isSelected ? Colors.black : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(MatchHistory matchHistory) {
    final teamA = Team.getById(matchHistory.teamAId);
    final teamB = Team.getById(matchHistory.teamBId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: Text(
          'Are you sure you want to delete this match?\n\n${teamA?.teamName ?? 'Team A'} vs ${teamB?.teamName ?? 'Team B'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              matchHistory.delete();
              Navigator.pop(context);
              _loadMatchHistories();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Match deleted from history'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String teamId) {
    final hash = teamId.hashCode;
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.teal,
      const Color(0xFF7C4DFF),
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildTeamRow(
      String team, Color color, String score, String overs,
      {Color? textColor}) {
    final displayTextColor = textColor ?? Colors.black;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 14,
          child: Text(
            team.isNotEmpty ? team[0].toUpperCase() : 'T',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            team,
            style: TextStyle(
              color: displayTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          score,
          style: TextStyle(
            color: displayTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        if (overs.isNotEmpty)
          Text(
            ' $overs',
            style: TextStyle(
              color: displayTextColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final matchDate = DateTime(date.year, date.month, date.day);

    if (matchDate == today) {
      return 'Today';
    } else if (matchDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}