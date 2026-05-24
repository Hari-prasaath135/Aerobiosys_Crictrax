import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Team_Name.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:TURF_TOWN_/src/models/tournament_team.dart';

class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;
  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
}

class TeamPage extends StatefulWidget {
  final String? tournamentId;
  final String? tournamentName;

  // NOTE: NOT const — TeamPage uses FirestoreService which is not const-safe.
  const TeamPage({super.key, this.tournamentId, this.tournamentName});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final _fs = FirestoreService.instance;

  Map<String, dynamic>? _team1Data;
  Map<String, dynamic>? _team2Data;

  String? selectedTossWinner;
  String? selectedTossDecision;
  final TextEditingController oversController = TextEditingController();
  bool additionalSettings = false;
  bool _isCreatingMatch = false;

  int get teamsCreated =>
      (_team1Data != null ? 1 : 0) + (_team2Data != null ? 1 : 0);

  final List<String> tossDecisions = ['Bat', 'Bowl'];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    oversController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _navigateToAddTeam() async {
    if (teamsCreated >= 2) {
      _snack('Maximum 2 teams for a match!', Colors.orange);
      return;
    }

    final result = await Navigator.push(
      context,
      SmoothPageRoute(
        page: TeamNameScreen(
          teamNumber: teamsCreated + 1,
          tournamentId: widget.tournamentId,
          onTeamCreated: (_) {},
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (_team1Data != null &&
          result['team_id'] == _team1Data!['team_id']) {
        _snack('This team is already added!', Colors.orange);
        return;
      }

      setState(() {
        if (_team1Data == null) {
          _team1Data = result;
        } else {
          _team2Data = result;
        }
      });

      // Register team in tournament bridge collection if inside a tournament.
      if (widget.tournamentId != null) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          await TournamentTeam.addTeamToTournament(
            tournamentId: widget.tournamentId!,
            teamId: result['team_id'] as String,
            teamName: result['team_name'] as String,
            ownerUid: result['team_owner_uid'] as String? ?? '',
            ownerName: (result['team_owner_name'] as String?) ??
                (user?.displayName ?? ''),
            playerCount: (result['player_count'] as int?) ?? 0,
          );
        } catch (_) {
          // Team may already be registered — not a blocking error.
        }
      }

      _snack('Team "${result['team_name']}" added!', Colors.green);
    }
  }

  // ─── Start match ───────────────────────────────────────────────────────────

  void _startMatch() async {
    if (_team1Data == null || _team2Data == null) {
      _snack('Please select both teams!', Colors.red);
      return;
    }
    if (selectedTossWinner == null) {
      _snack('Please select toss winner!', Colors.red);
      return;
    }
    if (selectedTossDecision == null) {
      _snack('Please select toss decision!', Colors.red);
      return;
    }
    if (oversController.text.isEmpty) {
      _snack('Please enter overs!', Colors.red);
      return;
    }

    final overs = int.tryParse(oversController.text);
    if (overs == null || overs <= 0) {
      _snack('Please enter valid overs!', Colors.red);
      return;
    }

    if (widget.tournamentId == null) {
      _snack('Please select a tournament first!', Colors.orange);
      return;
    }

    setState(() => _isCreatingMatch = true);

    try {
      final tossWonByTeamId =
          selectedTossWinner == _team1Data!['team_name']
              ? _team1Data!['team_id'] as String
              : _team2Data!['team_id'] as String;

      final batBowlFlag = selectedTossDecision == 'Bat' ? 1 : 2;

      final match = await _fs.createMatch(
        tournamentId: widget.tournamentId!,
        teamId1: _team1Data!['team_id'] as String,
        teamId1Name: _team1Data!['team_name'] as String,
        teamId1OwnerUid: _team1Data!['team_owner_uid'] as String? ?? '',
        teamId2: _team2Data!['team_id'] as String,
        teamId2Name: _team2Data!['team_name'] as String,
        teamId2OwnerUid: _team2Data!['team_owner_uid'] as String? ?? '',
        tossWonBy: tossWonByTeamId,
        batBowlFlag: batBowlFlag,
        noballFlag: 1,
        wideFlag: 1,
        overs: overs,
      );

      if (mounted) {
        setState(() => _isCreatingMatch = false);
        Navigator.pushNamed(context, '/playerSelection', arguments: {
          'match': match,
          'tournamentName': widget.tournamentName ?? '',
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingMatch = false);
        _snack('Error creating match: $e', Colors.red);
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
            stops: [0.0, 0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(w),
                        SizedBox(height: h * 0.035),
                        _buildAddTeamsButton(w),
                        SizedBox(height: h * 0.035),
                        _buildTeamsSection(w),
                        SizedBox(height: h * 0.025),
                        _buildTossDetailsSection(w),
                        SizedBox(height: h * 0.025),
                        _buildOversSection(w),
                        SizedBox(height: h * 0.04),
                        _buildBottomRow(w),
                        SizedBox(height: h * 0.025),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Cricket ', style: _ts(w * 0.1)),
            TextSpan(text: 'Scorer', style: _ts(w * 0.05)),
          ]),
        ),
        Row(
          children: [
            Icon(Icons.support_agent, color: Colors.white, size: w * 0.065),
            SizedBox(width: w * 0.025),
            Icon(Icons.settings, color: Colors.white, size: w * 0.065),
          ],
        ),
      ],
    );
  }

  Widget _buildAddTeamsButton(double w) {
    return InkWell(
      onTap: _navigateToAddTeam,
      borderRadius: BorderRadius.circular(10),
      splashColor: const Color(0xFF00C4FF).withOpacity(0.3),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF1C2026),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: w * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Add Teams', style: _ts(w * 0.04)),
              SizedBox(width: w * 0.025),
              Icon(Icons.add_circle_outline,
                  color: Colors.white, size: w * 0.065),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Teams', style: _ts(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildTeamDisplay('Team 1', _team1Data, w),
          SizedBox(height: w * 0.04),
          _buildTeamDisplay('Team 2', _team2Data, w),
        ],
      ),
    );
  }

  Widget _buildTeamDisplay(
      String label, Map<String, dynamic>? data, double w) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: data != null
            ? const Color(0xFF00C4FF).withOpacity(0.1)
            : const Color(0xFFD9D9D9),
        border: Border.all(
            color: data != null
                ? const Color(0xFF00C4FF)
                : const Color(0xFFD1D1D1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data != null ? data['team_name'] as String : label,
            style: _ts(
              w * 0.034,
              null,
              data != null
                  ? const Color(0xFF00C4FF)
                  : const Color(0xFF9E9E9E),
            ),
          ),
          Icon(
            data != null
                ? Icons.check_circle
                : Icons.arrow_drop_down_circle_outlined,
            color: data != null ? const Color(0xFF00C4FF) : Colors.black54,
            size: w * 0.062,
          ),
        ],
      ),
    );
  }

  Widget _buildTossDetailsSection(double w) {
    final tossTeams = <String>[
      if (_team1Data != null) _team1Data!['team_name'] as String,
      if (_team2Data != null) _team2Data!['team_name'] as String,
    ];
    final tossEnabled = tossTeams.length == 2;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Toss Details', style: _ts(w * 0.04)),
          SizedBox(height: w * 0.04),
          _buildLabeledDropdown(
            'Add',
            'Choose team',
            selectedTossWinner,
            (v) => setState(() => selectedTossWinner = v),
            w,
            enabled: tossEnabled,
            items: tossTeams,
          ),
          SizedBox(height: w * 0.04),
          _buildLabeledDropdown(
            'Choose to',
            'Bat / Bowl',
            selectedTossDecision,
            (v) => setState(() => selectedTossDecision = v),
            w,
            isTossDecision: true,
            enabled: tossEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildOversSection(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: w * 0.26,
            child: Text('Overs', style: _ts(w * 0.034)),
          ),
          Expanded(
            child: TextField(
              controller: oversController,
              keyboardType: TextInputType.number,
              style: _ts(w * 0.034, null, Colors.black),
              decoration: InputDecoration(
                hintText: 'Enter overs',
                hintStyle: _ts(w * 0.034, null, const Color(0xFF9E9E9E)),
                filled: true,
                fillColor: const Color(0xFFD9D9D9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D1D1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D1D1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF00C4FF), width: 2)),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: w * 0.025),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => additionalSettings = !additionalSettings),
          child: Row(
            children: [
              Text('Additional\nSettings', style: _ts(w * 0.04)),
              SizedBox(width: w * 0.025),
              Switch(
                value: additionalSettings,
                onChanged: (v) => setState(() => additionalSettings = v),
                activeColor: const Color(0xFF00C4FF),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _isCreatingMatch ? null : _startMatch,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.05, vertical: w * 0.03),
            decoration: BoxDecoration(
              color:
                  _isCreatingMatch ? Colors.grey : const Color(0xFF00C4FF),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: _isCreatingMatch
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start Match', style: _ts(w * 0.04)),
                      SizedBox(width: w * 0.02),
                      Icon(Icons.sports_cricket,
                          color: Colors.white, size: w * 0.062),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledDropdown(
    String label,
    String placeholder,
    String? value,
    Function(String?) onChanged,
    double w, {
    bool isTossDecision = false,
    bool enabled = true,
    List<String>? items,
  }) {
    return Row(
      children: [
        SizedBox(
            width: w * 0.26, child: Text(label, style: _ts(w * 0.034))),
        Expanded(
          child: GestureDetector(
            onTap: enabled
                ? () {
                    if (isTossDecision) {
                      _showPicker(
                          'Choose Decision', tossDecisions, value, onChanged);
                    } else {
                      _showPicker('Select Toss Winner', items ?? [],
                          value, onChanged);
                    }
                  }
                : () => _snack(
                    'Please select both teams first!', Colors.orange),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04, vertical: w * 0.025),
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFD9D9D9)
                    : const Color(0xFF808080),
                border: Border.all(color: const Color(0xFFD1D1D1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value ?? placeholder,
                    style: _ts(
                      w * 0.034,
                      null,
                      value == null
                          ? const Color(0xFF9E9E9E)
                          : Colors.black,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    color: enabled ? Colors.black54 : Colors.black26,
                    size: w * 0.052,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(String title, List<String> items, String? current,
      Function(String?) onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 16),
            ...items.map((item) => ListTile(
                  title:
                      Text(item, style: const TextStyle(color: Colors.black)),
                  trailing: current == item
                      ? const Icon(Icons.check, color: Color(0xFF00C4FF))
                      : null,
                  onTap: () {
                    onChanged(item);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  TextStyle _ts(double size, [FontWeight? weight, Color? color]) => TextStyle(
        color: color ?? Colors.white,
        fontSize: size,
        fontFamily: 'Poppins',
        fontWeight: weight ?? FontWeight.w400,
      );
}