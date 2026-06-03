import 'package:TURF_TOWN_/src/Pages/Teams/cricket_scorer_screen.dart';
import 'package:TURF_TOWN_/src/models/batsman.dart';
import 'package:TURF_TOWN_/src/models/bowler.dart';
import 'package:TURF_TOWN_/src/models/innings.dart';
import 'package:TURF_TOWN_/src/models/score.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:TURF_TOWN_/src/models/match_storage.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/models/player_storage.dart';
import 'package:TURF_TOWN_/src/Services/bluetooth_service.dart';

class SelectPlayersPage extends StatefulWidget {
  final String battingTeamName;
  final String bowlingTeamName;
  final int totalOvers;
  final String matchId;

  const SelectPlayersPage({
    super.key,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.totalOvers,
    required this.matchId,
  });

  @override
  State<SelectPlayersPage> createState() => _SelectPlayersPageState();
}

class _SelectPlayersPageState extends State<SelectPlayersPage> {
  String? selectedStriker;
  String? selectedNonStriker;
  String? selectedBowler;

  List<TeamMember> battingPlayers = [];
  List<TeamMember> bowlingPlayers = [];

  String? battingTeamId;
  String? bowlingTeamId;

  String? currentMatchId;

  String _tournamentId = '';

  bool isLoadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _loadMatchAndPlayers();
  }

  Future<void> _loadMatchAndPlayers() async {
    try {
      currentMatchId = widget.matchId;

      final currentMatch = MatchStorage.getByMatchId(currentMatchId!);
      if (currentMatch == null) {
        _showSnackBar('Match not found: $currentMatchId', Colors.red);
        setState(() => isLoadingPlayers = false);
        return;
      }

      _tournamentId = currentMatch.tournamentId;

      battingTeamId = currentMatch.getBattingTeamId();
      bowlingTeamId = currentMatch.getBowlingTeamId();

      debugPrint('✅ SelectPlayersPage: matchId=$currentMatchId | '
          'tournamentId=$_tournamentId | '
          'battingTeamId=$battingTeamId | bowlingTeamId=$bowlingTeamId');

      if (battingTeamId != null) {
        battingPlayers = PlayerStorage.getPlayersByTeam(battingTeamId!);
      }

      if (bowlingTeamId != null) {
        bowlingPlayers = PlayerStorage.getPlayersByTeam(bowlingTeamId!);
      }

      debugPrint('✅ Batting players: ${battingPlayers.length} | '
          'Bowling players: ${bowlingPlayers.length}');

      if (battingPlayers.isEmpty) {
        _showSnackBar('Batting team has no players!', Colors.orange);
      }

      if (bowlingPlayers.isEmpty) {
        _showSnackBar('Bowling team has no players!', Colors.orange);
      }

      setState(() => isLoadingPlayers = false);
    } catch (e) {
      _showSnackBar('Error loading players: $e', Colors.red);
      setState(() => isLoadingPlayers = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPlayerSelectionDialog(String playerType) {
    List<TeamMember> availablePlayers;
    String? currentSelection;

    switch (playerType) {
      case 'Striker':
      case 'Non-Striker':
        availablePlayers = battingPlayers;
        currentSelection =
            playerType == 'Striker' ? selectedStriker : selectedNonStriker;
        break;
      case 'Bowler':
        availablePlayers = bowlingPlayers;
        currentSelection = selectedBowler;
        break;
      default:
        return;
    }

    if (availablePlayers.isEmpty) {
      _showSnackBar('No players available for selection', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: Text(
          'Select $playerType',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availablePlayers.length,
            itemBuilder: (context, index) {
              final player = availablePlayers[index];
              final isSelected = player.playerId == currentSelection;

              bool isDisabled = false;
              String disabledReason = '';

              if (playerType == 'Striker' &&
                  player.playerId == selectedNonStriker) {
                isDisabled = true;
                disabledReason = 'Selected as Non-Striker';
              } else if (playerType == 'Non-Striker' &&
                  player.playerId == selectedStriker) {
                isDisabled = true;
                disabledReason = 'Selected as Striker';
              }

              return Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: ListTile(
                  enabled: !isDisabled,
                  title: Text(
                    player.playerName,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00C4FF)
                          : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  subtitle: isDisabled
                      ? Text(
                          disabledReason,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 11),
                        )
                       : null,
                  leading: Icon(
                    Icons.person,
                    color: isSelected
                        ? const Color(0xFF00C4FF)
                        : Colors.white70,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF00C4FF))
                      : null,
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            switch (playerType) {
                              case 'Striker':
                                selectedStriker = player.playerId;
                                break;
                              case 'Non-Striker':
                                selectedNonStriker = player.playerId;
                                break;
                              case 'Bowler':
                                selectedBowler = player.playerId;
                                break;
                            }
                          });
                          Navigator.pop(context);
                        },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF00C4FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToMatch() {
    if (selectedStriker == null ||
        selectedNonStriker == null ||
        selectedBowler == null) {
      _showSnackBar('Please select all players!', Colors.red);
      return;
    }

    if (selectedStriker == selectedNonStriker) {
      _showSnackBar(
          'Striker and Non-Striker cannot be the same!', Colors.red);
      return;
    }

    if (currentMatchId == null ||
        battingTeamId == null ||
        bowlingTeamId == null) {
      _showSnackBar('Match data not found!', Colors.red);
      return;
    }

    // ── CHANGE 1 ── Removed the isEmpty guard that blocked standalone matches.
    // The Innings/Batsman/Bowler/Score models already handle empty tournamentId
    // by routing writes to users/{uid}/matches/ instead of tournaments/...
    // So standalone matches (tournamentId == '') proceed correctly.

    final striker = TeamMember.getByPlayerId(selectedStriker!);
    final nonStriker = TeamMember.getByPlayerId(selectedNonStriker!);
    final bowler = TeamMember.getByPlayerId(selectedBowler!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text(
          'Confirm Players',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            const SizedBox(height: 12),
            Text(
              'Striker: ${striker?.playerName ?? "Unknown"}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Non-Striker: ${nonStriker?.playerName ?? "Unknown"}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Bowler: ${bowler?.playerName ?? "Unknown"}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C4FF),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startMatch();
            },
            child:
                const Text('Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startMatch() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('❌ User not authenticated!', Colors.red);
        return;
      }

      // ── CHANGE 2 ── Removed the isEmpty guard that blocked standalone matches.
      // Empty tournamentId is valid — models route to users/{uid}/matches/ path.

      if (currentMatchId == null ||
          battingTeamId == null ||
          bowlingTeamId == null) {
        _showSnackBar('Match data not found!', Colors.red);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00C4FF)),
                  SizedBox(height: 16),
                  Text(
                    'Starting match...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║        INITIALIZING MATCH              ║');
      debugPrint('║ Tournament: $_tournamentId             ║');
      debugPrint('║ Match: $currentMatchId                 ║');
      debugPrint('║ Creator UID: ${currentUser.uid}        ║');
      debugPrint('╚════════════════════════════════════════╝');

      final innings = Innings.createFirstInnings(
        matchId: currentMatchId!,
        battingTeamId: battingTeamId!,
        bowlingTeamId: bowlingTeamId!,
        tournamentId: _tournamentId,
        createdBy: currentUser.uid,
      );
      debugPrint('✅ Innings created: ${innings.inningsId}');

      final strikerBatsman = Batsman.create(
        inningsId: innings.inningsId,
        teamId: battingTeamId!,
        playerId: selectedStriker!,
        tournamentId: _tournamentId,
        matchId: currentMatchId!,
        createdBy: currentUser.uid,
      );
      debugPrint('✅ Striker batsman created');

      final nonStrikerBatsman = Batsman.create(
        inningsId: innings.inningsId,
        teamId: battingTeamId!,
        playerId: selectedNonStriker!,
        tournamentId: _tournamentId,
        matchId: currentMatchId!,
        createdBy: currentUser.uid,
      );
      debugPrint('✅ Non-striker batsman created');

      final bowler = Bowler.create(
        inningsId: innings.inningsId,
        teamId: bowlingTeamId!,
        playerId: selectedBowler!,
        tournamentId: _tournamentId,
        matchId: currentMatchId!,
        createdBy: currentUser.uid,
      );
      debugPrint('✅ Bowler created');

      final score = Score.create(
        innings.inningsId,
        tournamentId: _tournamentId,
        matchId: currentMatchId!,
        createdBy: currentUser.uid,
      );
      score.strikeBatsmanId = strikerBatsman.batId;
      score.nonStrikeBatsmanId = nonStrikerBatsman.batId;
      score.currentBowlerId = bowler.bowlerId;
      score.save();
      debugPrint('✅ Score initialized');

      await _sendInitialLEDData(
        innings: innings,
        striker: strikerBatsman,
        nonStriker: nonStrikerBatsman,
        bowler: bowler,
        score: score,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║    ✅ MATCH STARTED SUCCESSFULLY       ║');
      debugPrint('╚════════════════════════════════════════╝');

      _showSnackBar('🏏 Match started successfully!', Colors.green);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CricketScorerScreen(
            matchId: currentMatchId!,
            inningsId: innings.inningsId,
            strikeBatsmanId: strikerBatsman.batId,
            nonStrikeBatsmanId: nonStrikerBatsman.batId,
            bowlerId: bowler.bowlerId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error starting match: $e');

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showSnackBar('❌ Error starting match: $e', Colors.red);
    }
  }

  Future<void> _clearLEDScreen() async {
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping LED clear.');
        return;
      }

      debugPrint('🧹 Clearing LED screen...');
      await bleService.sendRawCommands(['CLEAR']);
      debugPrint('✅ LED screen cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear LED screen: $e');
    }
  }

  Future<void> _sendInitialLEDData({
    required Innings innings,
    required Batsman striker,
    required Batsman nonStriker,
    required Bowler bowler,
    required Score score,
  }) async {
    try {
      final bleService = BleManagerService();

      if (!bleService.isConnected) {
        debugPrint('⚠️ Bluetooth not connected. Skipping LED update.');
        _showSnackBar('LED Display not connected', Colors.orange);
        return;
      }

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║     SENDING MATCH DATA TO LED          ║');
      debugPrint('╚════════════════════════════════════════╝');

      debugPrint('📍 Step 1: Clearing display (triple clear)...');
      await bleService.sendRawCommands(['CLEAR']);
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint('📍 Step 3: Preparing player/team data...');

      final battingTeam = Team.getById(innings.battingTeamId);
      final strikerPlayer = TeamMember.getByPlayerId(striker.playerId);
      final nonStrikerPlayer = TeamMember.getByPlayerId(nonStriker.playerId);
      final bowlerPlayer = TeamMember.getByPlayerId(bowler.playerId);

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      const int temp = 27;

      String trunc(String name) =>
          (name.length > 6 ? name.substring(0, 6) : name).toUpperCase();

      final teamName = trunc(battingTeam?.teamName ?? 'BAT');
      final strikerName = trunc(strikerPlayer?.playerName ?? 'BAT1');
      final nonStrikerName =
          trunc(nonStrikerPlayer?.playerName ?? 'BAT2');
      final bowlerName = trunc(bowlerPlayer?.playerName ?? 'BOWL');

      debugPrint('   Team: $teamName | Striker: $strikerName | '
          'Non-Striker: $nonStrikerName | Bowler: $bowlerName');
      debugPrint('   Time: $timeStr | Temp: ${temp}°C');

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║  ✅ LED DISPLAY INITIALISED OK         ║');
      debugPrint('╚════════════════════════════════════════╝');
      _showSnackBar('✅ LED Display initialised', Colors.green);
    } catch (e) {
      debugPrint('❌ _sendInitialLEDData failed: $e');
      _showSnackBar('⚠️ Failed to initialise LED: $e', Colors.orange);
    }
  }

  void _showMatchDataDialog() {
    final allMatches = MatchStorage.getAllMatches();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Match Data Debug View',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: allMatches.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No matches created yet.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allMatches.length,
                  itemBuilder: (context, index) {
                    final match = allMatches[index];
                    final team1 = Team.getById(match.teamId1);
                    final team2 = Team.getById(match.teamId2);
                    final tossWinner = Team.getById(match.tossWonBy);
                    final battingTeam =
                        Team.getById(match.getBattingTeamId());
                    final bowlingTeam =
                        Team.getById(match.getBowlingTeamId());

                    return Card(
                      color: const Color(0xFF2C2C2E),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          
                            const Divider(color: Colors.white24, height: 16),
                            const Text('TEAMS:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '${team1?.teamName ?? match.teamId1} vs ${team2?.teamName ?? match.teamId2}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            const Text('MATCH SETTINGS:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Overs: ${match.overs}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            const Text('TOSS DETAILS:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Winner: ${tossWinner?.teamName ?? match.tossWonBy}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              'Decision: ${match.isBattingFirst ? "Bat First" : "Bowl First"}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Text('CURRENT STATUS:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Batting: ${battingTeam?.teamName ?? match.getBattingTeamId()}',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Bowling: ${bowlingTeam?.teamName ?? match.getBowlingTeamId()}',
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            const Text('MATCH RULES:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(
                                  match.isNoballAllowed
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: match.isNoballAllowed
                                      ? Colors.green
                                      : Colors.red,
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'No-ball: ${match.isNoballAllowed ? "Allowed" : "Not Allowed"}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ]),
                            Row(children: [
                              Icon(
                                  match.isWideAllowed
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: match.isWideAllowed
                                      ? Colors.green
                                      : Colors.red,
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Wide: ${match.isWideAllowed ? "Allowed" : "Not Allowed"}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            const Text('DATABASE INFO:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('DB ID: ${match.id}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                            Text('Team 1 ID: ${match.teamId1}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                            Text('Team 2 ID: ${match.teamId2}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFF00C4FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Appbg1.mainGradient),
        width: double.infinity,
        child: SafeArea(
          child: isLoadingPlayers
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00C4FF),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      "Cricket",
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Scorer",
                                      style: TextStyle(
                                        fontSize: 23,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.headphones,
                                      color: Colors.white70, size: 22),
                                  SizedBox(width: 12),
                                  Icon(Icons.settings,
                                      color: Colors.white70, size: 22),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 41),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2026),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(Icons.arrow_back,
                                        color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      "Select Opening Players",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Batting: ${widget.battingTeamName}",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Bowling: ${widget.bowlingTeamName}",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Players: ${battingPlayers.length} batters, ${bowlingPlayers.length} bowlers",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54,
                                          fontStyle: FontStyle.italic),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text("Striker",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 15),
                                    _buildPlayerSelector(
                                        "Select Striker",
                                        selectedStriker,
                                        'Striker'),
                                    const SizedBox(height: 20),
                                    const Text("Non-Striker",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 15),
                                    _buildPlayerSelector(
                                        "Select Non-Striker",
                                        selectedNonStriker,
                                        'Non-Striker'),
                                    const SizedBox(height: 20),
                                    const Text("Bowler",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 15),
                                    _buildPlayerSelector(
                                        "Choose Bowler",
                                        selectedBowler,
                                        'Bowler'),
                                    const SizedBox(height: 57),
                                    Center(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0E7292),
                                          minimumSize:
                                              const Size(50, 50),
                                          maximumSize:
                                              const Size(150, 50),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      30)),
                                        ),
                                        onPressed: _proceedToMatch,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: Text(
                                                "Proceed",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelector(
      String hint, String? selectedPlayerId, String playerType) {
    final selectedPlayer = selectedPlayerId != null
        ? TeamMember.getByPlayerId(selectedPlayerId)
        : null;
    return GestureDetector(
      onTap: () => _showPlayerSelectionDialog(playerType),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        height: 44.23,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedPlayer != null
                    ? selectedPlayer.playerName
                    : hint,
                style: TextStyle(
                  color: selectedPlayer != null
                      ? Colors.black
                      : const Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: selectedPlayer != null
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}