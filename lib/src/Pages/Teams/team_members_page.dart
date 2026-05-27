import 'package:TURF_TOWN_/src/Pages/Teams/player_stats_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';

class TeamMembersPage extends StatefulWidget {
  final Team team;

  const TeamMembersPage({super.key, required this.team});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  final _fs = FirestoreService.instance;
  List<TeamMember> players = [];
  bool isLoading = true;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => isLoading = true);
    try {
      // ✅ Scoped clear — only wipes THIS team's cache, not all teams
      TeamMember.clearCacheForTeam(widget.team.teamId);
      final loaded = await _fs.getPlayers(_uid, widget.team.teamId);
      if (mounted) {
        setState(() {
          players = loaded;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _snack('Error loading players: $e', Colors.red);
      }
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Add Player ─────────────────────────────────────────────────────────────

  void _showAddPlayerModal() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: _playerDialog(
          title: 'Add Player',
          controller: controller,
          buttonLabel: 'Add Player',
          onConfirm: () async {
            final name = controller.text.trim();
            if (name.isEmpty) {
              _snack('Please enter a player name!', Colors.red);
              return;
            }
            Navigator.of(dialogContext).pop();
            try {
              final member = await _fs.addPlayer(
                teamId: widget.team.teamId,
                playerName: name,
                teamName: widget.team.teamName,
              );

              // ✅ Update teamCount in Firestore
              await _fs.updateTeamCount(widget.team.teamId, players.length + 1);

              setState(() => players.add(member));
              _snack('$name added!', Colors.green);
            } catch (e) {
              _snack('$e', Colors.red);
            }
          },
        ),
      ),
    );
  }

  // ── Edit Player ────────────────────────────────────────────────────────────

  void _editPlayer(TeamMember player) {
    final controller = TextEditingController(text: player.playerName);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: _playerDialog(
          title: 'Edit Player',
          controller: controller,
          buttonLabel: 'Update',
          onConfirm: () async {
            final newName = controller.text.trim();
            if (newName.isEmpty) {
              _snack('Please enter a player name!', Colors.red);
              return;
            }
            Navigator.of(dialogContext).pop();
            try {
              await _fs.updatePlayerName(
                _uid,
                widget.team.teamId,
                player.playerId,
                newName,
              );
              await _loadPlayers();
              _snack('Player updated!', const Color(0xFF2B7790));
            } catch (e) {
              _snack('$e', Colors.red);
            }
          },
        ),
      ),
    );
  }

  // ── Delete Player ──────────────────────────────────────────────────────────

  void _deletePlayer(TeamMember player) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF3C3C3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Player',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        content: Text(
          'Delete "${player.playerName}"?',
          style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _fs.deletePlayer(
                  _uid,
                  widget.team.teamId,
                  player.playerId,
                );

                setState(
                  () =>
                      players.removeWhere((p) => p.playerId == player.playerId),
                );

                // ✅ Update teamCount in Firestore AFTER removing from local list
                await _fs.updateTeamCount(widget.team.teamId, players.length);

                _snack('Player deleted', Colors.orange);
              } catch (e) {
                _snack('Error: $e', Colors.red);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared dialog widget ───────────────────────────────────────────────────

  Widget _playerDialog({
    required String title,
    required TextEditingController controller,
    required String buttonLabel,
    required VoidCallback onConfirm,
  }) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(w * 0.06),
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: w * 0.065,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            autofocus: true, // ✅ autofocus true for better UX
            style: TextStyle(
              color: Colors.white,
              fontSize: w * 0.04,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: 'Enter Player Name',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'Poppins',
              ),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF5C5C5E),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2B7790),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.all(w * 0.04),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B7790),
                padding: EdgeInsets.symmetric(vertical: w * 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: w * 0.045,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140088),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140088),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.team.teamName,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF140088), Colors.black],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B7790)),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return players.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 100),
                              child: Text(
                                'No players added yet.\nTap + to add a player.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: w * 0.045,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.04,
                              vertical: w * 0.02,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Players (${players.length})',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w * 0.06,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: w * 0.04),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: players.length,
                                    itemBuilder: (context, index) =>
                                        _buildPlayerCard(
                                          players[index],
                                          index,
                                          w,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerModal,
        backgroundColor: const Color(0xFF2B7790),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPlayerCard(TeamMember player, int index, double w) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerStatsPage(player: player)),
      ),
      child: Container(
        key: ValueKey(player.playerId),
        margin: EdgeInsets.only(bottom: w * 0.04),
        padding: EdgeInsets.all(w * 0.045),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2B7790).withOpacity(0.3),
              const Color(0xFF1E1E1E).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2B7790).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B7790).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.025),
              decoration: BoxDecoration(
                color: const Color(0xFF2B7790),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person, color: Colors.white, size: w * 0.06),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.playerName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.045,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    'Tap to view stats',
                    style: TextStyle(
                      color: const Color(0xFF2B7790).withOpacity(0.8),
                      fontSize: w * 0.03,
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Stats icon hint
            Icon(
              Icons.bar_chart,
              color: const Color(0xFF2B7790).withOpacity(0.7),
              size: w * 0.05,
            ),
            SizedBox(width: w * 0.02),
            GestureDetector(
              onTap: () => _editPlayer(player),
              child: Container(
                padding: EdgeInsets.all(w * 0.02),
                child: Icon(
                  Icons.edit_outlined,
                  color: const Color(0xFF2B7790),
                  size: w * 0.055,
                ),
              ),
            ),
            SizedBox(width: w * 0.02),
            GestureDetector(
              onTap: () => _deletePlayer(player),
              child: Container(
                padding: EdgeInsets.all(w * 0.02),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: w * 0.055,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
