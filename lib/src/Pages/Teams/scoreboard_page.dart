import 'package:flutter/material.dart';
import 'dart:async';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/team.dart';

class ScoreboardPage extends StatefulWidget {
  final String matchId;
  final String inningsId;

  const ScoreboardPage({
    Key? key,
    required this.matchId,
    required this.inningsId,
  }) : super(key: key);

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  Timer? _refreshTimer;
  bool _isAutoRefreshEnabled = true;
  bool _isFirstInningsExpanded = true;
  bool _isSecondInningsExpanded = true;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // In your scoring/match controller or wherever you record balls

  // Method to record a wide
  void recordWide(String inningsId, String bowlerId, int extraRuns) {
    final score = Score.getByInningsId(inningsId);
    if (score != null) {
      final totalRuns = 1 + extraRuns; // 1 for wide + any additional runs
      score.totalRuns += totalRuns;
      score.wides++;
      score.save();

      // Update bowler
      final bowler = Bowler.getByBowlerId(bowlerId);
      if (bowler != null) {
        bowler.updateStats(
          totalRuns,
          false,
          extrasRuns: totalRuns,
          countBall: false,
        );
      }
    }
  }

  // Method to record a no-ball
  void recordNoBall(
    String inningsId,
    String bowlerId,
    String batsmanId,
    int batsmanRuns,
  ) {
    final score = Score.getByInningsId(inningsId);
    if (score != null) {
      final totalRuns = 1 + batsmanRuns; // 1 for no-ball + runs off bat
      score.totalRuns += totalRuns;
      score.noBalls++;
      score.save();

      // Update bowler
      final bowler = Bowler.getByBowlerId(bowlerId);
      if (bowler != null) {
        bowler.updateStats(totalRuns, false, extrasRuns: 1, countBall: false);
      }

      // Update batsman (gets runs but ball doesn't count)
      final batsman = Batsman.getByBatId(batsmanId);
      if (batsman != null) {
        batsman.updateStats(batsmanRuns, extrasRuns: 1, countBall: false);
      }
    }
  }

  // Method to record byes
  void recordBye(
    String inningsId,
    String bowlerId,
    String batsmanId,
    int runs,
  ) {
    final score = Score.getByInningsId(inningsId);
    if (score != null) {
      score.totalRuns += runs;
      score.byes++;
      score.save();

      // Update bowler (counts as a legal ball)
      final bowler = Bowler.getByBowlerId(bowlerId);
      if (bowler != null) {
        bowler.updateStats(runs, false, extrasRuns: runs, countBall: true);
      }

      // Update batsman (faces ball but gets no runs)
      final batsman = Batsman.getByBatId(batsmanId);
      if (batsman != null) {
        batsman.updateStats(0, extrasRuns: runs, countBall: true);
      }
    }
  }

  // Method to record a normal ball
  void recordNormalBall(
    String inningsId,
    String bowlerId,
    String batsmanId,
    int runs,
    bool isWicket,
  ) {
    final score = Score.getByInningsId(inningsId);
    if (score != null) {
      score.totalRuns += runs;
      if (isWicket) {
        score.wickets++;
      }
      score.save();

      // Update bowler
      final bowler = Bowler.getByBowlerId(bowlerId);
      if (bowler != null) {
        bowler.updateStats(runs, isWicket, countBall: true);
      }

      // Update batsman
      final batsman = Batsman.getByBatId(batsmanId);
      if (batsman != null) {
        batsman.updateStats(runs, countBall: true);
        if (isWicket) {
          batsman.markAsOut(bowlerIdWhoGotWicket: bowlerId);
        }
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isAutoRefreshEnabled && mounted) {
        setState(() {
          // This will trigger a rebuild and fetch fresh data
        });
      }
    });
  }

  void _toggleAutoRefresh() {
    setState(() {
      _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
    });
  }

  void _manualRefresh() {
    setState(() {
      // Force refresh
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scoreboard refreshed'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final match = Match.getByMatchId(widget.matchId);

  final firstInnings = Innings.getFirstInnings(widget.matchId);
  final secondInnings = Innings.getSecondInnings(widget.matchId);

  final innings = firstInnings ?? Innings.getByInningsId(widget.inningsId);

  if (match == null || innings == null) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appbg1.mainGradient),
        child: const Center(
          child: Text(
            'Error loading scoreboard',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  final firstInningsScore = firstInnings != null
      ? Score.getByInningsId(firstInnings.inningsId)
      : null;
  final secondInningsScore = secondInnings != null
      ? Score.getByInningsId(secondInnings.inningsId)
      : null;

  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: Appbg1.mainGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${Team.getById(firstInnings?.battingTeamId ?? innings.battingTeamId)?.teamName ?? "Team 1"} v/s ${Team.getById(firstInnings?.bowlingTeamId ?? innings.bowlingTeamId)?.teamName ?? "Team 2"}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _manualRefresh,
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    icon: Icon(
                      _isAutoRefreshEnabled
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: _isAutoRefreshEnabled
                          ? const Color(0xFF4CAF50)
                          : Colors.white,
                    ),
                    onPressed: _toggleAutoRefresh,
                    tooltip: _isAutoRefreshEnabled
                        ? 'Pause auto-refresh'
                        : 'Resume auto-refresh',
                  ),
                ],
              ),
            ),

            if (_isAutoRefreshEnabled)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live • Auto-refreshing every 2s',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (firstInnings != null && firstInningsScore != null)
                      _buildInningsSection(
                        firstInnings,
                        firstInningsScore,
                        match,
                        isExpanded: _isFirstInningsExpanded,
                        onToggle: () {
                          setState(() {
                            _isFirstInningsExpanded =
                                !_isFirstInningsExpanded;
                          });
                        },
                      ),

                    const SizedBox(height: 16),

                    if (secondInnings != null && secondInningsScore != null)
                      _buildInningsSection(
                        secondInnings,
                        secondInningsScore,
                        match,
                        isExpanded: _isSecondInningsExpanded,
                        onToggle: () {
                          setState(() {
                            _isSecondInningsExpanded =
                                !_isSecondInningsExpanded;
                          });
                        },
                      ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'Last updated: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Color(0xFF9AA0A6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildInningsSection(
    Innings innings,
    Score score,
    Match match, {
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final battingTeam = Team.getById(innings.battingTeamId);
    final bowlingTeam = Team.getById(innings.bowlingTeamId);

    // Get all batsmen for this innings
    final allBatsmen = Batsman.getByInningsAndTeam(
      innings.inningsId,
      innings.battingTeamId,
    );

    // Separate current batsmen and out batsmen
    final currentBatsmen = allBatsmen.where((b) => !b.isOut).toList();
    final outBatsmen = allBatsmen.where((b) => b.isOut).toList();

    // Get all bowlers for this innings
    final allBowlers = Bowler.getByInningsAndTeam(
      innings.inningsId,
      innings.bowlingTeamId,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F24),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Innings Header (Always visible, clickable)
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6D7CFF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isExpanded
                      ? Radius.zero
                      : const Radius.circular(12),
                  bottomRight: isExpanded
                      ? Radius.zero
                      : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          battingTeam?.teamName ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'vs ${bowlingTeam?.teamName ?? "Unknown"}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.totalRuns}-${score.wickets}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${score.overs.toStringAsFixed(1)} Ov',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CRR: ${score.crr.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          if (isExpanded) ...[
            // Batsmen Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batsman header
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Batsman',
                          style: TextStyle(
                            color: Color(0xFF9AA0A6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildCompactTableHeader('R', 1),
                      _buildCompactTableHeader('B', 1),
                      _buildCompactTableHeader('4s', 1),
                      _buildCompactTableHeader('6s', 1),
                      _buildCompactTableHeader('SR', 1),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),

                  // Current batsmen
                  ...currentBatsmen.map(
                    (batsman) => _buildBatsmanRow(batsman, isCurrent: true),
                  ),

                  // Out batsmen
                  ...outBatsmen.map(
                    (batsman) => _buildBatsmanRow(batsman, isCurrent: false),
                  ),

                  // Extras row
                  const SizedBox(height: 8),
                  // Replace the Extras row section with this:
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Extras',
                          style: TextStyle(
                            color: Color(0xFF9AA0A6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          score.extrasDisplay,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF9AA0A6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),

                  // Total row - Separated into columns to avoid overlay
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          score.totalRuns.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          score.wickets.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          score.overs.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          score.crr.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // Bowlers Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bowler header
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Bowler',
                          style: TextStyle(
                            color: Color(0xFF9AA0A6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildCompactTableHeader('O', 1),
                      _buildCompactTableHeader('M', 1),
                      _buildCompactTableHeader('R', 1),
                      _buildCompactTableHeader('W', 1),
                      _buildCompactTableHeader('ER', 1),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),

                  // Bowlers list
                  ...allBowlers.map((bowler) => _buildBowlerRow(bowler)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactTableHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF9AA0A6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBatsmanRow(Batsman batsman, {required bool isCurrent}) {
    final player = TeamMember.getByPlayerId(batsman.playerId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCurrent)
                      const Icon(
                        Icons.circle,
                        color: Color(0xFF4CAF50),
                        size: 6,
                      ),
                    if (isCurrent) const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        player?.teamName ?? 'Unknown',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : const Color(0xFF9AA0A6),
                          fontSize: 12,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Always show dismissal status
                const SizedBox(height: 2),
                Text(
                  _getOutText(batsman),
                  style: TextStyle(
                    color: batsman.isOut
                        ? const Color(0xFFFF6B6B) // Red for out
                        : const Color(0xFF4CAF50), // Green for not out
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _buildCompactTableCell(batsman.runs.toString(), 1, isCurrent),
          _buildCompactTableCell(batsman.ballsFaced.toString(), 1, isCurrent),
          _buildCompactTableCell(batsman.fours.toString(), 1, isCurrent),
          _buildCompactTableCell(batsman.sixes.toString(), 1, isCurrent),
          _buildCompactTableCell(
            batsman.strikeRate.toStringAsFixed(0),
            1,
            isCurrent,
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(Bowler bowler) {
    final player = TeamMember.getByPlayerId(bowler.playerId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              player?.teamName ?? 'Unknown',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildCompactTableCell(bowler.overs.toStringAsFixed(1), 1, false),
          _buildCompactTableCell(bowler.maidens.toString(), 1, false),
          _buildCompactTableCell(bowler.runsConceded.toString(), 1, true),
          _buildCompactTableCell(bowler.wickets.toString(), 1, true),
          _buildCompactTableCell(bowler.economy.toStringAsFixed(1), 1, false),
        ],
      ),
    );
  }

  Widget _buildCompactTableCell(String text, int flex, bool isHighlighted) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHighlighted ? Colors.white : const Color(0xFF9AA0A6),
          fontSize: 12,
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  String _getOutText(Batsman batsman) {
    print(
      'DEBUG _getOutText: batId=${batsman.batId}, isOut=${batsman.isOut}, dismissalType=${batsman.dismissalType}, fielderIdWhoRanOut=${batsman.fielderIdWhoRanOut}, bowlerIdWhoGotWicket=${batsman.bowlerIdWhoGotWicket}',
    );

    if (!batsman.isOut) {
      return 'not out';
    }

    // Handle runout dismissal
    if (batsman.dismissalType == 'runout') {
      print('DEBUG: Processing runout dismissal');

      if (batsman.fielderIdWhoRanOut != null &&
          batsman.fielderIdWhoRanOut!.isNotEmpty) {
        print('DEBUG: fielderIdWhoRanOut = ${batsman.fielderIdWhoRanOut}');

        // Get the fielder directly by their player ID
        final fielder = TeamMember.getByPlayerId(batsman.fielderIdWhoRanOut!);

        if (fielder != null) {
          print('DEBUG: Found fielder - ${fielder.teamName}');
          return 'run out (${fielder.teamName})';
        } else {
          print(
            'DEBUG: Fielder not found for playerId: ${batsman.fielderIdWhoRanOut}',
          );
        }
      } else {
        print('DEBUG: fielderIdWhoRanOut is null or empty');
      }

      return 'run out';
    }

    // Handle normal wicket (bowled, caught, etc.)
    if (batsman.dismissalType != null && batsman.dismissalType!.isNotEmpty) {
      print('DEBUG: Processing ${batsman.dismissalType} dismissal');

      if (batsman.bowlerIdWhoGotWicket != null &&
          batsman.bowlerIdWhoGotWicket!.isNotEmpty) {
        final bowler = Bowler.getByBowlerId(batsman.bowlerIdWhoGotWicket!);
        if (bowler != null) {
          final bowlerPlayer = TeamMember.getByPlayerId(bowler.playerId);
          if (bowlerPlayer != null) {
            return 'b ${bowlerPlayer.teamName}';
          }
        }
      }
    }

    print('DEBUG: Falling back to generic "out"');
    return 'out';
  }
}
