import 'package:TURF_TOWN_/src/Pages/Teams/player_stats_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:TURF_TOWN_/src/models/team_member.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:TURF_TOWN_/src/utils/name_formatter.dart';

class TeamMembersPage extends StatefulWidget {
  final Team team;

  const TeamMembersPage({super.key, required this.team});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService.instance;
  List<TeamMember> players = [];
  List<TeamMember> _filtered = [];
  bool isLoading = true;
  bool _searchActive = false;
  final _searchCtrl = TextEditingController();

  late AnimationController _fabAnim;

  static const List<Color> _accentColors = [
    Color(0xFF00C4FF),
    Color(0xFF00E676),
    Color(0xFFFF6B35),
    Color(0xFFFFD93D),
    Color(0xFFB388FF),
    Color(0xFFFF4081),
  ];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _searchCtrl.addListener(_onSearch);
    _loadPlayers();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(players)
          : players
              .where((p) => p.playerName.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _loadPlayers() async {
    setState(() => isLoading = true);
    try {
      TeamMember.clearCacheForTeam(widget.team.teamId);
      final loaded = await _fs.getPlayers(_uid, widget.team.teamId);
      if (mounted) {
        setState(() {
          players = loaded;
          _filtered = List.from(loaded);
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
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          subtitle: 'Enter the player\'s name below',
          icon: Icons.person_add_alt_1_rounded,
          controller: controller,
          buttonLabel: 'Add to Squad',
          accentColor: const Color(0xFF00C4FF),
          onConfirm: () async {
            final name = controller.text.trim();
            if (name.isEmpty) {
              _snack('Please enter a player name!', Colors.red);
              return;
            }
             final formattedName = formatPlayerName(name); // added
            Navigator.of(dialogContext).pop();
            try {
              final member = await _fs.addPlayer(
                teamId: widget.team.teamId,
                playerName: formattedName,
                teamName: widget.team.teamName,
              );
              await _fs.updateTeamCount(
                  widget.team.teamId, players.length + 1);
              setState(() {
                players.add(member);
                _filtered = List.from(players);
              });
              _snack('$name added to squad!', const Color(0xFF00E676));
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
          subtitle: 'Update the player\'s name',
          icon: Icons.edit_rounded,
          controller: controller,
          buttonLabel: 'Save Changes',
          accentColor: const Color(0xFF00C4FF),
          onConfirm: () async {
            final newName = controller.text.trim();
            if (newName.isEmpty) {
              _snack('Please enter a player name!', Colors.red);
              return;
            }
            final formattedName = formatPlayerName(newName); // added
            Navigator.of(dialogContext).pop();
            try {
              await _fs.updatePlayerName(
                _uid,
                widget.team.teamId,
                player.playerId,
                formattedName,
              );
              await _loadPlayers();
              _snack('Player updated!', const Color(0xFF00C4FF));
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
        backgroundColor: const Color(0xFF1C2030),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_remove_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Remove Player',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white60,
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Remove '),
              TextSpan(
                text: '"${player.playerName}"',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' from the squad?'),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel',
                style:
                    TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _fs.deletePlayer(
                    _uid, widget.team.teamId, player.playerId);
                setState(() {
                  players.removeWhere((p) => p.playerId == player.playerId);
                  _filtered =
                      List.from(players); // keep search in sync
                });
                await _fs.updateTeamCount(
                    widget.team.teamId, players.length);
                _snack('${player.playerName} removed', Colors.orange);
              } catch (e) {
                _snack('Error: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Remove',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Shared Dialog ──────────────────────────────────────────────────────────

  Widget _playerDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
    required String buttonLabel,
    required Color accentColor,
    required VoidCallback onConfirm,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2030),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border:
                  Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Rohit Sharma',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontFamily: 'Poppins',
              ),
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: accentColor.withOpacity(0.7)),
              filled: true,
              fillColor: const Color(0xFF262B3E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(buttonLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C18),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B3E),
              Color(0xFF080C18),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (!isLoading && players.isNotEmpty) ...[
                _buildSearchBar(),
                _buildStatsRow(),
              ],
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00C4FF),
                          strokeWidth: 2.5,
                        ),
                      )
                    : players.isEmpty
                        ? _buildEmptyState()
                        : _filtered.isEmpty
                            ? _buildNoResultsState()
                            : _buildPlayerList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: _showAddPlayerModal,
          backgroundColor: const Color(0xFF00C4FF),
          elevation: 10,
          icon: const Icon(Icons.person_add_alt_1_rounded,
              color: Colors.white, size: 20),
          label: const Text(
            'Add Player',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    // Team initials for the header badge
    final initials = widget.team.teamName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00C4FF).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white60, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          // Team badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C4FF), Color(0xFF0066CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C4FF).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isNotEmpty ? initials : '?',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Team name + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team.teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'SQUAD ROSTER',
                  style: TextStyle(
                    color: const Color(0xFF00C4FF).withOpacity(0.65),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          // Search toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) {
                  _searchCtrl.clear();
                  _filtered = List.from(players);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _searchActive
                    ? const Color(0xFF00C4FF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchActive
                      ? const Color(0xFF00C4FF).withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                _searchActive ? Icons.close_rounded : Icons.search_rounded,
                color: _searchActive
                    ? const Color(0xFF00C4FF)
                    : Colors.white60,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _searchActive
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: const Color(0xFF00C4FF).withOpacity(0.7),
                      size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1A1F30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C4FF), width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1525),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00C4FF).withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          _statChip(
            icon: Icons.groups_rounded,
            label: '${players.length} Players',
            color: const Color(0xFF00C4FF),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          _statChip(
            icon: Icons.shield_rounded,
            label: widget.team.teamName,
            color: const Color(0xFF00E676),
          ),
          const Spacer(),
          Text(
            'TAP FOR STATS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF00C4FF).withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF00C4FF).withOpacity(0.18),
                  width: 1.5),
            ),
            child: Icon(Icons.group_add_rounded,
                size: 54, color: Colors.white.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            'Squad is Empty',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 22,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first player to get started',
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No players found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 17,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different name',
            style: TextStyle(
              color: Colors.white.withOpacity(0.22),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ── Player List ────────────────────────────────────────────────────────────

  Widget _buildPlayerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        // Find real index for consistent accent color
        final realIndex = players.indexOf(_filtered[index]);
        return _buildPlayerCard(_filtered[index], realIndex);
      },
    );
  }

  // ── Player Card ────────────────────────────────────────────────────────────

  Widget _buildPlayerCard(TeamMember player, int index) {
    final accent = _accentColors[index % _accentColors.length];
    final jerseyNumber = index + 1;
    final nameParts = player.playerName.trim().split(' ')
      ..removeWhere((w) => w.isEmpty);
    final initials = nameParts.take(2).map((w) => w[0].toUpperCase()).join();
    final firstName = nameParts.isNotEmpty ? nameParts.first : player.playerName;
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerStatsPage(player: player)),
      ),
      child: Container(
        key: ValueKey(player.playerId),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10151F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Left accent bar
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withOpacity(0.15)],
                    ),
                  ),
                ),
              ),
              // Subtle glow behind avatar area
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 90,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withOpacity(0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
                child: Row(
                  children: [
                    // Avatar with jersey badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withOpacity(0.3),
                                accent.withOpacity(0.07),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: accent.withOpacity(0.55), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials.isNotEmpty ? initials : '#',
                            style: TextStyle(
                              color: accent,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        // Jersey number pill
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.55),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '#$jerseyNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Name block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show split name if two-part, else single line
                          lastName.isNotEmpty
                              ? RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '$firstName ',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: lastName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  firstName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          // Stats chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: accent.withOpacity(0.25), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    color: accent, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  'View Stats',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF00C4FF),
                          onTap: () => _editPlayer(player),
                        ),
                        const SizedBox(height: 6),
                        _actionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red,
                          onTap: () => _deletePlayer(player),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.22), width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}