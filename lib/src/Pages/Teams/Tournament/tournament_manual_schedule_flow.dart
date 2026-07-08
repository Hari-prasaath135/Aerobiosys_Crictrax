import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';
import 'package:TURF_TOWN_/src/models/Tournament_team.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';

class ManualScheduleWizard extends StatefulWidget {
  final Tournament tournament;
  const ManualScheduleWizard({super.key, required this.tournament});

  @override
  State<ManualScheduleWizard> createState() => _ManualScheduleWizardState();
}

class _ManualScheduleWizardState extends State<ManualScheduleWizard> {
  final PageController _pageController = PageController();
  int _step = 0;
  static const _stepTitles = ['Format', 'Teams', 'Details', 'Publish'];

  // Step 1
  String? _selectedFormatId;

  // Step 2
  bool _loadingTeams = true;
  List<TournamentTeam> _teams = [];
  TournamentTeam? _teamA;
  TournamentTeam? _teamB;

  // Step 3
  int _overs = 20;
  String _ballType = 'leather'; // tennis | leather | other
  String _pitchType = 'TURF';
  DateTime? _matchDate;
  TimeOfDay? _matchTime;
  late TextEditingController _groundCtrl;
  late TextEditingController _cityCtrl;

  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _groundCtrl = TextEditingController(text: widget.tournament.ground);
    _cityCtrl = TextEditingController(text: widget.tournament.city);
    _loadTeams();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _groundCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournament.tournamentId)
          .collection('teams')
          .orderBy('addedAt')
          .get();
      final teams = snap.docs
          .map((d) => TournamentTeam(
                tournamentId: d['tournamentId'] as String,
                teamId: d['teamId'] as String,
                teamName: d['teamName'] as String,
                ownerUid: (d['ownerUid'] as String?) ?? '',
                ownerName: (d['ownerName'] as String?) ?? '',
                playerCount: (d['playerCount'] as int?) ?? 0,
              ))
          .toList();
      if (mounted) {
        setState(() {
          _teams = teams;
          _loadingTeams = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  void _goNext() {
    if (!_validateStep(_step)) return;
    if (_step < 3) {
      setState(() => _step++);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    } else {
      _publish();
    }
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_selectedFormatId == null) {
          _snack('Select a tournament format to continue', Colors.orange);
          return false;
        }
        return true;
      case 1:
        if (_teamA == null || _teamB == null) {
          _snack('Select both teams to continue', Colors.orange);
          return false;
        }
        if (_teamA!.teamId == _teamB!.teamId) {
          _snack('Team A and Team B must be different', Colors.orange);
          return false;
        }
        return true;
      case 2:
        if (_matchDate == null) {
          _snack('Pick a match date', Colors.orange);
          return false;
        }
        if (_matchTime == null) {
          _snack('Pick a match time', Colors.orange);
          return false;
        }
        if (_combinedDateTime().isBefore(DateTime.now())) {
          _snack('Match time cannot be in the past', Colors.orange);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  DateTime _combinedDateTime() => DateTime(
        _matchDate!.year,
        _matchDate!.month,
        _matchDate!.day,
        _matchTime!.hour,
        _matchTime!.minute,
      );

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final tId = widget.tournament.tournamentId;
      final matchRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tId)
          .collection('matches')
          .doc();

      final isKnockout = _selectedFormatId == 'single_elimination' ||
          _selectedFormatId == 'double_elimination';

      final data = <String, dynamic>{
        'matchId': matchRef.id,
        'tournamentId': tId,
        'teamId1': _teamA!.teamId,
        'teamId2': _teamB!.teamId,
        'teamId1Name': _teamA!.teamName,
        'teamId2Name': _teamB!.teamName,
        'teamId1OwnerUid': _teamA!.ownerUid,
        'teamId2OwnerUid': _teamB!.ownerUid,
        'overs': _overs,
        'ballType': _ballType,
        'pitchType': _pitchType,
        'ground': _groundCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'isCompleted': false,
        'status': 'scheduled',
        'scheduledAt': Timestamp.fromDate(_combinedDateTime()),
        'result': null,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'format': _selectedFormatId,
        'roundNo': 0,
        'roundName': isKnockout ? 'Round 1' : 'League',
        'bracketType': isKnockout ? 'winners' : 'league',
        'isBye': false,
        'isGhost': false,
        'nextMatchId': '',
        'nextMatchSlot': 0,
      };

      await matchRef.set(data);

      // Keep tournament-level format in sync for the badge/routing view,
      // merged so no other tournament fields are touched.
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tId)
          .set({'format': _selectedFormatId}, SetOptions(merge: true));

      if (mounted) {
        _snack('Match published successfully!', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('Error publishing match: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manual Schedule',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _formatStep(),
                _teamStep(),
                _detailsStep(),
                _reviewStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Step indicator ──────────────────────────────────────────────────
  Widget _buildStepper() {
    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_stepTitles.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < _step;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: leftDone ? const Color(0xFF00BCD4) : Colors.white12,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = idx == _step;
          final done = idx < _step;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (active || done)
                      ? const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)])
                      : null,
                  color: (active || done) ? null : const Color(0xFF1A1A2E),
                  border: Border.all(
                    color:
                        (active || done) ? Colors.transparent : Colors.white24,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: const Color(0xFF00BCD4).withOpacity(0.5),
                              blurRadius: 10)
                        ]
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              color: active ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                ),
              ),
              const SizedBox(height: 6),
              Text(_stepTitles[idx],
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white38,
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal)),
            ],
          );
        }),
      ),
    );
  }

  // ── Step 1: Format ──────────────────────────────────────────────────
  Widget _formatStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Tournament Format',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
              'This determines how the match fits into the tournament structure.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
               borderRadius: BorderRadius.circular(10),
               border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
             'Knockout formats (Single/Double Elimination, Group Stage) need the '
             'full bracket generated together — use Auto Schedule for those.',
              style: TextStyle(color: Colors.orange, fontSize: 11),
               ),
             ),
          ...kFormats.where((f) => 
              f.id == 'league' || f.id == 'ipl_full_league').map((fmt) {
            final selected = _selectedFormatId == fmt.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedFormatId = fmt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF283593)])
                      : null,
                  color: selected ? null : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? const Color(0xFF00BCD4) : Colors.white10,
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: const Color(0xFF00BCD4).withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (selected
                                ? const Color(0xFF00BCD4)
                                : Colors.white10)
                            .withOpacity(0.15),
                      ),
                      child: Icon(fmt.icon,
                          color: selected
                              ? const Color(0xFF00BCD4)
                              : Colors.white54,
                          size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmt.label,
                              style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(fmt.tagline,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? const Color(0xFF00BCD4) : Colors.white24,
                      size: 22,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 2: Teams ───────────────────────────────────────────────────
  Widget _teamStep() {
    if (_loadingTeams) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }
    if (_teams.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Need at least 2 registered teams to schedule a match.\n'
            'Add teams from the Teams tab first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Playing Teams',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          _teamPickerCircle(
              label: 'Team A',
              team: _teamA,
              onTap: () => _pickTeam(isTeamA: true)),
          const SizedBox(height: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A2E),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: const Text('VS',
                style: TextStyle(
                    color: Color(0xFF00BCD4),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(height: 8),
          _teamPickerCircle(
              label: 'Team B',
              team: _teamB,
              onTap: () => _pickTeam(isTeamA: false)),
        ],
      ),
    );
  }

  Widget _teamPickerCircle(
      {required String label,
      required TournamentTeam? team,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: team != null
                  ? const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF1A237E)])
                  : null,
              color: team == null ? const Color(0xFF1A1A2E) : null,
              border: Border.all(
                  color: team != null ? const Color(0xFF00BCD4) : Colors.white24,
                  width: 2),
              boxShadow: team != null
                  ? [
                      BoxShadow(
                          color: const Color(0xFF00BCD4).withOpacity(0.3),
                          blurRadius: 16)
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: team != null
                ? Text(_initials(team.teamName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26))
                : const Icon(Icons.add, color: Colors.white38, size: 32),
          ),
          const SizedBox(height: 10),
          Text(team?.teamName ?? label,
              style: TextStyle(
                  color: team != null ? Colors.white : Colors.white38,
                  fontWeight: team != null ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14)),
          if (team != null)
            Text('${team.playerCount} players',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return ((parts[0].isNotEmpty ? parts[0][0] : '') +
            (parts[1].isNotEmpty ? parts[1][0] : ''))
        .toUpperCase();
  }

  void _pickTeam({required bool isTeamA}) {
    final excludeId = isTeamA ? _teamB?.teamId : _teamA?.teamId;
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final filtered = _teams
              .where((t) => t.teamId != excludeId)
              .where((t) =>
                  t.teamName.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(isTeamA ? 'Select Team A' : 'Select Team B',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setSheet(() => query = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search teams…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                    filled: true,
                    fillColor: const Color(0xFF0D0D1A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('No teams found.',
                              style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final t = filtered[i];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isTeamA) {
                                    _teamA = t;
                                  } else {
                                    _teamB = t;
                                  }
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D0D1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          const Color(0xFF00BCD4).withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          const Color(0xFF00BCD4).withOpacity(0.2),
                                      child: Text(_initials(t.teamName),
                                          style: const TextStyle(
                                              color: Color(0xFF00BCD4),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(t.teamName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Text('${t.playerCount} pl',
                                        style: const TextStyle(
                                            color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Step 3: Details ─────────────────────────────────────────────────
  Widget _detailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Match Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _label('Overs per innings'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _stepperBtn(Icons.remove,
                    () => setState(() => _overs = (_overs - 1).clamp(1, 50))),
                Expanded(
                  child: Text('$_overs overs',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                _stepperBtn(Icons.add,
                    () => setState(() => _overs = (_overs + 1).clamp(1, 50))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label('Ball type'),
          const SizedBox(height: 8),
          Row(
            children: [
              _ballTypeChip('tennis', 'Tennis', Colors.green),
              const SizedBox(width: 10),
              _ballTypeChip('leather', 'Leather', Colors.red),
              const SizedBox(width: 10),
              _ballTypeChip('other', 'Other', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          _label('Pitch type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['ROUGH', 'CEMENT', 'TURF', 'ASTROTURF'].map((p) {
              final sel = _pitchType == p;
              return GestureDetector(
                onTap: () => setState(() => _pitchType = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF00BCD4) : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? const Color(0xFF00BCD4) : Colors.white12),
                  ),
                  child: Text(p,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _label('Ground'),
          const SizedBox(height: 8),
          _textField(_groundCtrl, Icons.stadium_outlined, 'Ground name'),
          const SizedBox(height: 16),
          _label('City'),
          const SizedBox(height: 8),
          _textField(_cityCtrl, Icons.location_city, 'City'),
          const SizedBox(height: 20),
          _label('Date & Time'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dateTimeTile(
                  icon: Icons.calendar_today,
                  label: _matchDate == null
                      ? 'Pick date'
                      : '${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year}',
                  hasValue: _matchDate != null,
                  onTap: () async {
                    final today = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _matchDate ?? today,
                      firstDate: DateTime(today.year, today.month, today.day),
                      lastDate: DateTime(today.year + 2),
                      builder: (c, child) => Theme(
                        data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF00BCD4),
                                surface: Color(0xFF1A1A2E))),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _matchDate = picked);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTimeTile(
                  icon: Icons.access_time,
                  label: _matchTime == null
                      ? 'Pick time'
                      : _matchTime!.format(context),
                  hasValue: _matchTime != null,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _matchTime ?? TimeOfDay.now(),
                      builder: (c, child) => Theme(
                        data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF00BCD4),
                                surface: Color(0xFF1A1A2E))),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _matchTime = picked);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _stepperBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF00BCD4), size: 18),
        ),
      );

  Widget _ballTypeChip(String value, String label, Color color) {
    final sel = _ballType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ballType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? color.withOpacity(0.15) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? color : Colors.white12),
          ),
          child: Column(
            children: [
              Icon(Icons.sports_cricket,
                  color: sel ? color : Colors.white38, size: 18),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, IconData icon, String hint) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      );

  Widget _dateTimeTile(
      {required IconData icon,
      required String label,
      required bool hasValue,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? const Color(0xFF00BCD4).withOpacity(0.6)
                  : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: hasValue ? Colors.white : Colors.white38,
                      fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Review ──────────────────────────────────────────────────
  Widget _reviewStep() {
    final fmt = kFormats.firstWhere((f) => f.id == _selectedFormatId,
        orElse: () => kFormats.first);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Publish',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Text(_teamA?.teamName ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('VS',
                          style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                        child: Text(_teamB?.teamName ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),
                _reviewRow(Icons.emoji_events_outlined, 'Format', fmt.label),
                _reviewRow(Icons.sports_cricket, 'Overs', '$_overs overs'),
                _reviewRow(Icons.sports_baseball, 'Ball',
                    _ballType[0].toUpperCase() + _ballType.substring(1)),
                _reviewRow(Icons.grass, 'Pitch', _pitchType),
                _reviewRow(Icons.stadium_outlined, 'Ground',
                    _groundCtrl.text.trim().isEmpty ? '-' : _groundCtrl.text.trim()),
                _reviewRow(Icons.location_city, 'City',
                    _cityCtrl.text.trim().isEmpty ? '-' : _cityCtrl.text.trim()),
                if (_matchDate != null && _matchTime != null)
                  _reviewRow(
                      Icons.event,
                      'When',
                      '${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year}  •  '
                          '${_matchTime!.format(context)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
              'Publishing will add this match to the tournament schedule immediately.',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12))),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _publishing ? null : _goBack,
              child: Text(_step == 0 ? 'Cancel' : 'Back',
                  style: const TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _publishing ? null : _goNext,
              child: _publishing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_step == 3 ? 'Publish Match' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}