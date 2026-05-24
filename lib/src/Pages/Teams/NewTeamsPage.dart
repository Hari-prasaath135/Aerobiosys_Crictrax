// lib/src/Pages/Teams/NewTeamsPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

class NewTeamsPage extends StatefulWidget {
  const NewTeamsPage({super.key});

  @override
  State<NewTeamsPage> createState() => _NewTeamsPageState();
}

class _NewTeamsPageState extends State<NewTeamsPage> {
  final _fs = FirestoreService.instance;
  final _teamNameCtrl = TextEditingController();
  final _playerCtrl = TextEditingController();

  Team? _createdTeam;
  List<TeamMember> _players = [];
  bool _teamSaved = false;
  bool _isSavingTeam = false;
  bool _isAddingPlayer = false;

  String get _ownerName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email ??
      '';

  Future<void> _saveTeam() async {
    final name = _teamNameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Enter a team name');
      return;
    }
    setState(() => _isSavingTeam = true);
    final team = await _fs.createTeam(teamName: name, ownerName: _ownerName);
    setState(() {
      _createdTeam = team;
      _teamSaved = true;
      _isSavingTeam = false;
    });
  }

  Future<void> _addPlayer() async {
    if (_createdTeam == null) {
      _showSnack('Save the team name first');
      return;
    }
    final name = _playerCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isAddingPlayer = true);
    final member = await _fs.addPlayer(
      teamId: _createdTeam!.teamId,
      playerName: name,
    );
    setState(() {
      _players.add(member);
      _playerCtrl.clear();
      _isAddingPlayer = false;
    });
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _playerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F24),
        title: const Text('New Team', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Team name row ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamNameCtrl,
                    enabled: !_teamSaved,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Team Name',
                      labelStyle: const TextStyle(color: Color(0xFF9AA0A6)),
                      filled: true,
                      fillColor: const Color(0xFF1C1F24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (!_teamSaved)
                  _isSavingTeam
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Color(0xFF6D7CFF), strokeWidth: 2))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D7CFF)),
                          onPressed: _saveTeam,
                          child: const Text('Save',
                              style: TextStyle(color: Colors.white)),
                        ),
                if (_teamSaved)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF4CAF50), size: 32),
              ],
            ),
            const SizedBox(height: 20),

            if (_teamSaved) ...[
              // ── Add player row ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Player Name',
                        labelStyle: const TextStyle(color: Color(0xFF9AA0A6)),
                        filled: true,
                        fillColor: const Color(0xFF1C1F24),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isAddingPlayer
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Color(0xFF6D7CFF), strokeWidth: 2))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D7CFF)),
                          onPressed: _addPlayer,
                          child: const Text('Add',
                              style: TextStyle(color: Colors.white)),
                        ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Players list ──────────────────────────────────────────────
              Expanded(
                child: _players.isEmpty
                    ? const Center(
                        child: Text('No players yet',
                            style: TextStyle(color: Color(0xFF9AA0A6))),
                      )
                    : ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF6D7CFF),
                            child: Text('${i + 1}',
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(_players[i].teamName,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
              ),

              // ── Done button ───────────────────────────────────────────────
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _players.length >= 2
                      ? const Color(0xFF4CAF50)
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _players.length >= 2
                    ? () => Navigator.pop(context)
                    : null,
                child: Text(
                  _players.length < 2
                      ? 'Add at least 2 players  (${_players.length}/2)'
                      : 'Done  (${_players.length} players)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}