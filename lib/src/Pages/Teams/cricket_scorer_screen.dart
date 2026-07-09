import 'dart:convert';
import 'dart:async'; // Add this import
import 'package:TURF_TOWN_/src/Services/environment_service.dart'; // Add this
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/match_graph_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/scoreboard_page.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';
import 'dart:collection';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/match_history.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/match.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/Services/bluetooth_service.dart';
import 'package:TURF_TOWN_/src/views/Home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TURF_TOWN_/src/models/ball.dart';
import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/InitialTeamPage.dart' hide Appbg1;
import 'package:TURF_TOWN_/src/Pages/Teams/InitialTeamPage.dart';
import 'package:TURF_TOWN_/src/widgets/cricket_animations.dart';
import 'package:uuid/uuid.dart';

class CricketScorerScreen extends StatefulWidget {
  final String matchId;
  final String inningsId;
  final String strikeBatsmanId;
  final String nonStrikeBatsmanId;
  final String bowlerId;
  final bool isResumed;
  final String? tournamentMatchDocId;

  const CricketScorerScreen({
    Key? key,
    required this.matchId,
    required this.inningsId,
    required this.strikeBatsmanId,
    required this.nonStrikeBatsmanId,
    required this.bowlerId,
    this.isResumed = false,
    this.tournamentMatchDocId,
  }) : super(key: key);

  @override
  State<CricketScorerScreen> createState() => _CricketScorerScreenState();
}

class _CricketScorerScreenState extends State<CricketScorerScreen>
    with WidgetsBindingObserver {
  late Match? currentMatch;
  late Innings? currentInnings;
  late Score? currentScore;
  late Batsman? strikeBatsman;
  late Batsman? nonStrikeBatsman;
  late Bowler? currentBowler;

  bool isInitializing = true;
  bool showExtrasOptions = false;
  bool isNoBall = false;
  bool isWide = false;
  bool isByes = false;

  bool noBallEnabled = true;
  bool wideEnabled = true;
  // Global LED cancel flag — set to true the instant we want to stop ALL LED ops
  bool _ledCancelled = false;
  int runsInCurrentOver = 0;
  bool isRunout = false;
  int? pendingRunoutRuns;
  String? runoutBatsmanId;

  // LED command queue to prevent race conditions
  final Queue<Future<void> Function()> _ledQueue = Queue();
  bool _ledQueueRunning = false;
  // Match completion flag - freeze buttons when match is complete
  bool isMatchComplete = false;
  bool _firstInningsLocked = false;
  String? _battingTeamNameCache;
  String? _bowlingTeamNameCache;

  // ScrollController for focusing scorecard during runout
  late ScrollController _scrollController;

  // Lottie animation flags
  bool _showBoundaryAnimation = false;
  String? _boundaryAnimationType; // '4' or '6'
  bool _showWicketAnimation = false;
  bool _showDuckAnimation = false;
  String? _lastDuckBatsman;
  bool _showRunoutHighlight = false;
  Set<String> _cancelledBatsmanIds = {};
  bool? _lastRow74WasStriker; // null = not yet set (first update)
  int _runoutHighlightIndex = 0;
  bool _showVictoryAnimation = false;
  String? _row74PlayerId;
  // Runout mode blur and highlight - light blur (0.3) with teal tint
  bool _isRunoutModeActive = false;

  // Helper method to determine banner border color
  Color _getTargetBannerColor() {
    // Check for tie first
    if (currentScore!.totalRuns == currentInnings!.targetRuns - 1) {
      return const Color(0xFFFF9800); // Orange for tie
    } else if (currentScore!.totalRuns >= currentInnings!.targetRuns) {
      // Target met - Team B won
      return const Color(0xFF4CAF50); // Green
    } else if (_isInningsComplete() || currentScore!.wickets >= 9) {
      // Match ended without reaching target - Team A won
      return const Color(0xFF4CAF50); // Green (showing Team A victory)
    } else {
      // Still chasing
      return const Color(0xFFFF9800); // Orange
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (!isMatchComplete && !isInitializing) {
        debugPrint(
          '📱 App lifecycle: $state — cancelling LED ops and clearing...',
        );

        // Instantly cancel all pending LED ops
        _ledCancelled = true;
        _ledQueue.clear();

        _autoSaveMatchState();

        final bleService = BleManagerService();
        if (bleService.isConnected) {
          bleService
              .sendRawCommands(['CLEAR'])
              .then((_) async {
                await Future.delayed(const Duration(milliseconds: 150));
                await bleService.sendRawCommands(['CLEAR']);
                debugPrint('✅ lifecycle: display cleared on background');
              })
              .catchError((e) {
                debugPrint('❌ lifecycle clear failed: $e');
              });
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      if (!isMatchComplete && !isInitializing) {
        debugPrint('📱 App lifecycle: inactive — auto-saving only...');
        _autoSaveMatchState();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground — re-enable LED ops
      debugPrint('📱 App lifecycle: resumed — re-enabling LED ops');
      _ledCancelled = false;
    }
  }

  // Helper method to build banner content based on match state
  Widget _buildTargetBannerContent() {
    // Case 0: Match Tied (scores are equal)
    if (currentScore!.totalRuns == currentInnings!.targetRuns - 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.handshake, color: Color(0xFFFF9800), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Match Tied',
              style: TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    // Case 1: Team B won (reached or exceeded target)
    if (currentScore!.totalRuns >= currentInnings!.targetRuns) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_getBattingTeamName()} won by ${10 - currentScore!.wickets} wickets',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    // Case 2: Match ended - Team A won (LSG failed to reach target)
    else if (_isInningsComplete() || currentScore!.wickets >= 9) {
      final firstInnings = Innings.getFirstInnings(widget.matchId);
      final bowlingTeamName = firstInnings != null
          ? (Team.getById(firstInnings.battingTeamId)?.teamName ?? 'Team A')
          : 'Team A';
      final runsDifference =
          currentInnings!.targetRuns - currentScore!.totalRuns;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$bowlingTeamName won by $runsDifference runs',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    // Case 3: Still chasing - show runs needed
    else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${currentInnings!.targetRuns - currentScore!.totalRuns} runs needed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'off',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            '${((currentMatch!.overs * 6) - currentScore!.currentBall)} balls',
            style: const TextStyle(
              color: Color(0xFFFF9800),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }

  Timer? _ledUpdateTimer;
  final _envService = EnvironmentService();

  List<Map<String, dynamic>> actionHistory = [];
  String? lastOverBowlerId;

@override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);

    print('🚀 CricketScorerScreen: Initializing EnvironmentService...');
    _envService.initialize();

    // Test weather API after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _envService.testWeatherAPI();
    });

    // 🔥 DO NOT START TIMER HERE - START ONLY AFTER LAYOUT IS READY
    // Timer will be started in _sendFullLEDLayout() or _sendSecondInningsIntroLayout()

    // 🔥 FIX: Initialize match WITHOUT immediate LED drawing
    _initializeMatch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _ledUpdateTimer?.cancel();
    debugPrint('⏹️ Stopped periodic time/temp updates');

    // Instantly cancel ALL pending LED operations
    _ledCancelled = true;
    _ledQueue.clear();

    final bleService = BleManagerService();
    if (bleService.isConnected && !isMatchComplete) {
      debugPrint('🧹 dispose: clearing LED display on exit...');
      bleService
          .sendRawCommands(['CLEAR'])
          .then((_) async {
            await Future.delayed(const Duration(milliseconds: 150));
            await bleService.sendRawCommands(['CLEAR']);
            await Future.delayed(const Duration(milliseconds: 150));
            await bleService.sendRawCommands(['CLEAR']);
            debugPrint('✅ dispose: LED cleared');
          })
          .catchError((e) {
            debugPrint('❌ dispose: LED clear failed: $e');
          });
    }

    super.dispose();
  }

  Future<void> _enqueueLEDUpdate(Future<void> Function() task) async {
    if (_ledCancelled) return; // Drop immediately if cancelled
    _ledQueue.add(task);
    if (_ledQueueRunning) return;
    _ledQueueRunning = true;
    while (_ledQueue.isNotEmpty) {
      if (_ledCancelled) {
        _ledQueue.clear();
        break;
      }
      final next = _ledQueue.removeFirst();
      try {
        await next();
      } catch (e) {
        debugPrint('❌ LED queue task failed: $e');
      }
    }
    _ledQueueRunning = false;
  }

  Future<void> _initializeMatch() async {
    try {
      currentMatch = Match.getByMatchId(widget.matchId);
      if (currentMatch == null) throw Exception('Match not found');

      noBallEnabled = currentMatch!.isNoballAllowed;
      wideEnabled = currentMatch!.isWideAllowed;

      currentInnings = Innings.getByInningsId(widget.inningsId);
      if (currentInnings == null) throw Exception('Innings not found');

  // Resolve team names from tournament match doc for display
      try {
        final tournamentId = currentInnings!.tournamentId;
        if (tournamentId.isNotEmpty) {
          final matchSnap = await _resolveTournamentMatchDoc(tournamentId);

          if (matchSnap != null) {
            final mdata = matchSnap.data() ?? {};
            final t1Id = (mdata['teamId1'] as String?) ?? '';
            final t2Id = (mdata['teamId2'] as String?) ?? '';
            final t1Name = (mdata['teamId1Name'] as String?) ?? '';
            final t2Name = (mdata['teamId2Name'] as String?) ?? '';

            if (currentInnings!.battingTeamId == t1Id) {
              _battingTeamNameCache = t1Name;
              _bowlingTeamNameCache = t2Name;
            } else {
              _battingTeamNameCache = t2Name;
              _bowlingTeamNameCache = t1Name;
            }
            debugPrint(
              '✅ Team names resolved: batting=$_battingTeamNameCache, bowling=$_bowlingTeamNameCache',
            );

            try {
              await matchSnap.reference.update({'status': 'live'});
            } catch (e) {
              debugPrint('⚠️ Could not mark match as live: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not resolve team names from Firestore: $e');
      }
      currentScore = Score.getByInningsId(widget.inningsId);
      if (currentScore == null) {
        // ── FIX 1: pass tournamentId + matchId derived from currentInnings ──
        currentScore = Score.create(
          widget.inningsId,
          tournamentId: currentInnings!.tournamentId,
          matchId: currentInnings!.matchId,
          createdBy: currentMatch!.createdBy,
        );
      }

      strikeBatsman = Batsman.getByBatId(widget.strikeBatsmanId);
      nonStrikeBatsman = Batsman.getByBatId(widget.nonStrikeBatsmanId);
      currentBowler = Bowler.getByBowlerId(widget.bowlerId);

      if (currentScore != null) {
        currentScore!.strikeBatsmanId = widget.strikeBatsmanId;
        currentScore!.nonStrikeBatsmanId = widget.nonStrikeBatsmanId;
        currentScore!.currentBowlerId = widget.bowlerId;
        currentScore!.save();
      }

      // 🔥 FIX: Always ensure a MatchHistory entry exists from the very start
      // so closing the app mid-match always shows up in history
      final existingHistory = MatchHistory.getByMatchId(widget.matchId);
      if (existingHistory == null) {
        MatchHistory.create(
          matchId: widget.matchId,
          teamAId: currentMatch!.teamId1,
          teamBId: currentMatch!.teamId2,
          matchDate: DateTime.now(),
          matchType: 'CRICKET',
          team1Runs: 0,
          team1Wickets: 0,
          team1Overs: 0.0,
          team2Runs: 0,
          team2Wickets: 0,
          team2Overs: 0.0,
          result: 'Match Interrupted',
          isCompleted: false,
          isPaused: false,
          isOnProgress: true,
          matchStartTime: DateTime.now(),
          createdBy: currentMatch!.createdBy, // ← ADD THIS
          tournamentId: currentMatch!.tournamentId, // ← ADD THIS
        );
      } else {
        existingHistory.updateStatus(
          // ← USE updateStatus instead of manual fields
          isOnProgress: true,
          isPaused: false,
        );
        existingHistory.result = 'Match Interrupted';
        if (existingHistory.matchStartTime == null) {
          existingHistory.matchStartTime = DateTime.now();
        }
        existingHistory.save();
      }
      // NOTE: Do NOT reset isPaused here for resumed matches.
      // The match stays isPaused=true while in progress.
      // Only _updateMatchToHistory() and _updateMatchTiedToHistory() set isPaused=false (on completion).

      setState(() => isInitializing = false);
      await Future.delayed(const Duration(milliseconds: 100));

      final isSecond = currentInnings!.isSecondInnings;

      await _waitForBluetoothConnection();

      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('🧹 Clearing display before drawing layout (triple clear)...');
      final bleService = BleManagerService();

      if (bleService.isConnected) {
        debugPrint('🧹 CLEAR 1/3');
        await bleService.sendRawCommands(['CLEAR']);
        await Future.delayed(const Duration(milliseconds: 200));

        debugPrint('🧹 CLEAR 2/3');
        await bleService.sendRawCommands(['CLEAR']);
        await Future.delayed(const Duration(milliseconds: 200));

        debugPrint('🧹 CLEAR 3/3');
        await bleService.sendRawCommands(['CLEAR']);
        await Future.delayed(const Duration(milliseconds: 200));

        debugPrint('✅ Display cleared and stabilized - ready to draw');
      } else {
        debugPrint('⚠️ BLE not connected - skipping clear');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('🎨 Starting layout render...');
      if (isSecond) {
        await _sendSecondInningsIntroLayout();
      } else {
        await _sendFullLEDLayout();
      }
    } catch (e) {
      print('Error initializing match: $e');
      _showErrorDialog('Failed to load match: $e');
    }
  }
  String? _tournamentMatchDocIdCache;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveTournamentMatchDoc(
    String tournamentId,
  ) async {
    if (tournamentId.isEmpty) return null;

    final matchesCol = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches');

    if (_tournamentMatchDocIdCache != null) {
      final cachedSnap =
          await matchesCol.doc(_tournamentMatchDocIdCache).get();
      if (cachedSnap.exists) return cachedSnap;
      _tournamentMatchDocIdCache = null;
    }

    if (widget.tournamentMatchDocId != null &&
        widget.tournamentMatchDocId!.isNotEmpty) {
      final directSnap =
          await matchesCol.doc(widget.tournamentMatchDocId).get();
      if (directSnap.exists) {
        _tournamentMatchDocIdCache = directSnap.id;
        return directSnap;
      }
      debugPrint(
        '⚠️ tournamentMatchDocId ${widget.tournamentMatchDocId} not found, '
        'falling back to scorerMatchId query',
      );
    }

    final query = await matchesCol
        .where('scorerMatchId', isEqualTo: widget.matchId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      _tournamentMatchDocIdCache = query.docs.first.id;
      return query.docs.first;
    }

    debugPrint(
      '⚠️ Could not resolve tournament match doc for matchId=${widget.matchId} '
      '(tournamentMatchDocId=${widget.tournamentMatchDocId})',
    );
    return null;
  }

 Future<void> _syncLiveScoreToFirestore() async {
  if (isMatchComplete) return; // ← ADD THIS LINE
  try {
    if (currentInnings == null || currentScore == null) return;
      final tournamentId = currentInnings!.tournamentId;
      if (tournamentId.isEmpty) return;

      // Find the tournament match doc
     // Find the tournament match doc
      final matchSnap = await _resolveTournamentMatchDoc(tournamentId);
      if (matchSnap == null) return;

      final matchDocId = matchSnap.id;
      final inningsNumber = currentInnings!.isSecondInnings ? 2 : 1;
      final inningsDocId = 'innings_$inningsNumber';

      // Write innings summary
   // Write innings summary
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchDocId)
          .collection('innings')
          .doc(inningsDocId)
          .set({
            'inningsNumber': inningsNumber,
            'isSecondInnings': currentInnings!.isSecondInnings,   // ← NEW LINE
            'battingTeamId': currentInnings!.battingTeamId,
            'battingTeamName':
                _battingTeamNameCache ??
                Team.getById(currentInnings!.battingTeamId)?.teamName ??
                '',
            'bowlingTeamId': currentInnings!.bowlingTeamId,
            'totalRuns': currentScore!.totalRuns,
            'wickets': currentScore!.wickets,
            'ballsBowled': currentScore!.currentBall,
            'overs': currentScore!.overs,
            'extras': currentScore!.totalExtras,
            'targetRuns': currentInnings!.isSecondInnings
                ? currentInnings!.targetRuns
                : null,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      // Write current batsmen
      if (strikeBatsman != null) {
        final strikerPlayer = TeamMember.getByPlayerId(strikeBatsman!.playerId);
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(matchDocId)
            .collection('innings')
            .doc(inningsDocId)
            .collection('batsmen')
            .doc(strikeBatsman!.batId)
            .set({
              'playerId': strikeBatsman!.playerId,
              'playerName':
                  strikerPlayer?.playerName ?? strikerPlayer?.teamName ?? '',
              'runs': strikeBatsman!.runs,
              'ballsFaced': strikeBatsman!.ballsFaced,
              'fours': strikeBatsman!.fours,
              'sixes': strikeBatsman!.sixes,
              'isStriker': true,
              'isOut': strikeBatsman!.isOut,
              'dismissalType': strikeBatsman!.dismissalType ?? '',
            }, SetOptions(merge: true));
      }

      if (nonStrikeBatsman != null) {
        final nonStrikerPlayer = TeamMember.getByPlayerId(
          nonStrikeBatsman!.playerId,
        );
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(matchDocId)
            .collection('innings')
            .doc(inningsDocId)
            .collection('batsmen')
            .doc(nonStrikeBatsman!.batId)
            .set({
              'playerId': nonStrikeBatsman!.playerId,
              'playerName':
                  nonStrikerPlayer?.playerName ??
                  nonStrikerPlayer?.teamName ??
                  '',
              'runs': nonStrikeBatsman!.runs,
              'ballsFaced': nonStrikeBatsman!.ballsFaced,
              'fours': nonStrikeBatsman!.fours,
              'sixes': nonStrikeBatsman!.sixes,
              'isStriker': false,
              'isOut': nonStrikeBatsman!.isOut,
              'dismissalType': nonStrikeBatsman!.dismissalType ?? '',
            }, SetOptions(merge: true));
      }

      // Write current bowler
      if (currentBowler != null) {
        final bowlerPlayer = TeamMember.getByPlayerId(currentBowler!.playerId);
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .doc(matchDocId)
            .collection('innings')
            .doc(inningsDocId)
            .collection('bowlers')
            .doc(currentBowler!.bowlerId)
            .set({
              'playerId': currentBowler!.playerId,
              'playerName':
                  bowlerPlayer?.playerName ?? bowlerPlayer?.teamName ?? '',
              'wickets': currentBowler!.wickets,
              'runsConceded': currentBowler!.runsConceded,
              'balls': currentBowler!.balls,
              'overs': currentBowler!.overs,
              'maidens': currentBowler!.maidens,
              'economy': currentBowler!.economy,
            }, SetOptions(merge: true));
      }

      debugPrint('✅ Live score synced to Firestore');
    } catch (e) {
      debugPrint('⚠️ Live score sync failed (non-critical): $e');
    }
  }

  // 🔥 NEW: Helper method to wait for Bluetooth connection
  Future<void> _waitForBluetoothConnection() async {
    final bleService = BleManagerService();

    // Wait up to 5 seconds for connection
    int attempts = 0;
    const maxAttempts = 50; // 50 * 100ms = 5 seconds

    while (!bleService.isConnected && attempts < maxAttempts) {
      debugPrint(
        '⏳ Waiting for Bluetooth connection... (${attempts + 1}/$maxAttempts)',
      );
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!bleService.isConnected) {
      debugPrint(
        '⚠️ Bluetooth connection timeout - proceeding without LED display',
      );
    } else {
      debugPrint('✅ Bluetooth connected - ready to send commands');
    }
  }

  String _getBattingTeamName() {
    if (currentInnings == null) return 'Unknown';
    final team = Team.getById(currentInnings!.battingTeamId);
    if (team != null) return team.teamName;
    // Fallback: resolve from cached innings name if available
    return _battingTeamNameCache ?? 'Unknown';
  }

  void _showErrorDialog(String message) async {
    // Clear display immediately on any fatal error
    await _clearLEDDisplay();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF9AA0A6)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF6D7CFF))),
          ),
        ],
      ),
    );
  }

  bool _checkSecondInningsVictory() {
    if (currentInnings == null || !currentInnings!.isSecondInnings)
      return false;

    if (currentInnings!.hasValidTarget && currentScore != null) {
      try {
        // 🔥 FIX: Check if target is met or exceeded
        if (currentScore!.totalRuns >= currentInnings!.targetRuns) {
          final firstInnings = Innings.getFirstInnings(widget.matchId);
          if (firstInnings != null) {
            final firstInningsScore = Score.getByInningsId(
              firstInnings.inningsId,
            );
            if (firstInningsScore != null) {
              // Team B won - pass TRUE for battingTeamWon
              _showVictoryDialog(true, firstInningsScore);
              return true;
            }
          }
        }
      } catch (e) {
        print('Error checking victory: $e');
      }
    }
    return false;
  }

  /// Called once when CricketScorerScreen first loads.
  /// Clears the display and redraws the complete static + dynamic layout.
  Future<void> _sendFullLEDLayout() async {
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping full LED layout.');
        return;
      }

      if (strikeBatsman == null ||
          nonStrikeBatsman == null ||
          currentBowler == null ||
          currentScore == null ||
          currentInnings == null) {
        debugPrint('⚠️ Null data — skipping full LED layout.');
        return;
      }

      debugPrint('🖥️ Drawing full LED layout...');

      // ── PREPARE ALL DATA ─────────────────────────────────────────
      final battingTeam = Team.getById(currentInnings!.battingTeamId);
      final bowlingTeam = Team.getById(currentInnings!.bowlingTeamId);
      final strikerPlayer = TeamMember.getByPlayerId(strikeBatsman!.playerId);
      final nonStrikerPlayer = TeamMember.getByPlayerId(
        nonStrikeBatsman!.playerId,
      );
      final bowlerPlayer = TeamMember.getByPlayerId(currentBowler!.playerId);

      _row74PlayerId = strikeBatsman!.playerId;

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final temp = (_envService.currentTemperature ?? 27).round();

      String trunc(String? name, int max) {
        final n = name ?? '';
        return (n.length > max ? n.substring(0, max) : n).toUpperCase();
      }

      final battingName = trunc(battingTeam?.teamName, 6);
      final bowlingName = trunc(bowlingTeam?.teamName, 6);
      final strikerName = trunc(strikerPlayer?.teamName, 7);
      final nonStrikerName = trunc(nonStrikerPlayer?.teamName, 7);
      final bowlerName = trunc(bowlerPlayer?.teamName, 7);

      final runs = currentScore!.totalRuns.toString();
      final wickets = currentScore!.wickets.toString();
      final overs = currentScore!.overs.toStringAsFixed(1);
      final crr = currentScore!.crr.toStringAsFixed(2);
      final strikerRuns = strikeBatsman!.runs.toString();
      final strikerBalls = strikeBatsman!.ballsFaced.toString();
      final nsBatsRuns = nonStrikeBatsman!.runs.toString();
      final nsBatsBalls = nonStrikeBatsman!.ballsFaced.toString();
      final bowlerWkts = currentBowler!.wickets.toString();
      final bowlerRuns = currentBowler!.runsConceded.toString();
      final bowlerOvers = currentBowler!.overs.toStringAsFixed(1);

      const int delayPerCommand = 100;

      // ── ROW 1 (y=2): Header — time + org + temp ──────────────────────────
      await bleService.sendRawCommands(['TEXT 3 2 1 255 255 200 $timeStr']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands(['TEXT 36 2 1 200 200 255 AEROBIOSYS']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      final int tempNumWidth = temp.toString().length * 6;
      final int degreeX = 102 + tempNumWidth;
      final int cLetterX = degreeX + 4;

      await bleService.sendRawCommands(['TEXT 102 2 1 200 255 200 $temp']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'SHAPE RECT $degreeX 2 2 2 200 255 200 200 255 200',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands(['TEXT $cLetterX 2 1 200 255 200 C']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 2 (y=12): Divider ───────────────────────────────────────────
      await bleService.sendRawCommands(['LINE H 0 12 127 12 1 255 255 255']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 2 (y=17): Team names ─────────────────────────────────────────
      final int batW = battingName.length * 6;
      final int bowlW = bowlingName.length * 6;
      final int batX = (28 - (batW ~/ 2)).clamp(3, 54 - batW);
      const int vsX = 57;
      final int bowlX = (98 - (bowlW ~/ 2)).clamp(72, 124 - bowlW);

      await bleService.sendRawCommands([
        'TEXT $batX 17 1 0 255 255 $battingName',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands(['TEXT $vsX 17 1 255 255 255 VS']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT $bowlX 17 1 255 100 100 $bowlingName',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 3 (y=30): Score ──────────────────────────────────────────────
      const int scrLabelX = 10; // SCR: starts at x=3
      const int slashX = 100;
      const int wicketsX = 112;

      // SCR: at scale 2 = 4 chars × 12px = 48px wide → ends at x=51
      // So runs must start at x=52 minimum
      final int dynamicRunsX = (78 - (runs.length * 10) ~/ 2).clamp(52, 90);

      await bleService.sendRawCommands(['TEXT $scrLabelX 30 2 255 0 255 SCR:']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT $dynamicRunsX 30 2 255 255 255 $runs',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands(['TEXT $slashX 30 2 255 100 100 /']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT $wicketsX 30 2 255 255 255 $wickets',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 4 (y=50): CRR + Overs ────────────────────────────────────────
      await bleService.sendRawCommands([
        'TEXT 5 50 1 255 255 0 CRR:',
        'TEXT 29 50 1 255 255 0 $crr',
        'TEXT 66 50 1 0 255 0 OVR:',
        'TEXT 90 50 1 0 255 0 $overs(${currentMatch!.overs})',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 5 (y=60): Bowler ─────────────────────────────────────────────
      final paddedBowlerNameInit = bowlerName.padRight(7).substring(0, 7);
      await bleService.sendRawCommands([
        'TEXT 10 60 1 255 200 200 $paddedBowlerNameInit',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT 58  60 1 0 255 0 $bowlerWkts',
        'TEXT 66  60 1 0 255 0 /',
        'TEXT 74  60 1 0 255 0 $bowlerRuns',
        'TEXT 94  60 1 0 255 0 (',
        'TEXT 102 60 1 0 255 0 $bowlerOvers',
        'TEXT 122 60 1 0 255 0 )',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 6 (y=70): Divider ───────────────────────────────────────────
      await bleService.sendRawCommands(['LINE H 0 70 127 70 1 255 255 255']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // ── ROW 7 (y=74): Striker ───────────────────────────────────────────
      await bleService.sendRawCommands(['TEXT 2 74 1 255 0 0 *']);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT 8 74 1 200 255 255 $strikerName',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT 58 74 1 200 255 200 $strikerRuns($strikerBalls)',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      // 🔥 RECORD which player is at row 74 — this never changes
      _row74PlayerId = strikeBatsman!.playerId;

      // ── ROW 8 (y=84): Non-striker ───────────────────────────────────────
      await bleService.sendRawCommands([
        'TEXT 8 84 1 200 200 255 $nonStrikerName',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      await bleService.sendRawCommands([
        'TEXT 58 84 1 200 255 200 $nsBatsRuns($nsBatsBalls)',
      ]);
      await Future.delayed(Duration(milliseconds: delayPerCommand));

      debugPrint('✅ Full LED layout drawn with split bowler stats');

      // 🔥 START PERIODIC TIME/TEMP UPDATE ONLY AFTER LAYOUT IS COMPLETELY READY
      if (_ledUpdateTimer == null || !_ledUpdateTimer!.isActive) {
        await Future.delayed(const Duration(seconds: 1));

        _ledUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
          debugPrint('⏰ CricketScorerScreen: Periodic LED update triggered');
          _updateLEDTimeAndTemp();
        });
        debugPrint('🔄 Started periodic time/temp updates (60s interval)');
      }
    } catch (e) {
      debugPrint('❌ _sendFullLEDLayout failed: $e');
    }
  }

  /// Called only when second innings loads.
  /// Shows a 3-second first innings summary screen, then draws the
  /// second innings layout row-by-row from top to bottom at 150ms per row.
  /// Called only when second innings loads.
  /// Shows a 3-second first innings summary screen, then draws the
  /// second innings layout row-by-row from top to bottom at 150ms per row.
  Future<void> _updateMatchTiedToHistory(Score firstInningsScore) async {
  if (currentMatch == null || currentInnings == null || currentScore == null) return;

  final firstInnings = Innings.getFirstInnings(widget.matchId);
  if (firstInnings == null) return;

  final existingHistory = MatchHistory.getByMatchId(widget.matchId);

  if (existingHistory != null) {
    existingHistory.isCompleted   = true;
    existingHistory.isPaused      = false;
    existingHistory.isOnProgress  = false;
    existingHistory.pausedState   = null;
    existingHistory.result        = 'Match Tied';
    existingHistory.team1Runs     = firstInningsScore.totalRuns;
    existingHistory.team1Wickets  = firstInningsScore.wickets;
    existingHistory.team1Overs    = firstInningsScore.overs;
    existingHistory.team2Runs     = currentScore!.totalRuns;
    existingHistory.team2Wickets  = currentScore!.wickets;
    existingHistory.team2Overs    = currentScore!.overs;
    existingHistory.matchDate     = DateTime.now();
    existingHistory.matchEndTime  = DateTime.now();
    existingHistory.matchStartTime ??= DateTime.now();
    existingHistory.save();
    debugPrint('✅ tied history saved — isCompleted=${existingHistory.isCompleted}, result=${existingHistory.result}');
  } else {
    MatchHistory.create(
      matchId:        widget.matchId,
      teamAId:        firstInnings.battingTeamId,
      teamBId:        firstInnings.bowlingTeamId,
      matchDate:      DateTime.now(),
      matchType:      'CRICKET',
      team1Runs:      firstInningsScore.totalRuns,
      team1Wickets:   firstInningsScore.wickets,
      team1Overs:     firstInningsScore.overs,
      team2Runs:      currentScore!.totalRuns,
      team2Wickets:   currentScore!.wickets,
      team2Overs:     currentScore!.overs,
      result:         'Match Tied',
      isCompleted:    true,
      isPaused:       false,
      isOnProgress:   false,
      matchStartTime: DateTime.now(),
      matchEndTime:   DateTime.now(),
      createdBy:      currentMatch!.createdBy,
      tournamentId:   currentMatch!.tournamentId,
    );
    debugPrint('✅ new tied history created');
  }

  await _updateTournamentMatchResult(
    result: 'Match Tied',
    battingTeamWon: false,
    firstInningsScore: firstInningsScore,
  );
}
  Future<void> _updateTournamentMatchResult({
  required String result,
  required bool battingTeamWon,
  required Score firstInningsScore,
}) async {
  try {
    if (currentInnings == null) return;

    final tournamentId = currentInnings!.tournamentId;
    if (tournamentId.isEmpty) return;
final matchDoc = await _resolveTournamentMatchDoc(tournamentId);
    if (matchDoc == null) {
      debugPrint(
        '❌ Could not find tournament match doc to mark completed '
        '(matchId=${widget.matchId}). Result was: $result',
      );
      return;
    }
    final data = matchDoc.data() ?? {};

    final t1Id = (data['teamId1'] as String?) ?? '';
    final t2Id = (data['teamId2'] as String?) ?? '';
    final t1Name = (data['teamId1Name'] as String?) ?? '';
    final t2Name = (data['teamId2Name'] as String?) ?? '';

    // ── Determine winner ──────────────────────────────────────────────
    String winnerId = '';
    String winnerName = '';

    if (result != 'Match Tied') {
      final firstInnings = Innings.getFirstInnings(widget.matchId);
      if (firstInnings != null) {
        if (battingTeamWon) {
          // Second innings batting team won
          winnerId = currentInnings!.battingTeamId;
          // Resolve display name from match doc fields
          winnerName = (winnerId == t1Id)
              ? t1Name
              : (winnerId == t2Id)
                  ? t2Name
                  : (_battingTeamNameCache ?? Team.getById(winnerId)?.teamName ?? '');
        } else {
          // First innings batting team won
          winnerId = firstInnings.battingTeamId;
          winnerName = (winnerId == t1Id)
              ? t1Name
              : (winnerId == t2Id)
                  ? t2Name
                  : (_bowlingTeamNameCache ?? Team.getById(winnerId)?.teamName ?? '');
        }
      }
    }

    // ── Update current match doc as completed ─────────────────────────
    final updateData = <String, dynamic>{
      'isCompleted': true,
      'status': 'completed',
      'result': result,
      'winnerId': winnerId.isNotEmpty ? winnerId : null,
      'winnerName': winnerName.isNotEmpty ? winnerName : null,
      'team1Score': firstInningsScore.totalRuns,
      'team1Wickets': firstInningsScore.wickets,
      'team1Overs': firstInningsScore.overs,
      'team2Score': currentScore!.totalRuns,
      'team2Wickets': currentScore!.wickets,
      'team2Overs': currentScore!.overs,
    };

    await matchDoc.reference.update(updateData);
    debugPrint('✅ Current match doc updated: $result | winner: $winnerName ($winnerId)');

    // ── Advance winner to next match if knockout ──────────────────────
    final nextMatchId = (data['nextMatchId'] as String?) ?? '';
    final nextMatchSlot = (data['nextMatchSlot'] as int?) ?? 1;

    if (nextMatchId.isNotEmpty && winnerId.isNotEmpty) {
      final nextRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(nextMatchId);

      final nextSnap = await nextRef.get();
      if (!nextSnap.exists) {
        debugPrint('⚠️ Next match doc $nextMatchId does not exist yet');
        return;
      }

      final nextData = nextSnap.data() ?? {};

      // Build slot-specific update
      final Map<String, dynamic> slotUpdate;
      if (nextMatchSlot == 1) {
        slotUpdate = {
          'teamId1': winnerId,
          'teamId1Name': winnerName,
        };
      } else {
        slotUpdate = {
          'teamId2': winnerId,
          'teamId2Name': winnerName,
        };
      }

      // ── Auto-schedule next match if BOTH slots are now filled ────────
      final String otherTeamId;
      final String otherTeamName;
      if (nextMatchSlot == 1) {
        otherTeamId = (nextData['teamId2'] as String?) ?? '';
        otherTeamName = (nextData['teamId2Name'] as String?) ?? '';
      } else {
        otherTeamId = (nextData['teamId1'] as String?) ?? '';
        otherTeamName = (nextData['teamId1Name'] as String?) ?? '';
      }

      final bool bothSlotsFilled =
          otherTeamId.isNotEmpty && otherTeamId != 'TBD';

      if (bothSlotsFilled) {
        // Both teams known — mark next match as scheduled and ready
        slotUpdate['status'] = 'scheduled';
        slotUpdate['waitingForTeams'] = false;
        debugPrint(
          '✅ Both slots filled for next match $nextMatchId — marking scheduled. '
          'Slot1: ${nextMatchSlot == 1 ? winnerId : otherTeamId} | '
          'Slot2: ${nextMatchSlot == 2 ? winnerId : otherTeamId}',
        );
      } else {
        // Still waiting for the other team
        slotUpdate['waitingForTeams'] = true;
        debugPrint(
          '⏳ Next match $nextMatchId still waiting for other team. '
          'Filled slot $nextMatchSlot with $winnerName',
        );
      }

      await nextRef.update(slotUpdate);
      debugPrint('✅ Next match $nextMatchId slot $nextMatchSlot updated with winner: $winnerName');
    }

    debugPrint('✅ Tournament match result fully updated: $result');
  } catch (e) {
    debugPrint('❌ Failed to update tournament match result: $e');
  }
}

  void _autoSaveMatchState() {
    try {
      if (currentMatch == null ||
          currentInnings == null ||
          currentScore == null) {
        debugPrint('⚠️ Auto-save skipped: match data not available');
        return;
      }

      final firstInnings = Innings.getFirstInnings(widget.matchId);
      final secondInnings = Innings.getSecondInnings(widget.matchId);
      final firstScore = firstInnings != null
          ? Score.getByInningsId(firstInnings.inningsId)
          : null;
      final secondScore = secondInnings != null
          ? Score.getByInningsId(secondInnings.inningsId)
          : null;

      // 🔥 FIX: Use widget IDs as reliable fallback (score IDs may be empty on first ball)
      final String strikerId = currentScore!.strikeBatsmanId.isNotEmpty
          ? currentScore!.strikeBatsmanId
          : widget.strikeBatsmanId;
      final String nonStrikerId = currentScore!.nonStrikeBatsmanId.isNotEmpty
          ? currentScore!.nonStrikeBatsmanId
          : widget.nonStrikeBatsmanId;
      final String bowlerIdStr = currentScore!.currentBowlerId.isNotEmpty
          ? currentScore!.currentBowlerId
          : widget.bowlerId;

      final matchStateJson = jsonEncode({
        'matchId': widget.matchId,
        'inningsId': widget.inningsId,
        'strikeBatsmanId': strikerId,
        'nonStrikeBatsmanId': nonStrikerId,
        'bowlerId': bowlerIdStr,
        'firstInningsId': firstInnings?.inningsId,
        'firstInningsTeamId': firstInnings?.battingTeamId,
        'firstInningsRuns': firstScore?.totalRuns ?? 0,
        'firstInningsWickets': firstScore?.wickets ?? 0,
        'firstInningsOvers': firstScore?.overs ?? 0.0,
        'firstInningsExtras': firstScore?.totalExtras ?? 0,
        'secondInningsId': secondInnings?.inningsId,
        'secondInningsTeamId': secondInnings?.battingTeamId,
        'secondInningsRuns': secondScore?.totalRuns ?? 0,
        'secondInningsWickets': secondScore?.wickets ?? 0,
        'secondInningsOvers': secondScore?.overs ?? 0.0,
        'secondInningsExtras': secondScore?.totalExtras ?? 0,
        'secondInningsTarget': secondInnings?.targetRuns ?? 0,
        'isCompleted': false,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final existingHistory = MatchHistory.getByMatchId(widget.matchId);

      if (existingHistory != null) {
        existingHistory.updateStatus(
          // ← single call, persists to Firestore
          isPaused: false,
          isOnProgress: true,
          isCompleted: false,
          pausedState: matchStateJson,
          matchEndTime: DateTime.now(),
        );
        existingHistory.result = 'Match Interrupted';
        existingHistory.team1Runs =
            firstScore?.totalRuns ?? existingHistory.team1Runs;
        existingHistory.team1Wickets =
            firstScore?.wickets ?? existingHistory.team1Wickets;
        existingHistory.team1Overs =
            firstScore?.overs ?? existingHistory.team1Overs;
        existingHistory.team2Runs =
            secondScore?.totalRuns ?? existingHistory.team2Runs;
        existingHistory.team2Wickets =
            secondScore?.wickets ?? existingHistory.team2Wickets;
        existingHistory.team2Overs =
            secondScore?.overs ?? existingHistory.team2Overs;
        existingHistory.matchDate = DateTime.now();
        existingHistory.save();
        // 🔥 FIX: Verify save actually persisted
        final verify = MatchHistory.getByMatchId(widget.matchId);
        debugPrint(
          '✅ Auto-save verified — isPaused=${verify?.isPaused}, result=${verify?.result}, pausedState length=${verify?.pausedState?.length ?? 0}',
        );
      } else {
        final DateTime startTime = DateTime.now();
    MatchHistory.create(
  matchId: widget.matchId,
  teamAId: currentMatch!.teamId1,
  teamBId: currentMatch!.teamId2,
  matchDate: DateTime.now(),
  matchType: 'CRICKET',
  team1Runs: firstScore?.totalRuns ?? 0,
  team1Wickets: firstScore?.wickets ?? 0,
  team1Overs: firstScore?.overs ?? 0.0,
  team2Runs: secondScore?.totalRuns ?? 0,
  team2Wickets: secondScore?.wickets ?? 0,
  team2Overs: secondScore?.overs ?? 0.0,
  result: 'Match Interrupted',
  isCompleted: false,
  isPaused: false,
  isOnProgress: true,
  pausedState: matchStateJson,
  matchStartTime: startTime,
  createdBy: currentMatch!.createdBy,       // ✅ INSIDE create()
  tournamentId: currentMatch!.tournamentId, // ✅ INSIDE create()
);
        // 🔥 FIX: Verify new entry was created
        final verify = MatchHistory.getByMatchId(widget.matchId);
        debugPrint(
          '✅ Auto-save created new entry — id=${verify?.id}, isPaused=${verify?.isPaused}',
        );
      }

      debugPrint(
        '✅ Match auto-saved as paused. strikerId=$strikerId, bowler=$bowlerIdStr',
      );
    } catch (e) {
      debugPrint('❌ Auto-save failed: $e');
    }
  }

  Future<void> _showContinueMatchDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1C1F24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF6D7CFF), width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.sports_cricket, color: Color(0xFF6D7CFF), size: 28),
              SizedBox(width: 12),
              Text(
                'Ready for Innings 2?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0f0f1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6D7CFF), width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 First innings summary is displayed on the LED',
                      style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🏏 Click "Continue Match" when ready to start second innings',
                      style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D7CFF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog and continue
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Continue Match',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
     ),
        );
      },
    );
  }

  Future<void> _sendSecondInningsIntroLayout() async {
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint(
          '⚠️ Bluetooth not connected. Skipping second innings intro.',
        );
        return;
      }

      if (strikeBatsman == null ||
          nonStrikeBatsman == null ||
          currentBowler == null ||
          currentScore == null ||
          currentInnings == null) {
        debugPrint('⚠️ Null data — skipping second innings intro.');
        return;
      }

      // Helper function to center text
      int centerX(String text, int scale) {
        const int displayWidth = 128;
        final int textWidth = text.length * 6 * scale;
        return ((displayWidth - textWidth) / 2).round().clamp(
          0,
          displayWidth - 1,
        );
      }

      // ── PHASE 1: SHOW FIRST INNINGS SUMMARY ──────────────────
      final firstInnings = Innings.getFirstInnings(widget.matchId);
      final firstScore = firstInnings != null
          ? Score.getByInningsId(firstInnings.inningsId)
          : null;
      final firstBattingTeam = firstInnings != null
          ? Team.getById(firstInnings.battingTeamId)
          : null;

      final targetRuns = currentInnings!.targetRuns.toString();
      final inns1Runs = firstScore?.totalRuns.toString() ?? '0';
      final inns1Wickets = firstScore?.wickets.toString() ?? '0';
      final inns1Overs = firstScore?.overs.toStringAsFixed(1) ?? '0.0';

      String trunc(String? name, int max) {
        final n = name ?? '';
        return (n.length > max ? n.substring(0, max) : n).toUpperCase();
      }

      final firstTeamName = trunc(firstBattingTeam?.teamName, 8);

      debugPrint('📺 Showing 1st innings summary...');

      // Draw innings 1 summary
      final headerText = 'INNINGS 1 SUMMARY';
      final headerX = centerX(headerText, 1);
      await bleService.sendRawCommands([
        'TEXT $headerX 2 1 255 200 0 $headerText',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands(['LINE H 0 12 127 12 1 255 200 0']);
      await Future.delayed(const Duration(milliseconds: 250));

      const String battingLabel = 'BATTING:';
      final int battingW = battingLabel.length * 6;
      final int teamW = firstTeamName.length * 6;
      const int gap = 6;
      final int totalW = battingW + gap + teamW;
      final int groupX = ((128 - totalW) / 2).round().clamp(0, 127);
      final int teamX = groupX + battingW + gap;

      await bleService.sendRawCommands([
        'TEXT $groupX 20 1 0 255 255 $battingLabel',
        'TEXT $teamX 20 1 255 255 255 $firstTeamName',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands([
        'TEXT 10 32 2 255 0 255 SCR:',
        'TEXT 58 32 2 255 255 255 $inns1Runs',
        'TEXT 88 32 2 255 100 100 /',
        'TEXT 100 32 2 255 255 255 $inns1Wickets',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      const String oversLabel = 'OVERS:';
      final int oversLabelW = oversLabel.length * 6;
      final int oversValW = inns1Overs.length * 6;
      const int oversGap = 6;
      final int oversTotalW = oversLabelW + oversGap + oversValW;
      final int oversGroupX = ((128 - oversTotalW) / 2).round().clamp(0, 127);
      final int oversValX = oversGroupX + oversLabelW + oversGap;

      await bleService.sendRawCommands([
        'TEXT $oversGroupX 52 1 0 255 255 $oversLabel',
        'TEXT $oversValX 52 1 255 255 255 $inns1Overs',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      const String targetLabel = 'TARGET:';
      final int targetLabelW =
          targetLabel.length * 12; // ← was * 6, scale 2 = 12px per char
      final int targetNumW = targetRuns.length * 12;
      const int targetGap = 8;
      final int targetTotalW = targetLabelW + targetGap + targetNumW;
      final int targetGroupX = ((128 - targetTotalW) / 2).round().clamp(0, 127);
      final int targetNumX = targetGroupX + targetLabelW + targetGap;

      await bleService.sendRawCommands([
        'LINE H 0 62 127 62 1 255 200 0',
        'TEXT $targetGroupX 68 2 255 200 0 $targetLabel',
        'TEXT $targetNumX 68 2 255 255 0 $targetRuns',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      const String waitingText = 'WAITING TO START...';
      final int waitingX = centerX(waitingText, 1);
      await bleService.sendRawCommands([
        'TEXT $waitingX 84 1 0 255 0 $waitingText',
      ]);

      debugPrint(
        '✅ 1st innings summary shown. Waiting for user confirmation...',
      );

      // ── PHASE 2: SHOW MODAL AND WAIT FOR USER CONFIRMATION ──────────────────
      await _showContinueMatchDialog();

      // ── PHASE 3: CLEAR + DRAW SECOND INNINGS LAYOUT ──────────────────────
      debugPrint('🖥️ Clearing and drawing 2nd innings layout...');

      await bleService.sendRawCommands(['CLEAR']);
      await Future.delayed(const Duration(milliseconds: 400));

      // Prepare second innings data
      final battingTeam = Team.getById(currentInnings!.battingTeamId);
      final bowlingTeam = Team.getById(currentInnings!.bowlingTeamId);
      final strikerPlayer = TeamMember.getByPlayerId(strikeBatsman!.playerId);
      final nonStrikerPlayer = TeamMember.getByPlayerId(
        nonStrikeBatsman!.playerId,
      );
      final bowlerPlayer = TeamMember.getByPlayerId(currentBowler!.playerId);

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final temp = (_envService.currentTemperature ?? 27).round();

      final battingName = trunc(battingTeam?.teamName, 6);
      final bowlingName = trunc(bowlingTeam?.teamName, 6);
      final strikerName = trunc(strikerPlayer?.teamName, 7);
      final nonStrikerName = trunc(nonStrikerPlayer?.teamName, 7);
      final bowlerName = trunc(bowlerPlayer?.teamName, 7);

      final runs = currentScore!.totalRuns.toString();
      final wickets = currentScore!.wickets.toString();
      final overs = currentScore!.overs.toStringAsFixed(1);
      final crr = currentScore!.crr.toStringAsFixed(2);
      final strikerRuns = strikeBatsman!.runs.toString();
      final strikerBalls = strikeBatsman!.ballsFaced.toString();
      final nsBatsRuns = nonStrikeBatsman!.runs.toString();
      final nsBatsBalls = nonStrikeBatsman!.ballsFaced.toString();
      final bowlerWkts = currentBowler!.wickets.toString();
      final bowlerRuns = currentBowler!.runsConceded.toString();
      final bowlerOvers = currentBowler!.overs.toStringAsFixed(1);

      // Draw layout with proper delays between command batches
      final int tempNumWidth2 = temp.toString().length * 6;
      final int degreeX2 = 102 + tempNumWidth2;
      final int cLetterX2 = degreeX2 + 4;

      await bleService.sendRawCommands(['TEXT 3 2 1 255 255 200 $timeStr']);
      await Future.delayed(const Duration(milliseconds: 100));

      await bleService.sendRawCommands(['TEXT 36 2 1 200 200 255 AEROBIOSYS']);
      await Future.delayed(const Duration(milliseconds: 100));

      await bleService.sendRawCommands(['TEXT 102 2 1 200 255 200 $temp']);
      await Future.delayed(const Duration(milliseconds: 100));

      await bleService.sendRawCommands([
        'SHAPE RECT $degreeX2 2 2 2 200 255 200 200 255 200',
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      await bleService.sendRawCommands(['TEXT $cLetterX2 2 1 200 255 200 C']);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands(['LINE H 0 12 127 12 1 255 255 255']);
      await Future.delayed(const Duration(milliseconds: 250));

      final int batW2 = battingName.length * 6;
      final int bowlW2 = bowlingName.length * 6;
      final int batX2 = (28 - (batW2 ~/ 2)).clamp(3, 54 - batW2);
      const int vsX2 = 57;
      final int bowlX2 = (98 - (bowlW2 ~/ 2)).clamp(72, 124 - bowlW2);

      await bleService.sendRawCommands([
        'TEXT $batX2 17 1 0 255 255 $battingName',
        'TEXT $vsX2 17 1 255 255 255 VS',
        'TEXT $bowlX2 17 1 255 100 100 $bowlingName',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      // Fix: same spacing logic
      const int scrLabelX2 = 10; // ← was 3, now matches first innings
      const int slashX2 = 100;
      const int wicketsX2 = 112;
      final int runsX2 = (78 - (runs.length * 10) ~/ 2).clamp(52, 90);

      await bleService.sendRawCommands([
        'TEXT $scrLabelX2 30 2 255 0 255 SCR:',
        'TEXT $runsX2 30 2 255 255 255 $runs',
        'TEXT $slashX2 30 2 255 100 100 /',
        'TEXT $wicketsX2 30 2 255 255 255 $wickets',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands([
        'TEXT 5 50 1 255 255 0 CRR:',
        'TEXT 29 50 1 255 255 0 $crr',
        'TEXT 66 50 1 0 255 0 OVR:',
        'TEXT 90 50 1 0 255 0 $overs(${currentMatch!.overs})',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      // Replace in _sendSecondInningsIntroLayout:
      final paddedBowlerName2 = bowlerName.padRight(7).substring(0, 7);
      await bleService.sendRawCommands([
        'TEXT 10  60 1 255 200 200 $paddedBowlerName2',
        'TEXT 58  60 1 0 255 0 $bowlerWkts',
        'TEXT 66  60 1 0 255 0 /',
        'TEXT 74  60 1 0 255 0 $bowlerRuns',
        'TEXT 94  60 1 0 255 0 (',
        'TEXT 102 60 1 0 255 0 $bowlerOvers',
        'TEXT 122 60 1 0 255 0 )',
      ]);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands([
        'LINE H 0 70 127 70 1 255 255 255',
        'TEXT 2 74 1 255 0 0 *',
        'TEXT 8 74 1 200 255 255 $strikerName',
        'TEXT 58 74 1 200 255 200 $strikerRuns($strikerBalls)',
        'TEXT 8 84 1 200 200 255 $nonStrikerName',
        'TEXT 58 84 1 200 255 200 $nsBatsRuns($nsBatsBalls)',
      ]);
      _row74PlayerId = strikeBatsman!.playerId;
      debugPrint('✅ Second innings LED layout drawn');

      // Start periodic time/temp update only after layout is complete
      if (_ledUpdateTimer == null || !_ledUpdateTimer!.isActive) {
        await Future.delayed(const Duration(seconds: 1));

        _ledUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
          debugPrint('⏰ CricketScorerScreen: Periodic LED update triggered');
          _updateLEDTimeAndTemp();
        });
        debugPrint(
          '🔄 Started periodic time/temp updates (60s interval) - LAYOUT FULLY COMPLETE',
        );
      }
    } catch (e) {
      debugPrint('❌ _sendSecondInningsIntroLayout failed: $e');
    }
  }

 void _showVictoryDialog(bool battingTeamWon, Score firstInningsScore) {
  currentInnings?.markCompleted();

  setState(() => isMatchComplete = true);

  _ledUpdateTimer?.cancel();
  _ledUpdateTimer = null;

  _triggerVictoryAnimation();

  Future(() async {
    // Step 1: Await full Firestore write before doing anything else
    await _updateMatchToHistory(battingTeamWon, firstInningsScore);

    final history = MatchHistory.getByMatchId(widget.matchId);
    debugPrint(
      '🔍 Post-write cache check — '
      'isCompleted=${history?.isCompleted}, '
      'isPaused=${history?.isPaused}, '
      'isOnProgress=${history?.isOnProgress}, '
      'result=${history?.result}',
    );

    // Step 2: LED cleanup
    int drainWait = 0;
    while (_ledQueueRunning && drainWait < 30) {
      await Future.delayed(const Duration(milliseconds: 50));
      drainWait++;
    }
    _ledQueue.clear();
    await _clearLEDDisplay();
    await Future.delayed(const Duration(milliseconds: 300));

    final h = MatchHistory.getByMatchId(widget.matchId);
    if (h != null && h.result.isNotEmpty) {
      await _showMatchSummaryOnLED(h.result);
    }

    // Step 3: Snackbar
    final victoryMessage =
        (history != null && history.result.isNotEmpty) ? history.result : 'Match Complete!';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            victoryMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    // Step 4: Wait then navigate
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final historyToSave = MatchHistory.getByMatchId(widget.matchId);
    if (historyToSave != null) {
      debugPrint('⏳ Awaiting Firestore confirm before navigation...');
      await historyToSave.persistAndAwait();
      debugPrint('✅ Firestore confirmed — isCompleted=${historyToSave.isCompleted}, result=${historyToSave.result}');
    }

    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.of(context).pop();

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
      (route) => false,
    ).then((_) async {
      MatchHistory.clearCache();
      await MatchHistory.loadFromFirestore();
      debugPrint('✅ History reloaded after navigation');
    });
  });
}
  Future<void> _showMatchSummaryOnLED(String resultText) async {
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping match stats display.');
        return;
      }

      debugPrint('🏆 Displaying match stats on LED...');

      // Helper to center text
      int centerX(String text, int scale) {
        const int displayWidth = 128;
        final int textWidth = text.length * 6 * scale;
        return ((displayWidth - textWidth) / 2).round().clamp(
          0,
          displayWidth - 1,
        );
      }

      // Draw "CONGRATS!" heading with scale 2
      const String heading = 'CONGRATS!';
      final int headingX = centerX(heading, 2);

      await bleService.sendRawCommands([
        'TEXT $headingX 10 2 255 200 0 $heading',
      ]);
      await Future.delayed(const Duration(milliseconds: 80));

      // Draw divider line
      await bleService.sendRawCommands(['LINE H 10 28 117 28 1 255 200 0']);
      await Future.delayed(const Duration(milliseconds: 80));

      // Split result text into multiple lines if needed (max 10 chars per line for scale 2)
      final words = resultText.toUpperCase().split(' ');
      List<String> lines = [];
      String currentLine = '';

      for (var word in words) {
        String testLine = currentLine.isEmpty ? word : '$currentLine $word';
        if (testLine.length <= 10) {
          currentLine = testLine;
        } else {
          if (currentLine.isNotEmpty) lines.add(currentLine);
          currentLine = word;
        }
      }
      if (currentLine.isNotEmpty) lines.add(currentLine);

      // Display result lines centered with scale 2
      int yPos = 38;
      for (var line in lines) {
        final int lineX = centerX(line, 2);
        await bleService.sendRawCommands(['TEXT $lineX $yPos 2 0 255 0 $line']);
        await Future.delayed(const Duration(milliseconds: 80));
        yPos += 18; // Increased spacing for scale 2 text (was 12)
      }

      debugPrint('✅ Match stats displayed on LED: $resultText');
    } catch (e) {
      debugPrint('❌ Failed to display match stats: $e');
    }
  }

  Future<void> _clearLEDDisplay() async {
    try {
      // Cancel ALL pending LED operations instantly
      _ledCancelled = true;
      _ledQueue.clear();

      // Wait for any currently executing command to finish (max 500ms)
      int drainWait = 0;
      while (_ledQueueRunning && drainWait < 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        drainWait++;
      }

      final bleService = BleManagerService();
      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping LED clear.');
        return;
      }

      debugPrint('🧹 Clearing LED display (triple clear)...');

      await bleService.sendRawCommands(['CLEAR']);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands(['CLEAR']);
      await Future.delayed(const Duration(milliseconds: 250));

      await bleService.sendRawCommands(['CLEAR']);
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('✅ LED display cleared');
    } catch (e) {
      debugPrint('❌ LED clear failed: $e');
    }
  }

  void _saveMatchState() {
    try {
      if (currentMatch == null ||
          currentInnings == null ||
          currentScore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Match data not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final firstInnings = Innings.getFirstInnings(widget.matchId);
      final secondInnings = Innings.getSecondInnings(widget.matchId);
      final firstScore = firstInnings != null
          ? Score.getByInningsId(firstInnings.inningsId)
          : null;
      final secondScore = secondInnings != null
          ? Score.getByInningsId(secondInnings.inningsId)
          : null;

      final String strikerId = currentScore!.strikeBatsmanId.isNotEmpty
          ? currentScore!.strikeBatsmanId
          : widget.strikeBatsmanId;
      final String nonStrikerId = currentScore!.nonStrikeBatsmanId.isNotEmpty
          ? currentScore!.nonStrikeBatsmanId
          : widget.nonStrikeBatsmanId;
      final String bowlerIdStr = currentScore!.currentBowlerId.isNotEmpty
          ? currentScore!.currentBowlerId
          : widget.bowlerId;

      final matchStateJson = jsonEncode({
        'matchId': widget.matchId,
        'inningsId': widget.inningsId,
        'strikeBatsmanId': strikerId,
        'nonStrikeBatsmanId': nonStrikerId,
        'bowlerId': bowlerIdStr,
        'firstInningsId': firstInnings?.inningsId,
        'firstInningsTeamId': firstInnings?.battingTeamId,
        'firstInningsRuns': firstScore?.totalRuns ?? 0,
        'firstInningsWickets': firstScore?.wickets ?? 0,
        'firstInningsOvers': firstScore?.overs ?? 0.0,
        'firstInningsExtras': firstScore?.totalExtras ?? 0,
        'secondInningsId': secondInnings?.inningsId,
        'secondInningsTeamId': secondInnings?.battingTeamId,
        'secondInningsRuns': secondScore?.totalRuns ?? 0,
        'secondInningsWickets': secondScore?.wickets ?? 0,
        'secondInningsOvers': secondScore?.overs ?? 0.0,
        'secondInningsExtras': secondScore?.totalExtras ?? 0,
        'secondInningsTarget': secondInnings?.targetRuns ?? 0,
        'isCompleted': false,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 🔥 Single safe upsert call — updates if exists, creates if not
      // Each matchId gets its own entry, so different matches never overwrite each other
      final existingForPause = MatchHistory.getByMatchId(widget.matchId);
      if (existingForPause != null) {
        existingForPause.updateStatus(
          // ← updateStatus handles Firestore write
          isPaused: true,
          isOnProgress: false,
          isCompleted: false,
          pausedState: matchStateJson,
          matchEndTime: DateTime.now(),
        );
        existingForPause.result = 'Match Paused';
        existingForPause.team1Runs =
            firstScore?.totalRuns ?? existingForPause.team1Runs;
        existingForPause.team1Wickets =
            firstScore?.wickets ?? existingForPause.team1Wickets;
        existingForPause.team1Overs =
            firstScore?.overs ?? existingForPause.team1Overs;
        existingForPause.team2Runs =
            secondScore?.totalRuns ?? existingForPause.team2Runs;
        existingForPause.team2Wickets =
            secondScore?.wickets ?? existingForPause.team2Wickets;
        existingForPause.team2Overs =
            secondScore?.overs ?? existingForPause.team2Overs;
        existingForPause.save();
      } else {
        MatchHistory.create(
          matchId: widget.matchId,
          teamAId: currentMatch!.teamId1,
          teamBId: currentMatch!.teamId2,
          matchDate: DateTime.now(),
          matchType: 'CRICKET',
          team1Runs: firstScore?.totalRuns ?? 0,
          team1Wickets: firstScore?.wickets ?? 0,
          team1Overs: firstScore?.overs ?? 0.0,
          team2Runs: secondScore?.totalRuns ?? 0,
          team2Wickets: secondScore?.wickets ?? 0,
          team2Overs: secondScore?.overs ?? 0.0,
          result: 'Match Paused',
          isCompleted: false,
          isPaused: true,
          isOnProgress: false,
          pausedState: matchStateJson,
          matchEndTime: DateTime.now(),
          createdBy: currentMatch!.createdBy,
          tournamentId: currentMatch!.tournamentId,
        );
      }

      final verify = MatchHistory.getByMatchId(widget.matchId);
      debugPrint(
        '✅ SaveMatchState — matchId=${widget.matchId}, '
        'isPaused=${verify?.isPaused}, '
        'pausedState length=${verify?.pausedState?.length ?? 0}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match saved! You can resume it later.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      final navigator = Navigator.of(context);
      _clearLEDDisplay().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InitialTeamPage()),
            (route) => false,
          );
        });
      });
    } catch (e) {
      debugPrint('❌ Error saving match state: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 Future<void> _updateMatchToHistory(bool battingTeamWon, Score firstInningsScore) async {
  if (currentMatch == null || currentInnings == null || currentScore == null) return;

  final firstInnings = Innings.getFirstInnings(widget.matchId);
  if (firstInnings == null) return;

  String result;

  final teamAName =
      Team.getById(firstInnings.battingTeamId)?.teamName ??
      (currentInnings!.isSecondInnings ? _bowlingTeamNameCache : _battingTeamNameCache) ??
      'Team A';
  final teamBName =
      Team.getById(firstInnings.bowlingTeamId)?.teamName ??
      (currentInnings!.isSecondInnings ? _battingTeamNameCache : _bowlingTeamNameCache) ??
      'Team B';

  if (currentInnings!.isSecondInnings) {
    if (currentScore!.totalRuns >= currentInnings!.targetRuns) {
      final wicketsRemaining = 10 - currentScore!.wickets;
      result = '$teamBName won by $wicketsRemaining wickets';
    } else {
      final runsDifference = currentInnings!.targetRuns - currentScore!.totalRuns;
      result = '$teamAName won by $runsDifference runs';
    }
  } else {
    final teamMembers = TeamMember.getByTeamId(currentInnings!.battingTeamId);
    final wicketsRemaining = (teamMembers.length - 1) - currentScore!.wickets;
    result = '$teamAName completed innings with $wicketsRemaining wickets remaining';
  }

  debugPrint('🏆 _updateMatchToHistory: computed result = $result');

  final existingHistory = MatchHistory.getByMatchId(widget.matchId);

  if (existingHistory != null) {
    existingHistory.isCompleted   = true;
    existingHistory.isPaused      = false;
    existingHistory.isOnProgress  = false;
    existingHistory.pausedState   = null;
    existingHistory.result        = result;
    existingHistory.team1Runs     = firstInningsScore.totalRuns;
    existingHistory.team1Wickets  = firstInningsScore.wickets;
    existingHistory.team1Overs    = firstInningsScore.overs;
    existingHistory.team2Runs     = currentScore!.totalRuns;
    existingHistory.team2Wickets  = currentScore!.wickets;
    existingHistory.team2Overs    = currentScore!.overs;
    existingHistory.matchDate     = DateTime.now();
    existingHistory.matchEndTime  = DateTime.now();
    existingHistory.matchStartTime ??= DateTime.now();
    existingHistory.save();
    debugPrint('✅ existingHistory saved — isCompleted=${existingHistory.isCompleted}, result=${existingHistory.result}');
  } else {
    final created = MatchHistory.create(
      matchId:        widget.matchId,
      teamAId:        firstInnings.battingTeamId,
      teamBId:        firstInnings.bowlingTeamId,
      matchDate:      DateTime.now(),
      matchType:      'CRICKET',
      team1Runs:      firstInningsScore.totalRuns,
      team1Wickets:   firstInningsScore.wickets,
      team1Overs:     firstInningsScore.overs,
      team2Runs:      currentScore!.totalRuns,
      team2Wickets:   currentScore!.wickets,
      team2Overs:     currentScore!.overs,
      result:         result,
      isCompleted:    true,
      isPaused:       false,
      isOnProgress:   false,
      matchStartTime: DateTime.now(),
      matchEndTime:   DateTime.now(),
      createdBy:      currentMatch!.createdBy,
      tournamentId:   currentMatch!.tournamentId,
    );
    debugPrint('✅ new history created — isCompleted=${created.isCompleted}, result=${created.result}');
  }

  await _updateTournamentMatchResult(
    result: result,
    battingTeamWon: battingTeamWon,
    firstInningsScore: firstInningsScore,
  );
}

 void _showMatchTiedDialog(Score firstInningsScore) {
  currentInnings?.markCompleted();

  setState(() => isMatchComplete = true);

  _ledUpdateTimer?.cancel();
  _ledUpdateTimer = null;

  Future(() async {
    // Await full Firestore write first
    await _updateMatchTiedToHistory(firstInningsScore);

    debugPrint('🎯 Tie recorded — draining LED queue before clear...');
    int drainWait = 0;
    while (_ledQueueRunning && drainWait < 30) {
      await Future.delayed(const Duration(milliseconds: 50));
      drainWait++;
    }
    _ledQueue.clear();

    await _clearLEDDisplay();
    await Future.delayed(const Duration(milliseconds: 300));

    final existingHistory = MatchHistory.getByMatchId(widget.matchId);
    if (existingHistory != null && existingHistory.result.isNotEmpty) {
      await _showMatchSummaryOnLED(existingHistory.result);
    }
    debugPrint('✅ Match stats displayed');
  });

  final teamAName = Team.getById(currentInnings!.bowlingTeamId)?.teamName ?? "Team A";
  final teamBName = Team.getById(currentInnings!.battingTeamId)?.teamName ?? "Team B";

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C1F24),
      title: const Text(
        '🤝 Match Tied!',
        style: TextStyle(color: Color(0xFFFF9800), fontSize: 22, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Both teams scored the same runs!',
              style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 16)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0f0f1e),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF9800), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Final Scores',
                    style: TextStyle(color: Color(0xFFFF9800), fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$teamAName:', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('${firstInningsScore.totalRuns}/${firstInningsScore.wickets}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$teamBName:', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('${currentScore!.totalRuns}/${currentScore!.wickets}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Home()),
              (route) => false,
            );
          },
          child: const Text('View History', style: TextStyle(color: Color(0xFF6D7CFF))),
        ),
      ],
    ),
  );

  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) {
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
        }
      });
    }
  });
}
  void _showLeaveMatchDialog() {
    setState(() {
      _isRunoutModeActive = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text(
          'Leave Match?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'What would you like to do?',
          style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Continue Match',
              style: TextStyle(color: Color(0xFF9AA0A6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D7CFF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _saveMatchState();
            },
            child: const Text(
              'Save & Exit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!widget.isResumed)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B3B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop(); // Close dialog

                if (mounted) {
                  setState(() => isMatchComplete = true);
                }

                // Drain queue and clear before navigating
                _ledQueue.clear();
                int drainWait = 0;
                while (_ledQueueRunning && drainWait < 20) {
                  await Future.delayed(const Duration(milliseconds: 50));
                  drainWait++;
                }

                await _clearLEDDisplay();
                await Future.delayed(const Duration(milliseconds: 200));

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const InitialTeamPage(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Discard & Exit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

void addRuns(int runs) {
    if (currentScore == null || strikeBatsman == null || currentBowler == null)
      return;
if (_firstInningsLocked) return;
if (_isInningsComplete()) return;
    if (isRunout) {
      addRunout(runs);
      return;
    }

    if (_isRunoutModeActive) {
      setState(() {
        _isRunoutModeActive = false;
      });
    }

    // ✅ Snapshot BEFORE setState so maiden check is correct
    final int runsInOverBeforeThisBall = runsInCurrentOver;
    bool countBallForBowler = true; // will be set correctly inside setState

    setState(() {
      actionHistory.add({
        'type': 'runs',
        'runs': runs,
        'strikeBatsmanId': strikeBatsman!.batId,
        'nonStrikeBatsmanId': nonStrikeBatsman!.batId,
        'batsmanRuns': strikeBatsman!.runs,
        'batsmanBalls': strikeBatsman!.ballsFaced,
        'batsmanFours': strikeBatsman!.fours,
        'batsmanSixes': strikeBatsman!.sixes,
        'batsmanDotBalls': strikeBatsman!.dotBalls,
        'batsmanExtras': strikeBatsman!.extras,
        'bowlerRuns': currentBowler!.runsConceded,
        'bowlerBalls': currentBowler!.balls,
        'bowlerWickets': currentBowler!.wickets,
        'bowlerMaidens': currentBowler!.maidens,
        'bowlerExtras': currentBowler!.extras,
        'totalRuns': currentScore!.totalRuns,
        'currentBall': currentScore!.currentBall,
        'overs': currentScore!.overs,
        'currentOver': List<String>.from(currentScore!.currentOver),
        'runsInCurrentOver': runsInCurrentOver,
        'isNoBall': isNoBall,
        'isWide': isWide,
        'isByes': isByes,
        'byes': currentScore!.byes,
        'wides': currentScore!.wides,
        'noBalls': currentScore!.noBalls,
      });

      int totalRunsToAdd = 0;
      int batsmanRuns = 0;
      int extrasRuns = 0;
      String ballDisplay = runs.toString();
      bool countBallForBatsman = true;
      countBallForBowler = true; // assign to outer variable

      if (isNoBall) {
        extrasRuns = 1;
        totalRunsToAdd = 1;
        countBallForBatsman = false;
        countBallForBowler = false;
        currentScore!.noBalls += 1;

        if (isByes) {
          totalRunsToAdd += runs;
          currentScore!.byes += runs;
          ballDisplay = 'NB+$runs';
          strikeBatsman!.extras += extrasRuns;
          strikeBatsman!.save();
        } else if (runs > 0) {
          totalRunsToAdd += runs;
          batsmanRuns = runs;
          ballDisplay = 'NB$runs';
          strikeBatsman!.updateStats(
            batsmanRuns,
            extrasRuns: extrasRuns,
            countBall: countBallForBatsman,
          );
        } else {
          ballDisplay = 'NB';
          strikeBatsman!.extras += extrasRuns;
          strikeBatsman!.save();
        }

        runsInCurrentOver += totalRunsToAdd;
      } else if (isWide) {
        if (isByes) {
          totalRunsToAdd = 1 + runs;
          extrasRuns = totalRunsToAdd;
          currentScore!.wides += totalRunsToAdd;
          ballDisplay = runs > 0 ? 'WD+$runs' : 'WD';
        } else if (runs > 0) {
          totalRunsToAdd = 1 + runs;
          extrasRuns = totalRunsToAdd;
          currentScore!.wides += totalRunsToAdd;
          ballDisplay = 'WD$runs';
        } else {
          totalRunsToAdd = 1;
          extrasRuns = 1;
          currentScore!.wides += 1;
          ballDisplay = 'WD';
        }

        countBallForBatsman = false;
        countBallForBowler = false;

        strikeBatsman!.extras += extrasRuns;
        strikeBatsman!.save();

        runsInCurrentOver += totalRunsToAdd;
      } else if (isByes) {
        extrasRuns = runs;
        totalRunsToAdd = runs;
        ballDisplay = 'B$runs';
        currentScore!.byes += runs;

        strikeBatsman!.updateStats(0, extrasRuns: extrasRuns, countBall: true);

        runsInCurrentOver += runs;
      } else {
        totalRunsToAdd = runs;
        batsmanRuns = runs;

        strikeBatsman!.updateStats(batsmanRuns, extrasRuns: 0, countBall: true);

        runsInCurrentOver += runs;
      }

      currentBowler!.updateStats(
        totalRunsToAdd,
        false,
        extrasRuns: extrasRuns,
        countBall: countBallForBowler,
      );

      var tempOver = currentScore!.currentOver;
      tempOver.add(ballDisplay);
      currentScore!.currentOver = tempOver;

      if (countBallForBowler) _updateOverTracking();
      _persistBallToFirestore(
        display: ballDisplay,
        runs: totalRunsToAdd,
        isWide: isWide,
        isNoBall: isNoBall,
        isBye: isByes && !isWide && !isNoBall,
      );

      currentScore!.totalRuns += totalRunsToAdd;
      currentScore!.crr = currentScore!.overs > 0
          ? (currentScore!.totalRuns / currentScore!.overs)
          : 0.0;
      currentScore!.save();

      // Trigger boundary animations
      if (runs == 4) {
        _triggerBoundaryAnimation('4');
      } else if (runs == 6) {
        _triggerBoundaryAnimation('6');
      }

      isNoBall = false;
      isWide = false;
      isByes = false;
      showExtrasOptions = false;
    }); // ✅ setState closes here — all dialogs/checks are outside

    // ✅ Victory check OUTSIDE setState
    if (currentInnings != null && currentInnings!.isSecondInnings) {
      if (_checkSecondInningsVictory()) return;
    }

    if (countBallForBowler && currentScore!.currentBall % 6 == 0) {
      // ✅ Use pre-ball snapshot for maiden check
      if (runsInCurrentOver == 0) {
        currentBowler!.incrementMaiden();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maiden Over! 🎯'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() => runsInCurrentOver = 0);

      // ✅ Swap for even runs at end of over
      if (runs % 2 == 0) _switchStrike();

      if (_isInningsComplete()) {
        _updateLEDAfterScore();
        _endInnings();
        return;
      }

      // ✅ Dialog OUTSIDE setState
      _showChangeBowlerDialog();
      _resetCurrentOver();
      _updateLEDAfterScore();
    } else if (runs % 2 == 1 && !isByes && !isWide) {
      _switchStrike();
      _updateLEDAfterScore();
    } else {
      _updateLEDAfterScore();
    }
  }

 void addWicket() {
    if (currentScore == null || strikeBatsman == null || currentBowler == null)
    
      return;
    if (_firstInningsLocked) return;
    if (_isInningsComplete()) return;
    // Snapshot EVERYTHING before any mutation happens
    final savedAction = {
      'type': 'wicket',
      'strikeBatsmanId': strikeBatsman!.batId,
      'nonStrikeBatsmanId': nonStrikeBatsman!.batId,
      'scoreStrikeBatsmanId': currentScore!.strikeBatsmanId,
      'scoreNonStrikeBatsmanId': currentScore!.nonStrikeBatsmanId,
      // Batsman state
      'batsmanIsOut': strikeBatsman!.isOut,
      'batsmanDismissalType': strikeBatsman!.dismissalType,
      'batsmanFielderId': strikeBatsman!.fielderIdWhoRanOut,
      'batsmanBowlerWhoGotWicket': strikeBatsman!.bowlerIdWhoGotWicket,
      'batsmanRuns': strikeBatsman!.runs,
      'batsmanBalls': strikeBatsman!.ballsFaced,
      'batsmanFours': strikeBatsman!.fours,
      'batsmanSixes': strikeBatsman!.sixes,
      'batsmanDotBalls': strikeBatsman!.dotBalls,
      'batsmanExtras': strikeBatsman!.extras,
      // Bowler state
      'bowlerWickets': currentBowler!.wickets,
      'bowlerBalls': currentBowler!.balls,
      'bowlerRuns': currentBowler!.runsConceded,
      'bowlerMaidens': currentBowler!.maidens,
      'bowlerExtras': currentBowler!.extras,
      // Score state
      'runsInCurrentOver': runsInCurrentOver,
      'wickets': currentScore!.wickets,
      'currentBall': currentScore!.currentBall,
      'overs': currentScore!.overs,
      'currentOver': List<String>.from(currentScore!.currentOver),
    };

    // Show dismissal dialog FIRST — _applyWicket() does all actual mutations
    _showDismissalTypeDialog(savedAction);
  }

  void _applyWicket(
    Map<String, dynamic> savedAction, {
    required String dismissalType,
    String? fielderId,
  }) {
    setState(() {
      actionHistory.add(savedAction);

      strikeBatsman!.markAsOut(
        bowlerIdWhoGotWicket: currentBowler!.bowlerId,
        dismissalType: dismissalType, // ✅ apply dismissal type
        fielderIdWhoRanOut: fielderId, // ✅ apply fielder
      );
      currentScore!.wickets++;
      currentBowler!.updateStats(0, true, extrasRuns: 0, countBall: true);

      var tempOver = currentScore!.currentOver;
      tempOver.add('W');
      currentScore!.currentOver = tempOver;

      _updateOverTracking();
      _persistBallToFirestore(display: 'W', runs: 0, isWicket: true);
    });

    // ✅ Outside setState
    _triggerWicketAnimation();

    if (strikeBatsman!.runs == 0) {
      _triggerDuckAnimation(strikeBatsman!.batId);
    }

    // Check innings-end conditions OUTSIDE setState
    if (currentInnings != null) {
      final teamMembers = TeamMember.getByTeamId(currentInnings!.battingTeamId);
      if (currentScore!.wickets >= teamMembers.length - 1) {
        currentScore!.save();
        _updateLEDAfterScore();
        _endInnings();
        return;
      }
    }

    if (_isInningsComplete()) {
      currentScore!.save();
      _updateLEDAfterScore();
      _endInnings();
      return;
    }

    currentScore!.save();
    _updateLEDAfterScore();

    final bool isOverComplete = currentScore!.currentBall % 6 == 0;

    _showSelectNextBatsmanDialog(
      onCancel: () => _undoWicket(savedAction),
      onConfirm: () {
        // ✅ added onConfirm
        if (isOverComplete) {
          if (runsInCurrentOver == 0) {
            currentBowler!.incrementMaiden();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maiden Over! 🎯'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
          setState(() => runsInCurrentOver = 0);
          _showChangeBowlerDialog();
          _resetCurrentOver();
          _switchStrike();
        }
      },
    );
  }

  void _showFielderPickerForWicket(
    Map<String, dynamic> savedAction,
    String dismissalType,
  ) {
    if (currentInnings == null) return;

    final fielders = TeamMember.getByTeamId(currentInnings!.bowlingTeamId);

    final label = dismissalType == 'caught'
        ? 'Caught by'
        : dismissalType == 'stumped'
        ? 'Stumped by'
        : 'Fielder';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: fielders.map((player) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A32),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Color(0xFF6D7CFF),
                    size: 20,
                  ),
            title: Text(
                    player.playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    _applyWicket(
                      savedAction,
                      dismissalType: dismissalType,
                      fielderId: player.playerId,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _applyWicket(
                savedAction,
                dismissalType: dismissalType,
                fielderId: null, // ✅ no fielder
              );
            },
            child: const Text(
              'Skip',
              style: TextStyle(color: Color(0xFF9AA0A6), fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDismissalTypeDialog(Map<String, dynamic> savedAction) {
    final dismissalTypes = [
      {
        'label': 'Bowled',
        'value': 'bowled',
        'icon': Icons.sports_cricket,
        'needsFielder': false,
      },
      {
        'label': 'Caught',
        'value': 'caught',
        'icon': Icons.back_hand,
        'needsFielder': true,
      },
      {
        'label': 'LBW',
        'value': 'lbw',
        'icon': Icons.front_hand,
        'needsFielder': false,
      },
      {
        'label': 'Stumped',
        'value': 'stumped',
        'icon': Icons.sports_cricket,
        'needsFielder': true,
      },
      {
        'label': 'Hit Wicket',
        'value': 'hit_wicket',
        'icon': Icons.close,
        'needsFielder': false,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'How was the batsman out?',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: dismissalTypes.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF252A32),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  d['icon'] as IconData,
                  color: const Color(0xFF6D7CFF),
                  size: 22,
                ),
                title: Text(
                  d['label'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: (d['needsFielder'] as bool)
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF9AA0A6),
                        size: 16,
                      )
                    : null,
                onTap: () {
                  Navigator.of(dialogCtx).pop();
                  final needsFielder = d['needsFielder'] as bool;
                  final dismissalType = d['value'] as String;

                  if (needsFielder) {
                    _showFielderPickerForWicket(savedAction, dismissalType);
                  } else {
                    _applyWicket(
                      // ✅ was missing
                      savedAction,
                      dismissalType: dismissalType,
                      fielderId: null,
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9AA0A6), fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 NEW: Undo a wicket when user cancels batsman selection
  void _undoWicket(Map<String, dynamic> savedAction) {
    setState(() {
      // Remove the last action from history
      if (actionHistory.isNotEmpty && actionHistory.last['type'] == 'wicket') {
        actionHistory.removeLast();
      }

      // Restore batsman state
      final strikerBatId = savedAction['strikeBatsmanId'];
      final batsman = Batsman.getByBatId(strikerBatId);
      if (batsman != null) {
        batsman.isOut = savedAction['batsmanIsOut'];
        batsman.dismissalType = savedAction['batsmanDismissalType'];
        batsman.fielderIdWhoRanOut = savedAction['batsmanFielderId'];
        batsman.bowlerIdWhoGotWicket = savedAction['batsmanBowlerWhoGotWicket'];
        batsman.extras = savedAction['batsmanExtras'];
        batsman.runs = savedAction['batsmanRuns'];
        batsman.ballsFaced = savedAction['batsmanBalls'];
        batsman.fours = savedAction['batsmanFours'];
        batsman.sixes = savedAction['batsmanSixes'];
        batsman.dotBalls = savedAction['batsmanDotBalls'];
        batsman.strikeRate = batsman.ballsFaced > 0
            ? (batsman.runs / batsman.ballsFaced) * 100
            : 0.0;
        batsman.save();
      }
      strikeBatsman = Batsman.getByBatId(savedAction['strikeBatsmanId']);
      nonStrikeBatsman = Batsman.getByBatId(savedAction['nonStrikeBatsmanId']);

      // 🔥 FIX: Restore score's internal batsman ID pointers
      currentScore!.strikeBatsmanId = savedAction['scoreStrikeBatsmanId'];
      currentScore!.nonStrikeBatsmanId = savedAction['scoreNonStrikeBatsmanId'];

      // Restore bowler state
      if (currentBowler != null) {
        currentBowler!.wickets = savedAction['bowlerWickets'];
        currentBowler!.balls = savedAction['bowlerBalls'];
        currentBowler!.runsConceded = savedAction['bowlerRuns'];
        currentBowler!.maidens = savedAction['bowlerMaidens'];
        currentBowler!.extras = savedAction['bowlerExtras'];

        int completedOvers = currentBowler!.balls ~/ 6;
        int remainingBalls = currentBowler!.balls % 6;
        currentBowler!.overs = completedOvers + (remainingBalls / 10.0);

        double totalOvers = completedOvers + (remainingBalls / 6.0);
        currentBowler!.economy = totalOvers > 0
            ? (currentBowler!.runsConceded / totalOvers)
            : 0.0;

        currentBowler!.save();
        currentBowler = Bowler.getByBowlerId(currentBowler!.bowlerId);
      }

      // Restore score state
      currentScore!.wickets = savedAction['wickets'];
      currentScore!.currentBall = savedAction['currentBall'];
      currentScore!.overs = savedAction['overs'];
      currentScore!.currentOver = List<String>.from(savedAction['currentOver']);
      currentScore!.crr = currentScore!.overs > 0
          ? (currentScore!.totalRuns / currentScore!.overs)
          : 0.0;
      runsInCurrentOver = savedAction['runsInCurrentOver'];
      currentScore!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wicket cancelled'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    });

    _updateLEDAfterScore();
  }

void addRunout(int runs) {
    if (_firstInningsLocked) return;
    if (_isInningsComplete()) return;
    setState(() {
      pendingRunoutRuns = runs;
    });
    _showRunoutBatsmanSelectionDialog(runs);
  }

  void _showRunoutBatsmanSelectionDialog(int runs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text(
          'Select Batsman Who Got Run Out',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                TeamMember.getByPlayerId(strikeBatsman!.playerId)?.teamName ??
                    'Striker',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: const Text(
                'Striker',
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
              onTap: () {
                Navigator.pop(context);
                runoutBatsmanId = strikeBatsman!.batId;
                _showFielderSelectionDialog(runs, runoutBatsmanId!);
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              title: Text(
                TeamMember.getByPlayerId(
                      nonStrikeBatsman!.playerId,
                    )?.teamName ??
                    'Non-Striker',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Non-Striker',
                style: TextStyle(color: Color(0xFF9AA0A6)),
              ),
              onTap: () {
                Navigator.pop(context);
                runoutBatsmanId = nonStrikeBatsman!.batId;
                _showFielderSelectionDialog(runs, runoutBatsmanId!);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add this dialog method
  void _showFielderSelectionDialog(int runs, String runoutBatsmanId) {
    if (currentInnings == null) return;

    final bowlingTeamPlayers = TeamMember.getByTeamId(
      currentInnings!.bowlingTeamId,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text(
          'Run Out By',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: bowlingTeamPlayers.map((player) {
              return ListTile(
            title: Text(
                  player.teamName,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              subtitle: null,
                onTap: () {
                  Navigator.pop(context);
                  _finalizeRunout(runs, runoutBatsmanId, player.playerId);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Add this method to finalize runout
  void _finalizeRunout(int runs, String runoutBatsmanId, String fielderId) {
    if (currentScore == null || currentBowler == null) return;

    final runoutBatsman = Batsman.getByBatId(runoutBatsmanId);
    if (runoutBatsman == null) return;

    // ── SNAPSHOT before any mutation ──────────────────────────────────────────
    final savedAction = {
      'type': 'runout',
      'runs': runs,
      'runoutBatsmanId': runoutBatsmanId,
      'fielderId': fielderId,
      'strikeBatsmanId': strikeBatsman!.batId,
      'nonStrikeBatsmanId': nonStrikeBatsman!.batId,
      'scoreStrikeBatsmanId': currentScore!.strikeBatsmanId,
      'scoreNonStrikeBatsmanId': currentScore!.nonStrikeBatsmanId,
      'strikerRuns': strikeBatsman!.runs,
      'strikerBalls': strikeBatsman!.ballsFaced,
      'strikerFours': strikeBatsman!.fours,
      'strikerSixes': strikeBatsman!.sixes,
      'strikerDotBalls': strikeBatsman!.dotBalls,
      'strikerExtras': strikeBatsman!.extras,
      'runoutBatsmanIsOut': runoutBatsman.isOut,
      'runoutBatsmanDismissalType': runoutBatsman.dismissalType,
      'runoutBatsmanFielderId': runoutBatsman.fielderIdWhoRanOut,
      'runoutBatsmanRuns': runoutBatsman.runs,
      'bowlerRuns': currentBowler!.runsConceded,
      'bowlerBalls': currentBowler!.balls,
      'bowlerWickets': currentBowler!.wickets,
      'bowlerMaidens': currentBowler!.maidens,
      'bowlerExtras': currentBowler!.extras,
      'totalRuns': currentScore!.totalRuns,
      'wickets': currentScore!.wickets,
      'currentBall': currentScore!.currentBall,
      'overs': currentScore!.overs,
      'currentOver': List<String>.from(currentScore!.currentOver),
      'runsInCurrentOver': runsInCurrentOver,
    };

    // ── Flags to decide post-setState side effects ─────────────────────────────
    bool shouldEndInnings = false;
    bool isOverComplete = false;
    bool strikerGotOut = false;

    // ── All UI-driving mutations in ONE setState ───────────────────────────────
    setState(() {
      actionHistory.add(savedAction);

      strikeBatsman!.updateStats(runs, extrasRuns: 0, countBall: true);

      runoutBatsman.markAsOut(
        dismissalType: 'runout',
        fielderIdWhoRanOut: fielderId,
      );

      currentScore!.totalRuns += runs;
      currentScore!.wickets++;

      currentBowler!.updateStats(runs, false, extrasRuns: 0, countBall: true);

      var tempOver = currentScore!.currentOver;
      tempOver.add('${runs}RO');
      currentScore!.currentOver = tempOver;

      _updateOverTracking();
      _persistBallToFirestore(display: '${runs}RO', runs: runs, isWicket: true);

      currentScore!.crr = currentScore!.overs > 0
          ? (currentScore!.totalRuns / currentScore!.overs)
          : 0.0;

      runsInCurrentOver += runs;

      // ── Compute flags INSIDE setState so they read final mutated state ──
      if (currentInnings != null) {
        final teamMembers = TeamMember.getByTeamId(
          currentInnings!.battingTeamId,
        );
        if (currentScore!.wickets >= teamMembers.length - 1) {
          shouldEndInnings = true;
        }
      }
      if (!shouldEndInnings && _isInningsComplete()) shouldEndInnings = true;

      isOverComplete = currentScore!.currentBall % 6 == 0;
      strikerGotOut = runoutBatsmanId == strikeBatsman!.batId;

      // Reset runout mode flags
      isRunout = false;
      pendingRunoutRuns = null;
      this.runoutBatsmanId = null;
    });

    // ── Save OUTSIDE setState ──────────────────────────────────────────────────
    currentScore!.save();

    // ── Animations OUTSIDE setState ───────────────────────────────────────────
    _triggerRunoutHighlight(runoutBatsmanId);

    if (runoutBatsman.runs == 0) {
      _triggerDuckAnimation(runoutBatsmanId);
    }

    // ── LED update OUTSIDE setState ───────────────────────────────────────────
    _updateLEDAfterScore();

    // ── Early exit: innings complete ──────────────────────────────────────────
    if (shouldEndInnings) {
      _endInnings();
      return;
    }

    // ── Early exit: second innings victory ────────────────────────────────────
    if (currentInnings != null && currentInnings!.isSecondInnings) {
      if (_checkSecondInningsVictory()) return;
    }

    // ── Swap striker if striker got run out ───────────────────────────────────
    // ── Swap striker if striker got run out ───────────────────────────────────
    if (strikerGotOut) {
      setState(() => strikeBatsman = nonStrikeBatsman);
    }

    // ✅ Fix: switch strike BEFORE showing dialog
    if (runs % 2 == 1) {
      _switchStrike();
    }

    // ── Show next batsman dialog ───────────────────────────────────────────────
    _showSelectNextBatsmanDialog(onCancel: () => _undoRunout(savedAction));

    // ── Handle over completion ────────────────────────────────────────────────
    if (isOverComplete) {
      if (runsInCurrentOver == 0) {
        currentBowler!.incrementMaiden();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maiden Over! 🎯'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() => runsInCurrentOver = 0);
      _showChangeBowlerDialog();
      _resetCurrentOver();
    }
  }

  void _undoRunout(Map<String, dynamic> savedAction) {
    setState(() {
      // Remove from action history
      if (actionHistory.isNotEmpty && actionHistory.last['type'] == 'runout') {
        actionHistory.removeLast();
      }

      // Restore runout batsman's out-state
      final runoutBatId = savedAction['runoutBatsmanId'];
      final runoutBat = Batsman.getByBatId(runoutBatId);
      if (runoutBat != null) {
        runoutBat.isOut = savedAction['runoutBatsmanIsOut'];
        runoutBat.dismissalType = savedAction['runoutBatsmanDismissalType'];
        runoutBat.fielderIdWhoRanOut = savedAction['runoutBatsmanFielderId'];
        runoutBat.save();
      }

      // Restore striker's stats
      final strikerBatId = savedAction['strikeBatsmanId'];
      final strikerBat = Batsman.getByBatId(strikerBatId);
      if (strikerBat != null) {
        strikerBat.runs = savedAction['strikerRuns'];
        strikerBat.ballsFaced = savedAction['strikerBalls'];
        strikerBat.fours = savedAction['strikerFours'];
        strikerBat.sixes = savedAction['strikerSixes'];
        strikerBat.dotBalls = savedAction['strikerDotBalls'];
        strikerBat.extras = savedAction['strikerExtras'];
        strikerBat.strikeRate = strikerBat.ballsFaced > 0
            ? (strikerBat.runs / strikerBat.ballsFaced) * 100
            : 0.0;
        strikerBat.save();
      }

      // Restore strikeBatsman / nonStrikeBatsman references
      strikeBatsman = Batsman.getByBatId(savedAction['strikeBatsmanId']);
      nonStrikeBatsman = Batsman.getByBatId(savedAction['nonStrikeBatsmanId']);

      // 🔥 Restore score's internal batsman ID pointers
      currentScore!.strikeBatsmanId = savedAction['scoreStrikeBatsmanId'];
      currentScore!.nonStrikeBatsmanId = savedAction['scoreNonStrikeBatsmanId'];

      // Restore bowler state
      if (currentBowler != null) {
        currentBowler!.runsConceded = savedAction['bowlerRuns'];
        currentBowler!.balls = savedAction['bowlerBalls'];
        currentBowler!.wickets = savedAction['bowlerWickets'];
        currentBowler!.maidens = savedAction['bowlerMaidens'];
        currentBowler!.extras = savedAction['bowlerExtras'];

        int completedOvers = currentBowler!.balls ~/ 6;
        int remainingBalls = currentBowler!.balls % 6;
        currentBowler!.overs = completedOvers + (remainingBalls / 10.0);

        double totalOvers = completedOvers + (remainingBalls / 6.0);
        currentBowler!.economy = totalOvers > 0
            ? (currentBowler!.runsConceded / totalOvers)
            : 0.0;

        currentBowler!.save();
        currentBowler = Bowler.getByBowlerId(currentBowler!.bowlerId);
      }

      // Restore score state
      currentScore!.totalRuns = savedAction['totalRuns'];
      currentScore!.wickets = savedAction['wickets'];
      currentScore!.currentBall = savedAction['currentBall'];
      currentScore!.overs = savedAction['overs'];
      currentScore!.currentOver = List<String>.from(savedAction['currentOver']);
      currentScore!.crr = currentScore!.overs > 0
          ? (currentScore!.totalRuns / currentScore!.overs)
          : 0.0;
      runsInCurrentOver = savedAction['runsInCurrentOver'];

      // Reset runout mode flags
      isRunout = false;
      pendingRunoutRuns = null;
      runoutBatsmanId = null;

      currentScore!.save();

      // 🔥 Force star re-evaluation
      _lastRow74WasStriker = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Runout cancelled'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    });

    _updateLEDAfterScore();
  }

  void _showSelectNextBatsmanDialog({
    VoidCallback? onCancel,
    VoidCallback? onConfirm, // ✅ ADD THIS
  }) {
    if (currentInnings == null) return;

    final allBatsmenInInnings = Batsman.getByInningsAndTeam(
      currentInnings!.inningsId,
      currentInnings!.battingTeamId,
    );

    final teamPlayers = TeamMember.getByTeamId(currentInnings!.battingTeamId);

    // 🔥 FIX: Exclude batsmen whose Batsman record was cancelled by a prior undo
    // Without this, undone new-batsman records still block their playerId from the dropdown
    final playersWhoBatted = allBatsmenInInnings
        .where((b) => !_cancelledBatsmanIds.contains(b.batId))
        .map((b) => b.playerId)
        .toSet();

    final availablePlayers = teamPlayers
        .where((p) => !playersWhoBatted.contains(p.playerId))
        .toList();

    if (availablePlayers.isEmpty) {
      currentScore!.save();
      _endInnings();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop();
          onCancel?.call();
          return false;
        },
        child: AlertDialog(
          backgroundColor: const Color(0xFF1C1F24),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Next Batsman',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                tooltip: 'Cancel wicket',
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Available Batsmen:',
                    style: TextStyle(
                      color: Color(0xFF6D7CFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                ...availablePlayers.map((player) {
                  return ListTile(
                    title: Text(
                      player.teamName,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                    ),
                    subtitle: null,
                    onTap: () {
                      // ── FIX 2: pass tournamentId + matchId from currentInnings ──
                    final newBatsman = Batsman.create(
                        inningsId: currentInnings!.inningsId,
                        teamId: currentInnings!.battingTeamId,
                        playerId: player.playerId,
                        playerName: player.playerName,
                        tournamentId: currentInnings!.tournamentId,
                        matchId: currentInnings!.matchId,
                        createdBy: currentMatch!.createdBy,
                      );

                      // 🔥 FIX: Store the new batsman's batId in the wicket action so
                      // _performUndo can mark it as cancelled and restore the dropdown
                      if (actionHistory.isNotEmpty &&
                          (actionHistory.last['type'] == 'wicket' ||
                              actionHistory.last['type'] == 'runout')) {
                        actionHistory.last['newBatsmanBatId'] =
                            newBatsman.batId;
                      }

                      setState(() {
                        strikeBatsman = newBatsman;
                        currentScore!.strikeBatsmanId = newBatsman.batId;
                        currentScore!.save();
                      });

                      Navigator.pop(context);
                      onConfirm?.call();
                      _updateLEDAfterScore();
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: const Text(
                'Cancel Wicket',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeBowlerDialog() {
    if (currentInnings == null) return;

    // Get all bowlers who have bowled in this innings
    final allBowlers = Bowler.getByInningsAndTeam(
      currentInnings!.inningsId,
      currentInnings!.bowlingTeamId,
    );

    // Get team players
    final teamPlayers = TeamMember.getByTeamId(currentInnings!.bowlingTeamId);
    final existingPlayerIds = allBowlers.map((b) => b.playerId).toSet();

    // Get available players who haven't bowled yet
    final newBowlerPlayers = teamPlayers
        .where((p) => !existingPlayerIds.contains(p.playerId))
        .toList();

    // Filter available bowlers: exclude the CURRENT bowler (who just completed the over)
    final availableBowlers = allBowlers.where((b) {
      // Exclude the bowler who just finished their over (current bowler)
      // currentBowler should be the Bowler object of who just bowled
      if (currentBowler != null && b.bowlerId == currentBowler!.bowlerId) {
        return false;
      }

      return true;
    }).toList();

    // Combine all available bowlers (existing + new) into a unified list
    List<Map<String, dynamic>> allAvailableBowlers = [];

    // Add existing bowlers
    for (var bowler in availableBowlers) {
      final player = TeamMember.getByPlayerId(bowler.playerId);
      allAvailableBowlers.add({
        'type': 'existing',
        'bowler': bowler,
        'player': player,
        'name': player?.teamName ?? 'Unknown',
        'stats':
            '${bowler.wickets}-${bowler.runsConceded} (${bowler.overs.toStringAsFixed(1)}) M:${bowler.maidens}',
      });
    }

    // Add new bowlers
    for (var player in newBowlerPlayers) {
      allAvailableBowlers.add({
        'type': 'new',
        'player': player,
        'name': player.teamName,
        'stats': 'New bowler',
      });
    }

    // Check if any bowlers are available
    if (allAvailableBowlers.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1F24),
          title: const Text(
            'No Bowlers Available',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No bowlers are currently available. The current bowler cannot bowl consecutive overs, and no other bowlers are available.',
            style: TextStyle(color: Color(0xFF9AA0A6)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _endInnings();
              },
              child: const Text(
                'End Innings',
                style: TextStyle(color: Color(0xFFFF3B3B)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    int backPressCount = 0;

    // Show unified dialog with all available bowlers
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          backPressCount++;
          if (backPressCount == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a bowler to continue'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
            return false;
          } else if (backPressCount >= 2) {
            // Auto-select first available bowler
            final firstBowler = allAvailableBowlers.first;
            Navigator.pop(context); // Close dialog first
            _selectBowler(firstBowler);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Auto-selected bowler: ${firstBowler['name']}'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
            return false; // Prevent default back behavior
          }
          return false;
        },
        child: AlertDialog(
          backgroundColor: const Color(0xFF1C1F24),
          title: const Text(
            'Select Next Bowler',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentBowler != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Note: ${_getBowlerNameById(currentBowler!.bowlerId)} cannot bowl consecutive overs',
                      style: const TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allAvailableBowlers.length,
                    itemBuilder: (context, index) {
                      final bowlerData = allAvailableBowlers[index];
                      return ListTile(
                        title: Text(
                          bowlerData['name'],
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          bowlerData['stats'],
                          style: TextStyle(
                            color: bowlerData['type'] == 'new'
                                ? const Color(0xFF6D7CFF)
                                : const Color(0xFF8F9499),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _selectBowler(bowlerData);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get bowler name by ID
  String _getBowlerNameById(String bowlerId) {
    final bowler = Bowler.getByBowlerId(bowlerId);
    if (bowler != null) {
      final player = TeamMember.getByPlayerId(bowler.playerId);
      return player?.teamName ?? 'Unknown';
    }
    return 'Unknown';
  }

  void _selectBowler(Map<String, dynamic> bowlerData) {
    setState(() {
      if (bowlerData['type'] == 'existing') {
        // Select existing bowler
        lastOverBowlerId = currentBowler?.bowlerId;
        currentBowler = bowlerData['bowler'];
        currentScore!.currentBowlerId = currentBowler!.bowlerId;
      } else {
        // ── FIX 3: pass tournamentId + matchId from currentInnings ──
        final player = bowlerData['player'];
        final newBowler = Bowler.create(
          inningsId: currentInnings!.inningsId,
          teamId: currentInnings!.bowlingTeamId,
          playerName: player.playerName,
          playerId: player.playerId,
          tournamentId: currentInnings!.tournamentId,
          matchId: currentInnings!.matchId,
          createdBy: currentMatch!.createdBy,
        );
        lastOverBowlerId = currentBowler?.bowlerId;
        currentBowler = newBowler;
        currentScore!.currentBowlerId = newBowler.bowlerId;
      }
      runsInCurrentOver = 0;
      currentScore!.save();
    });

    // 🔥 ADD THIS - UPDATE LED IMMEDIATELY WHEN BOWLER CHANGES
    Future.delayed(const Duration(milliseconds: 100), () {
      _updateLEDAfterScore();
    });
  }

  bool _isInningsComplete() {
    if (currentMatch == null || currentScore == null) return false;
    int totalBalls = currentMatch!.overs * 6;
    return currentScore!.currentBall >= totalBalls;
  }

  void _endInnings() {
    if (currentInnings == null || currentScore == null) return;

    currentInnings!.markCompleted();

    if (currentInnings!.isSecondInnings) {
      final firstInnings = Innings.getFirstInnings(widget.matchId);

      if (firstInnings != null) {
        final firstInningsScore = Score.getByInningsId(firstInnings.inningsId);
        if (firstInningsScore != null && currentInnings!.hasValidTarget) {
          try {
            // 🔥 CLEAR LED BEFORE SHOWING RESULT DIALOGS
            Future.delayed(const Duration(milliseconds: 100), () {
              _clearLEDDisplay();
            });

            // 🔥 FIX: Check scores directly, not using hasMetTarget
            // CHECK FOR TIE FIRST
            if (currentScore!.totalRuns == firstInningsScore.totalRuns) {
              _showMatchTiedDialog(firstInningsScore);
              return;
            }
            // CHECK IF TEAM B WON (met or exceeded target)
            else if (currentScore!.totalRuns >= currentInnings!.targetRuns) {
              _showVictoryDialog(true, firstInningsScore);
              return;
            }
            // TEAM A WON (Team B didn't reach target)
            else {
              _showVictoryDialog(false, firstInningsScore);
              return;
            }
          } catch (e) {
            print('Error checking target: $e');
          }
        }
      }
  } else {
      // First innings complete
      setState(() => _firstInningsLocked = true);
      final teamMembers = TeamMember.getByTeamId(currentInnings!.battingTeamId);
      final totalTeamMembers = teamMembers.length;
      bool wasAllOut = currentScore!.wickets >= totalTeamMembers - 1;

      String message = wasAllOut
          ? '🏏 All Out! Team scored ${currentScore!.totalRuns} runs in ${currentScore!.overs.toStringAsFixed(1)} overs (${currentScore!.wickets}/${totalTeamMembers - 1} wickets)'
          : '⏱️ Innings Complete! Team scored ${currentScore!.totalRuns}/${currentScore!.wickets} in ${currentScore!.overs.toStringAsFixed(1)} overs';
int targetRuns = currentScore!.totalRuns + 1;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1C1F24),
            title: Text(
              wasAllOut ? 'All Out!' : 'First Innings Complete',
              style: const TextStyle(color: Colors.white),
            ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(color: Color(0xFF9AA0A6))),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0f0f1e),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF9800), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Second Innings Target',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target:',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Text(
                          '$targetRuns runs',
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D7CFF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _startSecondInnings();
              },
            child: const Text(
                'Start Second Innings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        ),
      );
      return;
    }
  }

  void _startSecondInnings() async {
    try {
      if (currentMatch == null ||
          currentInnings == null ||
          currentScore == null) {
        throw Exception('Match data not available');
      }

      // ── FIX 4: pass tournamentId derived from currentMatch ──
      final secondInnings = Innings.createSecondInnings(
        matchId: widget.matchId,
        battingTeamId:
            currentInnings!.bowlingTeamId, // Previous bowling team now bats
        bowlingTeamId:
            currentInnings!.battingTeamId, // Previous batting team now bowls
        firstInningsScore: currentScore!.totalRuns, // First innings total score
        tournamentId: currentMatch!.tournamentId,
        createdBy: currentMatch!.createdBy,
      );

      // Show dialog to select opening batsmen for second innings
      _showSelectOpeningBatsmenDialog(secondInnings);
    } catch (e) {
      _showErrorDialog('Error starting second innings: $e');
      print('Error in _startSecondInnings: $e');
    }
  }

  void _showSelectOpeningBatsmenDialog(Innings secondInnings) {
    // Get players from the NEW batting team (was bowling in first innings)
    final battingTeamPlayers = TeamMember.getByTeamId(
      secondInnings.battingTeamId,
    );

    if (battingTeamPlayers.isEmpty) {
      _showErrorDialog('No players found for batting team!');
      return;
    }

    // Get all batsmen who have already played in ANY innings of this match
    final allMatchInnings = [
      Innings.getFirstInnings(widget.matchId),
      secondInnings,
    ].whereType<Innings>().toList();

    // Collect all player IDs who have batted in any innings for this team
    Set<String> playersWhoBattedInMatch = {};
    for (final innings in allMatchInnings) {
      if (innings.battingTeamId == secondInnings.battingTeamId) {
        final batsmenInInnings = Batsman.getByInningsAndTeam(
          innings.inningsId,
          secondInnings.battingTeamId,
        );
        playersWhoBattedInMatch.addAll(batsmenInInnings.map((b) => b.playerId));
      }
    }

    // Filter available players - only those who haven't batted yet
    final availablePlayers = battingTeamPlayers
        .where((p) => !playersWhoBattedInMatch.contains(p.playerId))
        .toList();

    if (availablePlayers.isEmpty) {
      _showErrorDialog(
        'No available players for second innings! All players have already batted.',
      );
      return;
    }

    String? selectedStriker;
    String? selectedNonStriker;
    String? selectedBowler;

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final bowlingTeamPlayers = TeamMember.getByTeamId(
              secondInnings.bowlingTeamId,
            );

            return AlertDialog(
              backgroundColor: const Color(0xFF1C1F24),
            title: const Text(
              'Select Opening Players for Innings 2',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target: ${secondInnings.targetRuns} runs',
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Striker selection
                  const Text(
                    'Striker:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedStriker,
                    hint: const Text(
                      'Select Striker',
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: const Color(0xFF1C1F24),
                    items: availablePlayers
                        .where((p) => p.playerId != selectedNonStriker)
                        .map(
                          (player) => DropdownMenuItem(
                            value: player.playerId,
                           child: Text(
                              player.teamName,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStriker = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Non-striker selection
                  const Text(
                    'Non-Striker:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedNonStriker,
                    hint: const Text(
                      'Select Non-Striker',
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: const Color(0xFF1C1F24),
                    items: availablePlayers
                        .where((p) => p.playerId != selectedStriker)
                        .map(
                          (player) => DropdownMenuItem(
                            value: player.playerId,
                            child: Text(
                              player.teamName,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedNonStriker = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bowler selection
                  const Text(
                    'Opening Bowler:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedBowler,
                    hint: const Text(
                      'Select Bowler',
                      style: TextStyle(color: Colors.white54),
                    ),
                    dropdownColor: const Color(0xFF1C1F24),
                    items: bowlingTeamPlayers
                        .map(
                          (player) => DropdownMenuItem(
                            value: player.playerId,
                            child: Text(
                              player.teamName,  
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBowler = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
          TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to home
                  setState(() => _firstInningsLocked = false);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF9AA0A6)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D7CFF),
                ),
                onPressed:
                    selectedStriker != null &&
                        selectedNonStriker != null &&
                        selectedBowler != null
                    ? () {
                        Navigator.of(context).pop();
                        _finalizeSecondInnings(
                          secondInnings,
                          selectedStriker!,
                          selectedNonStriker!,
                          selectedBowler!,
                        );
                      }
                    : null,
            child: const Text(
                    'Start Innings',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

 void _finalizeSecondInnings(
    Innings secondInnings,
    String strikerId,
    String nonStrikerId,
    String bowlerId,
  ) async {
    try {
      final strikerMember = TeamMember.getByPlayerId(strikerId);
      final nonStrikerMember = TeamMember.getByPlayerId(nonStrikerId);
      final bowlerMember = TeamMember.getByPlayerId(bowlerId);

      // Create batsmen for second innings
      final striker = Batsman.create(
        inningsId: secondInnings.inningsId,
        teamId: secondInnings.battingTeamId,
        playerId: strikerId,
        playerName: strikerMember?.playerName ?? 'Unknown',
        tournamentId: secondInnings.tournamentId,
        matchId: secondInnings.matchId,
        createdBy: currentMatch!.createdBy,
      );

      final nonStriker = Batsman.create(
        inningsId: secondInnings.inningsId,
        teamId: secondInnings.battingTeamId,
        playerId: nonStrikerId,
        playerName: nonStrikerMember?.playerName ?? 'Unknown',
        tournamentId: secondInnings.tournamentId,
        matchId: secondInnings.matchId,
        createdBy: currentMatch!.createdBy,
      );

      // Create bowler for second innings
      final bowler = Bowler.create(
        inningsId: secondInnings.inningsId,
        teamId: secondInnings.bowlingTeamId,
        playerId: bowlerId,
        playerName: bowlerMember?.playerName ?? 'Unknown',
        tournamentId: secondInnings.tournamentId,
        matchId: secondInnings.matchId,
        createdBy: currentMatch!.createdBy,
      );

      // Navigate to the same screen with new innings data
  Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CricketScorerScreen(
            matchId: widget.matchId,
            inningsId: secondInnings.inningsId,
            strikeBatsmanId: striker.batId,
            nonStrikeBatsmanId: nonStriker.batId,
            bowlerId: bowler.bowlerId,
            tournamentMatchDocId: widget.tournamentMatchDocId,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error finalizing second innings: $e');
      print('Error in _finalizeSecondInnings: $e');
    }
  }

  void _showAllOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text('All Out!', style: TextStyle(color: Colors.white)),
        content: Text(
          'Team is all out for ${currentScore?.totalRuns ?? 0} runs in ${currentScore?.overs ?? 0} overs',
          style: const TextStyle(color: Color(0xFF9AA0A6)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              setState(() => _firstInningsLocked = false);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF6D7CFF))),
          ),
        ],
      ),
    );
  }

  void toggleExtrasOptions() {
    setState(() => showExtrasOptions = !showExtrasOptions);
  }

  void toggleNoBall() {
    if (!noBallEnabled) return;
    setState(() {
      isNoBall = !isNoBall;
      if (isNoBall) isWide = false;
    });
  }

  void toggleWide() {
    if (!wideEnabled) return;
    setState(() {
      isWide = !isWide;
      if (isWide) isNoBall = false;
    });
  }

  void toggleByes() {
    setState(() => isByes = !isByes);
  }

  void swapPlayers() {
    setState(() {
      // Perform the strike switch
      _switchStrike();

      // Save the updated score
      currentScore?.save();
    });

    // 🔥 UPDATE LED IMMEDIATELY AFTER SWAP
    _updateLEDAfterScore();

    // Show brief feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Players swapped ✓'),
        duration: Duration(milliseconds: 800),
        backgroundColor: Color(0xFF6D7CFF),
      ),
    );
  }

  void undoLastBall() {
    if (actionHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No action to undo'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text(
          'Confirm Undo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to undo the last ${actionHistory.last['type']}?',
          style: const TextStyle(color: Color(0xFF9AA0A6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9AA0A6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performUndo();
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Color(0xFF6D7CFF)),
            ),
          ),
        ],
      ),
    );
  }

  void _performUndo() {
    if (actionHistory.isEmpty || currentScore == null) return;

    setState(() {
      Map<String, dynamic> lastAction = actionHistory.removeLast();
      String actionType = lastAction['type'];

      if (actionType == 'runs') {
        final strikerBatId = lastAction['strikeBatsmanId'];

        final strikerBat = Batsman.getByBatId(strikerBatId);
        if (strikerBat != null) {
          strikerBat.runs = lastAction['batsmanRuns'];
          strikerBat.ballsFaced = lastAction['batsmanBalls'];
          strikerBat.fours = lastAction['batsmanFours'];
          strikerBat.sixes = lastAction['batsmanSixes'];
          strikerBat.dotBalls = lastAction['batsmanDotBalls'];
          strikerBat.extras = lastAction['batsmanExtras'];
          strikerBat.strikeRate = strikerBat.ballsFaced > 0
              ? (strikerBat.runs / strikerBat.ballsFaced) * 100
              : 0.0;
          strikerBat.save();
        }

        strikeBatsman = Batsman.getByBatId(strikerBatId);
        nonStrikeBatsman = Batsman.getByBatId(lastAction['nonStrikeBatsmanId']);

        // Restore bowler state
        if (currentBowler != null) {
          currentBowler!.runsConceded = lastAction['bowlerRuns'];
          currentBowler!.balls = lastAction['bowlerBalls'];
          currentBowler!.wickets = lastAction['bowlerWickets'];
          currentBowler!.maidens = lastAction['bowlerMaidens'];
          currentBowler!.extras = lastAction['bowlerExtras'];

          int completedOvers = currentBowler!.balls ~/ 6;
          int remainingBalls = currentBowler!.balls % 6;
          currentBowler!.overs = completedOvers + (remainingBalls / 10.0);

          double totalOvers = completedOvers + (remainingBalls / 6.0);
          currentBowler!.economy = totalOvers > 0
              ? (currentBowler!.runsConceded / totalOvers)
              : 0.0;

          currentBowler!.save();
          currentBowler = Bowler.getByBowlerId(currentBowler!.bowlerId);
        }

        if (lastAction.containsKey('byes'))
          currentScore!.byes = lastAction['byes'];
        if (lastAction.containsKey('wides'))
          currentScore!.wides = lastAction['wides'];
        if (lastAction.containsKey('noBalls'))
          currentScore!.noBalls = lastAction['noBalls'];

        currentScore!.totalRuns = lastAction['totalRuns'];
        currentScore!.currentBall = lastAction['currentBall'];
        currentScore!.overs = lastAction['overs'];
        currentScore!.currentOver = List<String>.from(
          lastAction['currentOver'],
        );
        currentScore!.crr = currentScore!.overs > 0
            ? (currentScore!.totalRuns / currentScore!.overs)
            : 0.0;

        if (lastAction.containsKey('runsInCurrentOver')) {
          runsInCurrentOver = lastAction['runsInCurrentOver'];
        }

        isNoBall = false;
        isWide = false;
        isByes = false;
      } else if (actionType == 'wicket') {
        final strikerBatId = lastAction['strikeBatsmanId'];
        final nonStrikerBatId = lastAction['nonStrikeBatsmanId'];

        final batsman = Batsman.getByBatId(strikerBatId);
        if (batsman != null) {
          batsman.isOut = lastAction['batsmanIsOut'];
          batsman.bowlerIdWhoGotWicket =
              lastAction['batsmanBowlerWhoGotWicket'];
          batsman.dismissalType = lastAction['batsmanDismissalType'];
          batsman.fielderIdWhoRanOut = lastAction['batsmanFielderId'];
          batsman.extras = lastAction['batsmanExtras'];
          batsman.runs = lastAction['batsmanRuns'] ?? batsman.runs;
          batsman.ballsFaced = lastAction['batsmanBalls'] ?? batsman.ballsFaced;
          batsman.fours = lastAction['batsmanFours'] ?? batsman.fours;
          batsman.sixes = lastAction['batsmanSixes'] ?? batsman.sixes;
          batsman.dotBalls = lastAction['batsmanDotBalls'] ?? batsman.dotBalls;
          batsman.strikeRate = batsman.ballsFaced > 0
              ? (batsman.runs / batsman.ballsFaced) * 100
              : 0.0;
          batsman.save();
        }

        strikeBatsman = Batsman.getByBatId(strikerBatId);
        nonStrikeBatsman = Batsman.getByBatId(nonStrikerBatId);

        if (lastAction.containsKey('scoreStrikeBatsmanId')) {
          currentScore!.strikeBatsmanId = lastAction['scoreStrikeBatsmanId'];
        }
        if (lastAction.containsKey('scoreNonStrikeBatsmanId')) {
          currentScore!.nonStrikeBatsmanId =
              lastAction['scoreNonStrikeBatsmanId'];
        }

        if (currentBowler != null) {
          currentBowler!.wickets = lastAction['bowlerWickets'];
          currentBowler!.balls = lastAction['bowlerBalls'];
          currentBowler!.runsConceded = lastAction['bowlerRuns'];
          currentBowler!.maidens = lastAction['bowlerMaidens'];
          currentBowler!.extras = lastAction['bowlerExtras'];

          int completedOvers = currentBowler!.balls ~/ 6;
          int remainingBalls = currentBowler!.balls % 6;
          currentBowler!.overs = completedOvers + (remainingBalls / 10.0);

          double totalOvers = completedOvers + (remainingBalls / 6.0);
          currentBowler!.economy = totalOvers > 0
              ? (currentBowler!.runsConceded / totalOvers)
              : 0.0;

          currentBowler!.save();
          currentBowler = Bowler.getByBowlerId(currentBowler!.bowlerId);
        }

        if (lastAction.containsKey('byes'))
          currentScore!.byes = lastAction['byes'];
        if (lastAction.containsKey('wides'))
          currentScore!.wides = lastAction['wides'];
        if (lastAction.containsKey('noBalls'))
          currentScore!.noBalls = lastAction['noBalls'];

        currentScore!.wickets = lastAction['wickets'];
        currentScore!.currentBall = lastAction['currentBall'];

        if (lastAction.containsKey('overs')) {
          currentScore!.overs = lastAction['overs'];
        }

        currentScore!.currentOver = List<String>.from(
          lastAction['currentOver'],
        );
        currentScore!.crr = currentScore!.overs > 0
            ? (currentScore!.totalRuns / currentScore!.overs)
            : 0.0;

        if (lastAction.containsKey('runsInCurrentOver')) {
          runsInCurrentOver = lastAction['runsInCurrentOver'];
        }

        if (lastAction.containsKey('newBatsmanBatId')) {
          _cancelledBatsmanIds.add(lastAction['newBatsmanBatId'] as String);
          debugPrint(
            '↩️ Undo wicket: cancelled new batsman ${lastAction['newBatsmanBatId']}',
          );
        }
      } else if (actionType == 'runout') {
        final strikerBatId = lastAction['strikeBatsmanId'];
        final strikerBat = Batsman.getByBatId(strikerBatId);
        if (strikerBat != null) {
          strikerBat.runs = lastAction['strikerRuns'];
          strikerBat.ballsFaced = lastAction['strikerBalls'];
          strikerBat.fours = lastAction['strikerFours'];
          strikerBat.sixes = lastAction['strikerSixes'];
          strikerBat.dotBalls = lastAction['strikerDotBalls'];
          strikerBat.extras = lastAction['strikerExtras'];
          strikerBat.strikeRate = strikerBat.ballsFaced > 0
              ? (strikerBat.runs / strikerBat.ballsFaced) * 100
              : 0.0;
          strikerBat.save();
        }

        final runoutBatId = lastAction['runoutBatsmanId'];
        final runoutBat = Batsman.getByBatId(runoutBatId);
        if (runoutBat != null) {
          runoutBat.isOut = lastAction['runoutBatsmanIsOut'];
          runoutBat.dismissalType = lastAction['runoutBatsmanDismissalType'];
          runoutBat.fielderIdWhoRanOut = lastAction['runoutBatsmanFielderId'];
          runoutBat.save();
        }

        strikeBatsman = Batsman.getByBatId(strikerBatId);
        nonStrikeBatsman = Batsman.getByBatId(lastAction['nonStrikeBatsmanId']);

        // ✅ Fix: restore score's internal batsman ID pointers
        if (lastAction.containsKey('scoreStrikeBatsmanId')) {
          currentScore!.strikeBatsmanId = lastAction['scoreStrikeBatsmanId'];
        }
        if (lastAction.containsKey('scoreNonStrikeBatsmanId')) {
          currentScore!.nonStrikeBatsmanId =
              lastAction['scoreNonStrikeBatsmanId'];
        }

        if (currentBowler != null) {
          currentBowler!.runsConceded = lastAction['bowlerRuns'];
          currentBowler!.balls = lastAction['bowlerBalls'];
          currentBowler!.wickets = lastAction['bowlerWickets'];
          currentBowler!.maidens = lastAction['bowlerMaidens'];
          currentBowler!.extras = lastAction['bowlerExtras'];

          int completedOvers = currentBowler!.balls ~/ 6;
          int remainingBalls = currentBowler!.balls % 6;
          currentBowler!.overs = completedOvers + (remainingBalls / 10.0);

          double totalOvers = completedOvers + (remainingBalls / 6.0);
          currentBowler!.economy = totalOvers > 0
              ? (currentBowler!.runsConceded / totalOvers)
              : 0.0;

          currentBowler!.save();
          currentBowler = Bowler.getByBowlerId(currentBowler!.bowlerId);
        }

        currentScore!.totalRuns = lastAction['totalRuns'];
        currentScore!.wickets = lastAction['wickets'];
        currentScore!.currentBall = lastAction['currentBall'];
        currentScore!.overs = lastAction['overs'];
        currentScore!.currentOver = List<String>.from(
          lastAction['currentOver'],
        );
        currentScore!.crr = currentScore!.overs > 0
            ? (currentScore!.totalRuns / currentScore!.overs)
            : 0.0;

        if (lastAction.containsKey('runsInCurrentOver')) {
          runsInCurrentOver = lastAction['runsInCurrentOver'];
        }

        // ✅ Fix: cancel new batsman record so they reappear in dropdown after undo
        if (lastAction.containsKey('newBatsmanBatId')) {
          _cancelledBatsmanIds.add(lastAction['newBatsmanBatId'] as String);
          debugPrint(
            '↩️ Undo runout: cancelled new batsman ${lastAction['newBatsmanBatId']}',
          );
        }

        isRunout = false;
        pendingRunoutRuns = null;
        runoutBatsmanId = null;
      }

      currentScore!.save();

      // 🔥 Force star to re-evaluate its position after undo
      _lastRow74WasStriker = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action undone successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    });

    // 🔥 Update LED OUTSIDE setState so it runs after state is fully committed
    _updateLEDAfterScore();
  }

  Future<void> _updateLEDAfterScore() async {
    if (_ledCancelled) return;
    _enqueueLEDUpdate(_doLEDAfterScore);
    // Sync live score to Firestore for tournament Stats tab
    _syncLiveScoreToFirestore();
  }

  Future<void> _doLEDAfterScore() async {
    if (_ledCancelled) return; // Check at entry point
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping LED update.');
        return;
      }

      if (strikeBatsman == null ||
          nonStrikeBatsman == null ||
          currentBowler == null ||
          currentScore == null) {
        debugPrint('⚠️ Null data — skipping LED update.');
        return;
      }

      if (_ledCancelled) return; // Check before sending

      debugPrint('📤 Updating LED score (targeted)...');

      final strikerPlayer = TeamMember.getByPlayerId(strikeBatsman!.playerId);
      final nonStrikerPlayer = TeamMember.getByPlayerId(
        nonStrikeBatsman!.playerId,
      );
      final bowlerPlayer = TeamMember.getByPlayerId(currentBowler!.playerId);

      String trunc(String? name, int max) {
        final n = name ?? '';
        return (n.length > max ? n.substring(0, max) : n).toUpperCase();
      }

      final runs = currentScore!.totalRuns.toString();
      final wickets = currentScore!.wickets.toString();
      final overs = currentScore!.overs.toStringAsFixed(1);
      final crr = currentScore!.crr.toStringAsFixed(2);
      final bowlerWkts = currentBowler!.wickets.toString();
      final bowlerRuns = currentBowler!.runsConceded.toString();
      final bowlerOvers = currentBowler!.overs.toStringAsFixed(1);
      final bowlerName = trunc(
        bowlerPlayer?.teamName,
        7,
      ).padRight(7).substring(0, 7);

      final row74IsStriker = strikeBatsman!.playerId == _row74PlayerId;
      final row74Player = row74IsStriker ? strikerPlayer : nonStrikerPlayer;
      final row84Player = row74IsStriker ? nonStrikerPlayer : strikerPlayer;
      final row74Bat = row74IsStriker ? strikeBatsman! : nonStrikeBatsman!;
      final row84Bat = row74IsStriker ? nonStrikeBatsman! : strikeBatsman!;

      final row74Name = trunc(row74Player?.teamName, 7);
      final row84Name = trunc(row84Player?.teamName, 7);
      final row74Runs = row74Bat.runs.toString();
      final row74Balls = row74Bat.ballsFaced.toString();
      final row84Runs = row84Bat.runs.toString();
      final row84Balls = row84Bat.ballsFaced.toString();

      final bool starMoved =
          _lastRow74WasStriker == null ||
          _lastRow74WasStriker != row74IsStriker;
      _lastRow74WasStriker = row74IsStriker;

      final int runsX = (78 - (runs.length * 10) ~/ 2).clamp(52, 90);

      if (_ledCancelled) return; // Final check before sending commands

      final List<String> allCommands = [
        'CHANGE 52  30 48 14 2 0 0 0 ',
        'CHANGE $runsX 30 ${runs.length * 12} 14 2 255 255 255 $runs',
        'CHANGE 112 30 16 14 2 255 255 255 $wickets',
        'CHANGE 29 50 30 10 1 255 255 0 $crr',
        'CHANGE 90 50 46 10 1 0 255 0 $overs(${currentMatch!.overs})',
        'CHANGE 10 60 42 10 1 0 0 0 ',
        'CHANGE 10 60 42 10 1 255 200 200 $bowlerName',
        'CHANGE 58 60 6  10 1 0 0 0 ',
        'CHANGE 58 60 6  10 1 0 255 0 $bowlerWkts',
        'CHANGE 74 60 18 10 1 0 0 0 ',
        'CHANGE 74 60 18 10 1 0 255 0 $bowlerRuns',
        'CHANGE 102 60 18 10 1 0 0 0 ',
        'CHANGE 102 60 18 10 1 0 255 0 $bowlerOvers',
        'CHANGE 8  74 48 10 1 200 255 255 $row74Name',
        'CHANGE 58 74 69 10 1 200 255 200 $row74Runs($row74Balls)',
        'CHANGE 8  84 48 10 1 200 200 255 $row84Name',
        'CHANGE 58 84 69 10 1 200 255 200 $row84Runs($row84Balls)',
      ];

      await bleService.sendRawCommands(allCommands);
      await Future.delayed(const Duration(milliseconds: 40));

      if (_ledCancelled) return; // Check before star update

      if (starMoved) {
        await Future.delayed(const Duration(milliseconds: 30));
        if (row74IsStriker) {
          await bleService.sendRawCommands([
            'CHANGE 2 84 6 10 1 0 0 0 *',
            'CHANGE 2 74 6 10 1 255 0 0 *',
          ]);
        } else {
          await bleService.sendRawCommands([
            'CHANGE 2 74 6 10 1 0 0 0 *',
            'CHANGE 2 84 6 10 1 255 0 0 *',
          ]);
        }
        await Future.delayed(const Duration(milliseconds: 30));
      }

      debugPrint('✅ LED updated — $runs/$wickets ($overs) CRR:$crr');
    } catch (e) {
      debugPrint('❌ _doLEDAfterScore failed: $e');
    }
  }

  Future<void> _updateLEDTimeAndTemp() async {
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping time/temp update.');
        return;
      }

      debugPrint('🕐 Updating time and temperature...');

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final temp = (_envService.currentTemperature ?? 27).round();
      final tempStr = temp.toString();

      debugPrint('📊 Time: $timeStr | Temp: ${tempStr}°C');

      // ✅ ATOMIC CHANGE COMMANDS (from Doc 1)
      const int timeX = 3;
      const int timeY = 2;
      const int timeWidth = 33;
      const int timeHeight = 10;

      const int tempStartX = 102;
      const int tempY = 2;
      const int tempWidth = 12;
      const int tempHeight = 10;

      final commands = [
        'CHANGE $timeX $timeY $timeWidth $timeHeight 1 255 255 200 $timeStr',
        'CHANGE $tempStartX $tempY $tempWidth $tempHeight 1 200 255 200 $tempStr',
      ];

      await bleService.sendRawCommands(commands);

      debugPrint('✅ Time: $timeStr, Temp: ${tempStr}°C updated on LED');
    } catch (e) {
      debugPrint('❌ Time/temp update failed: $e');
    }
  }

  Widget _buildHeader(double w) {
    return Row(
      children: [
        // Back arrow button with confirmation
        GestureDetector(
          onTap: _showLeaveMatchDialog,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: w * 0.07),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Cricket Scorer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Trending up icon (Statistics)
        IconButton(
          icon: const Icon(Icons.trending_up, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchGraphPage(
                  matchId: widget.matchId,
                  inningsId: widget.inningsId,
                ),
              ),
            );
          },
        ),
        // Scoreboard icon
        IconButton(
          icon: const Icon(Icons.scoreboard, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScoreboardPage(
                  matchId: widget.matchId,
                  inningsId: widget.inningsId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRunoutButton() {
    return GestureDetector(
      onTap: isMatchComplete
          ? null
          : () {
              setState(() {
                isRunout = !isRunout; // Toggle runout mode
                _isRunoutModeActive = isRunout; // Activate blur overlay
                if (isRunout) {
                  // Reset other extras when runout is activated
                  isNoBall = false;
                  isWide = false;
                  isByes = false;

                  // Scroll to focus on scorecard when runout is activated
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                }
              });
            },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isRunout
                ? [Color(0xFFFFD700), Color(0xFFFFA500)] // Active state
                : [Color(0xFFB8860B), Color(0xFFDAA520)], // Inactive state
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: isRunout
              ? Border.all(color: Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(isRunout ? 0.8 : 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            // Extra glow effect when runout mode is active
            if (_isRunoutModeActive)
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: const Center(
          child: Text(
            'RO',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _updateOverTracking() {
    if (currentScore == null) return;

    currentScore!.currentBall++;
    int completedOvers = currentScore!.currentBall ~/ 6;
    int ballsInCurrentOver = currentScore!.currentBall % 6;
    currentScore!.overs = completedOvers + (ballsInCurrentOver / 10.0);
  }

  /// Writes a single ball-by-ball event to Firestore for tournament matches.
/// Called from addRuns(), _applyWicket(), and _finalizeRunout() — the three
/// places that already build a `ballDisplay` string for currentScore!.currentOver.
///
/// Mirrors the over/ball-in-over math LiveScoreRepository.watchCurrentOverBalls
/// expects: overNumber/ballInOver are 0-indexed and derived from currentBall
/// AFTER _updateOverTracking() has incremented it for this delivery.
Future<void> _persistBallToFirestore({
  required String display,
  required int runs,
  bool isWicket = false,
  bool isWide = false,
  bool isNoBall = false,
  bool isBye = false,
  bool isLegBye = false,
}) async {
  try {
    if (currentInnings == null || currentScore == null) return;
    final tournamentId = currentInnings!.tournamentId;
    if (tournamentId.isEmpty || tournamentId == 'standalone') return;

    final matchSnap = await _resolveTournamentMatchDoc(tournamentId);
    if (matchSnap == null) return;

    final matchDocId = matchSnap.id;
    final inningsNumber = currentInnings!.isSecondInnings ? 2 : 1;
    final inningsDocId = 'innings_$inningsNumber';

    // currentBall has ALREADY been incremented by _updateOverTracking() for
    // legal deliveries by the time this is called from addRuns(). Wides/no-balls
    // don't call _updateOverTracking(), so currentBall still reflects the
    // CURRENT (not-yet-complete) over — which is correct: extras belong to
    // the over in progress, not the next one.
    final int totalBalls = currentScore!.currentBall;
    final int completedOvers = totalBalls ~/ 6;
    final int ballsInOver = totalBalls % 6;

    // For legal deliveries that just completed an over (ballsInOver == 0,
    // totalBalls > 0), the ball belongs to the over that just finished, not
    // the upcoming one — matches the same currentOverNumber logic already
    // used in LiveScoreScreen's _Col3BallTracker.
    final int overNumber = (ballsInOver == 0 && totalBalls > 0 && !isWide && !isNoBall)
        ? completedOvers - 1
        : completedOvers;
    final int ballInOver = (ballsInOver == 0 && totalBalls > 0 && !isWide && !isNoBall)
        ? 6
        : ballsInOver;

    final ball = Ball(
      ballId: const Uuid().v4(),
      inningsId: currentInnings!.inningsId,
      overNumber: overNumber,
      ballInOver: ballInOver,
      runs: runs,
      isWicket: isWicket,
      isWide: isWide,
      isNoBall: isNoBall,
      isBye: isBye,
      isLegBye: isLegBye,
      display: display,
    );

    await Ball.col(tournamentId, matchDocId, inningsDocId)
        .doc(ball.ballId)
        .set(ball.toMap());

    debugPrint('✅ Ball persisted: over=$overNumber ball=$ballInOver display=$display');
  } catch (e) {
    debugPrint('⚠️ Ball persist failed (non-critical): $e');
  }
}

  void _switchStrike() {
    if (currentScore == null) return;

    String temp = currentScore!.strikeBatsmanId;
    currentScore!.strikeBatsmanId = currentScore!.nonStrikeBatsmanId;
    currentScore!.nonStrikeBatsmanId = temp;

    Batsman? tempBat = strikeBatsman;
    strikeBatsman = nonStrikeBatsman;
    nonStrikeBatsman = tempBat;
  }

  void _resetCurrentOver() {
    if (currentScore == null) return;
    currentScore!.currentOver = [];
  }

  // Animation Builder - Choose animation based on type
  Widget _buildLottieAnimation(String assetPath) {
    if (assetPath.contains('Scored 4')) {
      return const BoundaryFourAnimation();
    } else if (assetPath.contains('SIX')) {
      return const BoundarySixAnimation();
    } else if (assetPath.contains('CRICKET OUT') || assetPath.contains('Out')) {
      return const WicketAnimation();
    } else if (assetPath.contains('Duck')) {
      return const DuckAnimation();
    } else if (assetPath == 'victory') {
      return const VictoryAnimation();
    } else if (assetPath == 'over') {
      return const BoundaryFourAnimation(); // Reuse 4 animation for over completion
    }

    // Fallback
    return const SizedBox.shrink();
  }

  // Lottie Animation Methods
  void _triggerBoundaryAnimation(String animationType) {
    setState(() {
      _boundaryAnimationType = animationType; // '4' or '6'
      _showBoundaryAnimation = true;
    });

    // Auto-hide after animation completes (1200ms)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showBoundaryAnimation = false;
        });
      }
    });
  }

  void _triggerWicketAnimation() {
    setState(() {
      _showWicketAnimation = true;
    });

    // Show animation for 3 seconds before showing dialog
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWicketAnimation = false;
        });
      }
    });
  }

  void _triggerDuckAnimation(String batsmanId) {
    setState(() {
      _lastDuckBatsman = batsmanId;
      _showDuckAnimation = true;
    });

    // Auto-hide after animation completes (1000ms)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showDuckAnimation = false;
        });
      }
    });
  }

  void _triggerVictoryAnimation() {
    setState(() {
      _showVictoryAnimation = true;
    });

    // Show animation for 2 seconds before showing victory dialog
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showVictoryAnimation = false;
        });
      }
    });
  }

  void _triggerRunoutHighlight(String batsmanId) {
    setState(() {
      _showRunoutHighlight = true;
      _runoutHighlightIndex = 0;
    });

    // Cycle through highlight indices 0-6
    int cycleCount = 0;
    const int totalCycles = 7;
    const Duration cycleDuration = Duration(milliseconds: 150);

    Future.doWhile(() async {
      await Future.delayed(cycleDuration);
      if (mounted && cycleCount < totalCycles) {
        setState(() {
          _runoutHighlightIndex = cycleCount;
        });
        cycleCount++;
        return true;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          _showRunoutHighlight = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: Appbg1.mainGradient),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6D7CFF)),
          ),
        ),
      );
    }

    if (currentScore == null ||
        strikeBatsman == null ||
        nonStrikeBatsman == null ||
        currentBowler == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: Appbg1.mainGradient),
          child: const Center(
            child: Text(
              'Error loading match data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final strikerPlayer = TeamMember.getByPlayerId(strikeBatsman!.playerId);
    final nonStrikerPlayer = TeamMember.getByPlayerId(
      nonStrikeBatsman!.playerId,
    );
    final bowlerPlayer = TeamMember.getByPlayerId(currentBowler!.playerId);

    return WillPopScope(
      onWillPop: () async {
        _showLeaveMatchDialog();
        return false; // Prevents automatic pop
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: Appbg1.mainGradient),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar - FIXED: Only one header now
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildHeader(MediaQuery.of(context).size.width),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // Main Score Card
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1F24),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Target display for second innings
                                  if (currentInnings != null &&
                                      currentInnings!.isSecondInnings &&
                                      currentInnings!.hasValidTarget)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: Appbg1.mainGradient,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _getTargetBannerColor(),
                                          width: 2,
                                        ),
                                      ),
                                      child: _buildTargetBannerContent(),
                                    ),
           Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _getBattingTeamName(),
                                                style: const TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                              ),
                                            ),
                                            Text(
                                              'CRR : ${currentScore!.crr.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFF9AA0A6),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${currentScore!.totalRuns}-${currentScore!.wickets}',
                                              style: const TextStyle(
                                                color: Color(0xFFFFFFFF),
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '(${currentScore!.overs.toStringAsFixed(1)})',
                                              style: const TextStyle(
                                                color: Color(0xFF9AA0A6),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Batsmen Stats
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: Appbg1.mainGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6D7CFF),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Batsman',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          'R',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          'B',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          '4s',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          '6s',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 50,
                                        child: Text(
                                          'SR',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 1.5,
                                    color: const Color(0xFF4D4D4D),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.circle,
                                              color: Color(0xFF6D7CFF),
                                              size: 6,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                strikerPlayer?.teamName ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${strikeBatsman!.runs}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${strikeBatsman!.ballsFaced}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${strikeBatsman!.fours}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${strikeBatsman!.sixes}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          '${strikeBatsman!.strikeRate.toStringAsFixed(0)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                          ),
                                          child: Text(
                                            nonStrikerPlayer?.teamName ??
                                                'Unknown',
                                            style: const TextStyle(
                                              color: Color(0xFFCCCCCC),
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${nonStrikeBatsman!.runs}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${nonStrikeBatsman!.ballsFaced}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${nonStrikeBatsman!.fours}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${nonStrikeBatsman!.sixes}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          '${nonStrikeBatsman!.strikeRate.toStringAsFixed(0)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Bowler Stats
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: Appbg1.mainGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6D7CFF),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Bowler',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          'O',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          'M',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          'R',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                        child: Text(
                                          'W',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 45,
                                        child: Text(
                                          'ER',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 1.5,
                                    color: const Color(0xFF4D4D4D),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bowlerPlayer?.teamName ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${currentBowler!.overs.toStringAsFixed(1)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${currentBowler!.maidens}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${currentBowler!.runsConceded}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${currentBowler!.wickets}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 45,
                                        child: Text(
                                          '${currentBowler!.economy.toStringAsFixed(1)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFCCCCCC),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Current Over
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1F25),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'OVER',
                                    style: TextStyle(
                                      color: Color(0xFF7A7F85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                               Expanded(
                                    child: currentScore!.currentOver.isEmpty
                                        ? const Text(
                                            'Waiting for delivery...',
                                            style: TextStyle(
                                              color: Color(0xFF7A7F85),
                                              fontSize: 12,
                                            ),
                                          )
                                        // Fixed-height horizontal scroller — balls beyond
                                        // what fits on screen scroll right instead of
                                        // wrapping to a new row (Wrap's default behavior).
                                        : SizedBox(
                                            height: 32,
                                            child: ScrollConfiguration(
                                              behavior: ScrollConfiguration.of(
                                                context,
                                              ).copyWith(scrollbars: true),
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: currentScore!
                                                      .currentOver
                                                      .map((ball) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            right: 8,
                                                          ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  _getBallColor(
                                                                ball,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                6,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              ball,
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                      .toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Extras Options (if shown)
                            if (showExtrasOptions)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF20242A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildExtrasButton(
                                        'No Ball',
                                        isNoBall,
                                        toggleNoBall,
                                        enabled: noBallEnabled,
                                      ),
                                      _buildExtrasButton(
                                        'Wide',
                                        isWide,
                                        toggleWide,
                                        enabled: wideEnabled,
                                      ),
                                      _buildExtrasButton(
                                        'Byes',
                                        isByes,
                                        toggleByes,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            if (showExtrasOptions) const SizedBox(height: 16),

                            // Run Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildRunButton('4', 4),
                                  _buildRunButton('3', 3),
                                  _buildRunButton('1', 1),
                                  _buildRunButton('0', 0),
                                  _buildRunButton('2', 2),
                                  _buildRunButton('5', 5),
                                  _buildRunButton('6', 6),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Action Buttons Row
                            // Action Buttons Row - UPDATED WITH SWAP BUTTON
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Extras button
                                  GestureDetector(
                                    onTap: toggleExtrasOptions,
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Color(0xFF000000),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Wicket button
                                  _buildWicketButton(),

                                  // Swap button - NEW
                                  GestureDetector(
                                    onTap: swapPlayers,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00BCD4),
                                            Color(0xFF0097A7),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00BCD4,
                                            ).withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.swap_horiz,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Runout button
                                  _buildRunoutButton(),

                                  // Undo button
                                  GestureDetector(
                                    onTap: undoLastBall,
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                          // Glow effect when runout mode is active
                                          if (_isRunoutModeActive)
                                            BoxShadow(
                                              color: const Color(
                                                0xFFFFD700,
                                              ).withValues(alpha: 0.8),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 0),
                                            ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.undo,
                                          color: Color(0xFF333333),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Lottie Animation Overlays with Error Handling
            if (_showBoundaryAnimation)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: _buildLottieAnimation(
                          _boundaryAnimationType == '4'
                              ? 'assets/images/Scored 4.lottie'
                              : 'assets/images/SIX ANIMATION.lottie',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_showWicketAnimation)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: _buildLottieAnimation(
                        'assets/images/CRICKET OUT ANIMATION.lottie',
                      ),
                    ),
                  ),
                ),
              ),
            if (_showDuckAnimation)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: _buildLottieAnimation(
                        'assets/images/Duck Out.lottie',
                      ),
                    ),
                  ),
                ),
              ),
            // Victory Animation Overlay
            if (_showVictoryAnimation)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: _buildLottieAnimation('victory'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton(String label, int value) {
    // Special styling for 4 and 6 buttons
    bool isBoundaryButton = (value == 4 || value == 6);

    return GestureDetector(
      onTap: isMatchComplete ? null : () => addRuns(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isBoundaryButton ? 56 : 50,
        height: isBoundaryButton ? 71 : 65,
        decoration: BoxDecoration(
          // Different gradients for boundary buttons (4 and 6)
          gradient: isMatchComplete
              ? const LinearGradient(
                  colors: [
                    Color(0xFF666666),
                    Color(0xFF555555),
                    Color(0xFF444444),
                  ], // Gray for disabled
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : (value == 4
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF26C6DA),
                          Color(0xFF00BCD4),
                          Color(0xFF0097A7),
                        ], // Soft teal/turquoise for 4
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : value == 6
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFCE93D8),
                          Color(0xFFBA68C8),
                          Color(0xFFAB47BC),
                        ], // Soft lavender/purple for 6
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFF6D7CFF),
                          Color(0xFF2D3DFF),
                        ], // White to blue gradient for others
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isMatchComplete
                  ? Colors.black.withValues(alpha: 0.3)
                  : (isBoundaryButton
                        ? (value == 4
                                  ? const Color(0xFF26C6DA)
                                  : const Color(0xFFCE93D8))
                              .withValues(alpha: 0.6)
                        : const Color(0xFF6D7CFF).withValues(alpha: 0.4)),
              blurRadius: isBoundaryButton ? 15 : 10,
              spreadRadius: isBoundaryButton ? 3 : 2,
              offset: const Offset(0, 4),
            ),
            // Glow effect when runout mode is active
            if (_isRunoutModeActive)
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
          ],
          border: Border.all(
            color: isMatchComplete
                ? Colors.grey.withValues(alpha: 0.3)
                : (_isRunoutModeActive
                      ? const Color(0xFFFFD700).withValues(
                          alpha: 0.9,
                        ) // Golden border when RO active
                      : (isBoundaryButton
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.3))),
            width: _isRunoutModeActive
                ? 3
                : (isBoundaryButton ? 2 : 1), // Thicker border in RO mode
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: isMatchComplete ? 0.5 : 1.0,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: isBoundaryButton ? 26 : 24,
                fontWeight: isBoundaryButton
                    ? FontWeight.w900
                    : FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: const Offset(1, 1),
                    blurRadius: isBoundaryButton ? 3 : 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWicketButton() {
    return GestureDetector(
      onTap: isMatchComplete ? null : addWicket,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B3B), Color(0xFFFF0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0000).withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
            // Glow effect when runout mode is active
            if (_isRunoutModeActive)
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: const Center(
          child: Text(
            'W',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtrasButton(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: (enabled && !isMatchComplete) ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: !enabled
              ? Colors.grey.withOpacity(0.3)
              : isActive
              ? const Color(0xFF6D7CFF)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !enabled
                ? Colors.grey
                : isActive
                ? const Color(0xFF6D7CFF)
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            // Glow effect when runout mode is active
            if (_isRunoutModeActive && !isMatchComplete)
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: !enabled ? Colors.grey : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getBallColor(String ball) {
    if (ball == 'W') return const Color(0xFFFF6B6B);
    if (ball == '4') return const Color(0xFF4CAF50);
    if (ball == '6') return const Color(0xFF2196F3);
    if (ball.startsWith('WD') || ball.startsWith('NB'))
      return const Color(0xFFFF9800);
    if (ball == '0') return const Color(0xFF666666);
    return const Color(0xFF555555);
  }
}
