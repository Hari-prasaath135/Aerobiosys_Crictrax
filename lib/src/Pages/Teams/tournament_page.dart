// ═══════════════════════════════════════════════════════════════════════════
// TournamentPage.dart
// Changes in this version:
//   1. Three-dot menu on scheduled match cards (edit / delete) — Firestore
//      persisted, visible to all, only tournament creator can act
//   2. Tournament format shown on the detail screen (created/overview card)
//   3. All 5 formats verified with scheduling logic gated behind ≥4 teams
//   4. Minimum 4 teams enforced before any schedule generation
//   5. Pro feature suggestions panel added to About tab
//   BUG FIX 1: Removed ownerUid one-team-per-user guard in _showMyTeamsPicker();
//              replaced with teamName uniqueness check so same user can add
//              multiple different teams.
//   BUG FIX 2: Match cards now read data['format'] and display format icon+label.
//   BUG FIX 3: Tournament creation now saves format field; _showScheduleOptions()
//              locks to tournament.format instead of free-pick list.
//   No other existing features changed.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/create_tournament_team_page.dart';
import 'package:TURF_TOWN_/src/models/Tournament_team.dart';
import 'package:TURF_TOWN_/src/models/team.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/tournament_model.dart';
import 'package:TURF_TOWN_/src/services/firestore_service.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/TeamPage.dart';

// ──────────────────────────────────────────────────────────────────────────
// Tournament format data
// ──────────────────────────────────────────────────────────────────────────

class _TournamentFormat {
  final String id;
  final String label;
  final String tagline;
  final String description;
  final String group;
  final IconData icon;

  const _TournamentFormat({
    required this.id,
    required this.label,
    required this.tagline,
    required this.description,
    required this.group,
    required this.icon,
  });
}

const List<_TournamentFormat> _kFormats = [
  _TournamentFormat(
    id: 'league',
    label: 'League / Round Robin',
    tagline: 'IPL group stage style',
    description:
        'Every team plays every other team exactly once. '
        'The most fair format — everyone gets equal game time — '
        'but requires more matches as the team count grows.',
    group: 'Quick',
    icon: Icons.loop,
  ),
  _TournamentFormat(
    id: 'single_elimination',
    label: 'Single Elimination',
    tagline: 'World Cup knockout style',
    description:
        'Lose once and you\'re out. Bracket advances winner to the '
        'next round. Fast, dramatic, and perfect for large fields '
        'where you need a winner quickly.',
    group: 'Quick',
    icon: Icons.account_tree_outlined,
  ),
  _TournamentFormat(
    id: 'ipl_full_league',
    label: 'IPL Full League',
    tagline: 'IPL full season format',
    description:
        'All teams play each other in a round-robin, then the '
        'top teams advance to semi-finals and a final. '
        'Balances fairness with exciting knockout drama.',
    group: 'Quick',
    icon: Icons.emoji_events_outlined,
  ),
  _TournamentFormat(
    id: 'double_elimination',
    label: 'Double Elimination',
    tagline: 'Second-chance knockout',
    description:
        'You get one lifeline after a loss. Teams move between '
        'a Winners Bracket and a Losers Bracket. Popular in esports '
        'and competitive circuits where one bad day shouldn\'t '
        'end a team\'s tournament.',
    group: 'Advanced',
    icon: Icons.low_priority,
  ),
  _TournamentFormat(
    id: 'fifa_world_cup',
    label: 'Group Stage + Knockout',
    tagline: 'FIFA World Cup format',
    description:
        'Teams are split into groups for mini round-robins. '
        'Top finishers from each group advance to a knockout bracket. '
        'The gold standard for large tournaments with 8+ teams.',
    group: 'Advanced',
    icon: Icons.public,
  ),
];

// ── Scheduling helper ──────────────────────────────────────────────────────
// Returns a list of (teamA, teamB) matchup strings for a given format.
// Requires teams.length >= 4.

List<List<TournamentTeam>> _generateScheduleFromTeams(
    String formatId, List<TournamentTeam> teams) {
  final n = teams.length;
  if (n < 4) return [];

  switch (formatId) {
    case 'league':
    case 'ipl_full_league':
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          matches.add([teams[i], teams[j]]);
        }
      }
      return matches;

    case 'single_elimination':
    case 'double_elimination':
      final matches = <List<TournamentTeam>>[];
      for (int i = 0; i < n - 1; i += 2) {
        matches.add([teams[i], teams[i + 1]]);
      }
      return matches;

    case 'fifa_world_cup':
      final matches = <List<TournamentTeam>>[];
      const groupSize = 4;
      for (int g = 0; g * groupSize < n; g++) {
        final start = g * groupSize;
        final end = (start + groupSize).clamp(0, n);
        final group = teams.sublist(start, end);
        for (int i = 0; i < group.length; i++) {
          for (int j = i + 1; j < group.length; j++) {
            matches.add([group[i], group[j]]);
          }
        }
      }
      return matches;

    default:
      return [];
  }
}
// ──────────────────────────────────────────────────────────────────────────
// Main page widget
// ──────────────────────────────────────────────────────────────────────────

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _groundController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerPhoneController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  File? _logoFile;
  String? _logoPath;
  List<String> _categories = [];
  List<String> _tags = [];
  bool _isCreating = false;
  String? _selectedFormatId;

  late TabController _tabController;
  List<Tournament> _tournaments = [];
  StreamSubscription<List<Tournament>>? _tournamentsSubscription;
  bool _isLoadingTournaments = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribeToTournaments();
  }

  @override
  void dispose() {
    _tournamentsSubscription?.cancel();
    _tabController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _groundController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    super.dispose();
  }

  void _subscribeToTournaments() {
    if (Tournament.currentUserIsAnonymous) {
      setState(() {
        _isLoadingTournaments = false;
        _loadError =
            'You must be signed in with a registered account to view tournaments.';
      });
      return;
    }

    _tournamentsSubscription = Tournament.stream().listen(
      (list) {
        if (mounted) {
          setState(() {
            _tournaments = list;
            _isLoadingTournaments = false;
            _loadError = null;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _isLoadingTournaments = false;
            _loadError = 'Failed to load tournaments: $e';
          });
        }
      },
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Logo',
          toolbarColor: const Color(0xFF1A237E),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF00BCD4),
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Logo',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() {
        _logoFile = File(cropped.path);
        _logoPath = cropped.path;
      });
    }
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter tournament name', Colors.red);
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnack('Please enter city', Colors.red);
      return false;
    }
    if (_groundController.text.trim().isEmpty) {
      _showSnack('Please enter ground name', Colors.red);
      return false;
    }
    if (_organizerNameController.text.trim().isEmpty) {
      _showSnack('Please enter organizer name', Colors.red);
      return false;
    }
    if (_organizerPhoneController.text.trim().length < 10) {
      _showSnack('Please enter valid phone number', Colors.red);
      return false;
    }
    if (_startDate == null) {
      _showSnack('Please select start date', Colors.red);
      return false;
    }
    if (_endDate == null) {
      _showSnack('Please select end date', Colors.red);
      return false;
    }
    if (_endDate!.difference(_startDate!).inDays < 2) {
      _showSnack('Tournament must be at least 2 days long', Colors.red);
      return false;
    }
    return true;
  }

  Future<void> _createTournament() async {
    if (!_validate()) return;

    if (Tournament.currentUserIsAnonymous) {
      _showSnack(
          'You must be signed in with a registered account to create a tournament.',
          Colors.red);
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isCreating = true);

    try {
      final tournament = Tournament(
        tournamentId: Tournament.generateId(),
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        ground: _groundController.text.trim(),
        organizerName: _organizerNameController.text.trim(),
        organizerPhone: _organizerPhoneController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        categories: List.from(_categories),
        tags: List.from(_tags),
        logoPath: _logoPath,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        // BUG FIX 3: persist the selected format so scheduling is locked to it
        format: _selectedFormatId ?? '',
      );

      await Tournament.save(tournament);

      setState(() {
        _startDate = null;
        _endDate = null;
        _logoFile = null;
        _logoPath = null;
        _selectedFormatId = null;
        _categories = [];
        _tags = [];
      });
      _nameController.clear();
      _cityController.clear();
      _groundController.clear();
      _organizerNameController.clear();
      _organizerPhoneController.clear();

      _showSnack('Tournament created successfully!', Colors.green);
      _tabController.animateTo(1);
    } catch (e) {
      _showSnack('Error creating tournament: $e', Colors.red);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteTournament(Tournament t) async {
    if (!t.isOwnedByCurrentUser) {
      _showSnack('You can only delete your own tournaments.', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Tournament',
            style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${t.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Tournament.delete(t.tournamentId);
        _showSnack('Tournament deleted', Colors.orange);
      } catch (e) {
        _showSnack('Error deleting tournament: $e', Colors.red);
      }
    }
  }

  void _editTournament(Tournament t) {
    if (!t.isOwnedByCurrentUser) {
      _showSnack('You can only edit your own tournaments.', Colors.red);
      return;
    }

    _nameController.text = t.name;
    _cityController.text = t.city;
    _groundController.text = t.ground;
    _organizerNameController.text = t.organizerName;
    _organizerPhoneController.text = t.organizerPhone;

    setState(() {
      _startDate = t.startDate;
      _endDate = t.endDate;
      _logoPath = t.logoPath;
      _logoFile = null;
      _categories = List.from(t.categories);
      _tags = List.from(t.tags);
      // BUG FIX 3: restore the saved format when editing
     _selectedFormatId = (t.format?.isNotEmpty == true) ? t.format : null;
    });

    _tabController.animateTo(0);
    _showSnack(
        'Edit the fields and tap Create Tournament to save changes.',
        const Color(0xFF00BCD4));
  }

  String _getStatus(Tournament t) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final start =
        DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
    final end = DateTime(t.endDate.year, t.endDate.month, t.endDate.day);

    if (today.isBefore(start)) return 'Upcoming';
    if (today.isAfter(end)) return 'Completed';
    return 'Live';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Live':
        return Colors.green;
      case 'Upcoming':
        return const Color(0xFF00BCD4);
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  void _openTournamentDetail(Tournament t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentDetailPage(
          tournament: t,
          formatDate: _formatDate,
          getStatus: _getStatus,
          getStatusColor: _getStatusColor,
          onDelete: () async => _deleteTournament(t),
          onEdit: () {
            Navigator.pop(context);
            _editTournament(t);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Color(0xFF00BCD4)),
            SizedBox(width: 8),
            Text('Tournaments',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Create New'),
                Tab(text: 'All Tournaments'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    if (Tournament.currentUserIsAnonymous) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Please sign in with a registered account to create tournaments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A2E),
                      border: Border.all(
                          color: const Color(0xFF00BCD4), width: 2),
                      image: _logoFile != null
                          ? DecorationImage(
                              image: FileImage(_logoFile!),
                              fit: BoxFit.cover,
                            )
                          : (_logoPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_logoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: (_logoFile == null && _logoPath == null)
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Color(0xFF00BCD4), size: 32),
                              SizedBox(height: 4),
                              Text('Logo',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                  if (_logoFile != null || _logoPath != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BCD4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 14),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Tap to add tournament logo',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            icon: Icons.info_outline,
            title: 'Tournament Info',
            children: [
              _buildStyledField(_nameController, 'Tournament Name',
                  Icons.emoji_events_outlined),
              _buildStyledField(
                  _cityController, 'City', Icons.location_city),
              _buildStyledField(_groundController, 'Ground / Venue',
                  Icons.stadium_outlined),
            ],
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.person_outline,
            title: 'Organizer Details',
            children: [
              _buildStyledField(_organizerNameController, 'Organizer Name',
                  Icons.person_outline),
              _buildStyledField(
                  _organizerPhoneController, 'Phone Number',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
            ],
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.calendar_month,
            title: 'Schedule',
            children: [
              _buildStyledDateRow('Start Date', _startDate,
                  (d) => setState(() => _startDate = d),
                  isStart: true),
              _buildStyledDateRow('End Date', _endDate,
                  (d) => setState(() => _endDate = d),
                  isStart: false),
            ],
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.format_list_bulleted,
            title: 'Tournament Format',
            children: [_buildFormatDropdown()],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isCreating ? null : _createTournament,
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create Tournament',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatDropdown() {
    final selected = _selectedFormatId != null
        ? _kFormats.firstWhere((f) => f.id == _selectedFormatId,
            orElse: () => _kFormats.first)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFormatPicker(),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected != null
                    ? const Color(0xFF00BCD4).withOpacity(0.6)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected?.icon ?? Icons.help_outline,
                  color: selected != null
                      ? const Color(0xFF00BCD4)
                      : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected?.label ?? 'Select a format',
                    style: TextStyle(
                      color:
                          selected != null ? Colors.white : Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white38),
              ],
            ),
          ),
        ),

        if (selected != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF00BCD4).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(selected.icon,
                        color: const Color(0xFF00BCD4), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      selected.tagline,
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  selected.description,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showFormatPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Tournament Format',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _formatGroupLabel('⚡ Quick Formats'),
              const SizedBox(height: 8),
              ..._kFormats
                  .where((f) => f.group == 'Quick')
                  .map((f) => _formatTile(f)),
              const SizedBox(height: 16),
              _formatGroupLabel('🏆 Advanced Formats'),
              const SizedBox(height: 8),
              ..._kFormats
                  .where((f) => f.group == 'Advanced')
                  .map((f) => _formatTile(f)),
            ],
          ),
        );
      },
    );
  }

  Widget _formatGroupLabel(String label) => Text(
        label,
        style: const TextStyle(
          color: Color(0xFF00BCD4),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );

  Widget _formatTile(_TournamentFormat f) {
    final isSelected = _selectedFormatId == f.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFormatId = f.id);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BCD4).withOpacity(0.15)
              : const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00BCD4) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(f.icon,
                color: isSelected
                    ? const Color(0xFF00BCD4)
                    : Colors.white54,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.label,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(f.tagline,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF00BCD4), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStyledField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
          filled: true,
          fillColor: const Color(0xFF0D0D1A),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStyledDateRow(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked, {
    required bool isStart,
  }) {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? firstDate,
            firstDate: firstDate,
            lastDate: DateTime(2100),
            builder: (context, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF00BCD4),
                  surface: Color(0xFF1A1A2E),
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPicked(picked);
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value == null
                      ? label
                      : '$label: ${_formatDate(value)}',
                  style: TextStyle(
                    color: value == null ? Colors.white38 : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const Text('Select',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const Icon(Icons.arrow_drop_down, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTab() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_loadError!,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 15)),
        ),
      );
    }

    if (_isLoadingTournaments) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }

    if (_tournaments.isEmpty) {
      return const Center(
          child: Text('No tournaments yet.',
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
          left: 12, right: 12, top: 12, bottom: 120),
      itemCount: _tournaments.length,
      itemBuilder: (context, i) {
        final t = _tournaments[i];
        final status = _getStatus(t);
        final statusColor = _getStatusColor(status);
        final isOwner = t.isOwnedByCurrentUser;

        return GestureDetector(
          onTap: () => _openTournamentDetail(t),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0D0D1A),
                      backgroundImage: (t.logoPath != null &&
                              t.logoPath!.isNotEmpty)
                          ? FileImage(File(t.logoPath!))
                          : null,
                      child: (t.logoPath == null || t.logoPath!.isEmpty)
                          ? const Icon(Icons.emoji_events,
                              color: Color(0xFF00BCD4), size: 22)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white38, size: 13),
                              const SizedBox(width: 2),
                              Text('${t.city} • ${t.ground}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12)),
                            ],
                          ),
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
                    if (isOwner) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        color: const Color(0xFF1A1A2E),
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white54),
                        onSelected: (value) {
                          if (value == 'edit') _editTournament(t);
                          if (value == 'delete') _deleteTournament(t);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined,
                                  color: Color(0xFF00BCD4), size: 18),
                              SizedBox(width: 8),
                              Text('Edit',
                                  style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(t.startDate)}  →  ${_formatDate(t.endDate)}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                        '${t.organizerName}  •  ${t.organizerPhone}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tournament Detail Page
// ═══════════════════════════════════════════════════════════════════════════

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
    'Matches',
    'Leaderboard',
    'Points Table',
    'Stats',
    'Teams',
    'About',
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
            title: Text(
              t.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white),
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
                        Text('Edit',
                            style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
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
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  tabs: _tabs
                      .map((label) =>
                          Tab(height: 46, child: Text(label)))
                      .toList(),
                ),
              ),
            ),
          ),
          // Sub-header: logo + name + dates + status + FORMAT BADGE
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
                          image: (t.logoPath != null &&
                                  t.logoPath!.isNotEmpty)
                              ? DecorationImage(
                                  image: FileImage(File(t.logoPath!)),
                                  fit: BoxFit.cover,
                                )
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
                            Text(
                              t.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateRange,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
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
                  // ── FORMAT BADGE shown under the header row ──────────────
                  const SizedBox(height: 10),
                  _FormatBadge(tournamentId: t.tournamentId),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _detailTabController,
          children: [
            _MatchesTab(tournament: widget.tournament),
            _LeaderboardTab(),
            _PointsTableTab(tournament: widget.tournament),
            _StatsTab(),
            _TeamsTab(tournament: widget.tournament),
            _AboutTab(tournament: widget.tournament),
          ],
        ),
      ),
    );
  }
}

// ── Format badge widget — reads format from Firestore ─────────────────────

class _FormatBadge extends StatelessWidget {
  final String tournamentId;
  const _FormatBadge({required this.tournamentId});

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

        final fmt = _kFormats.firstWhere(
          (f) => f.id == formatId,
          orElse: () => _kFormats.first,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFF00BCD4).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(fmt.icon, color: const Color(0xFF00BCD4), size: 13),
              const SizedBox(width: 6),
              Text(
                fmt.label,
                style: const TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Matches Tab ───────────────────────────────────────────────────────────

class _MatchesTab extends StatefulWidget {
  final Tournament tournament;
  const _MatchesTab({required this.tournament});

  @override
  State<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<_MatchesTab>
    with SingleTickerProviderStateMixin {
  late TabController _matchTabController;
  final List<String> _matchTabs = ['Live', 'Upcoming', 'Past'];

  @override
  void initState() {
    super.initState();
    _matchTabController =
        TabController(length: _matchTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _matchTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0D0D1A),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: AnimatedBuilder(
            animation: _matchTabController,
            builder: (_, __) => Row(
              children: List.generate(_matchTabs.length, (i) {
                final selected = _matchTabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _matchTabController.animateTo(i)),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8.0 : 0.0),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00BCD4)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _matchTabs[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white54,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _matchTabController,
            children: [
              _ScheduledMatchList(
                tournament: widget.tournament,
                filter: 'live',
              ),
              _ScheduledMatchList(
                tournament: widget.tournament,
                filter: 'upcoming',
              ),
              _ScheduledMatchList(
                tournament: widget.tournament,
                filter: 'past',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Leaderboard Tab ───────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
          child: Row(
            children: const [
              Expanded(child: _LeaderboardHeader('Top Batsmen')),
              SizedBox(width: 8),
              Expanded(child: _LeaderboardHeader('Top Bowlers')),
              SizedBox(width: 8),
              Expanded(child: _LeaderboardHeader('Top Fielders')),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(3, (col) {
                return Expanded(
                  child: Column(
                    children: List.generate(5, (row) {
                      return Container(
                        margin: EdgeInsets.only(
                            bottom: 8,
                            right: col < 2 ? 8.0 : 0.0),
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0D0D1A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D0D1A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'The tournament leaderboard will appear after the first match.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  final String title;
  const _LeaderboardHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Color(0xFF00BCD4),
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Points Table Tab ──────────────────────────────────────────────────────

class _PointsTableTab extends StatelessWidget {
  final Tournament tournament;
  const _PointsTableTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('League Matches (League Matches)',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('Team',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                _TableHeaderCell('M'),
                _TableHeaderCell('W'),
                _TableHeaderCell('L'),
                _TableHeaderCell('T'),
                _TableHeaderCell('NR'),
                _TableHeaderCell('Pt.'),
                _TableHeaderCell('NRR'),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('—',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12))),
                _TableCell('0'),
                _TableCell('0'),
                _TableCell('0'),
                _TableCell('0'),
                _TableCell('0'),
                _TableCell('0'),
                _TableCell('0.00'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Do you have a bonus points system?',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {},
            child: const Text('Show more',
                style: TextStyle(color: Color(0xFF00BCD4), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12)),
      );
}

// ── Stats Tab ─────────────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  int _selectedFilter = 0;
  final _filters = ['Overall', 'Best Spell', 'Most Runs'];

  final _statItems = const [
    ('Matches', '0', '0', '0'),
    ('Wickets', '0', '0', '0'),
    ('Runs', '0', '0', '0 LB RUNS'),
    ('SR / AVG', '0', '0', '0 LB RUNS'),
    ('Economy', '0', '0', '0 STRICTURES'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _selectedFilter == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF00BCD4)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_filters[i],
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white54,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _statItems.map((item) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.$1,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                          ),
                          Text(item.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Text(item.$3,
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12)),
                          const SizedBox(width: 16),
                          Text(item.$4,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    if (item != _statItems.last)
                      const Divider(color: Colors.white12, height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Stats will appear here once matches are scored in this tournament.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Teams Tab ─────────────────────────────────────────────────────────────

class _TeamsTab extends StatefulWidget {
  final Tournament tournament;
  const _TeamsTab({required this.tournament});

  @override
  State<_TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<_TeamsTab> {
  final _fs = FirestoreService.instance;
  List<TournamentTeam> _registeredTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegisteredTeams();
  }

  Future<void> _loadRegisteredTeams() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournament.tournamentId)
          .collection('teams')
          .orderBy('addedAt', descending: false)
          .get();

      if (mounted) {
        setState(() {
          _registeredTeams = snap.docs
              .map((d) => TournamentTeam(
                    tournamentId: d['tournamentId'] as String,
                    teamId: d['teamId'] as String,
                    teamName: d['teamName'] as String,
                    ownerUid: (d['ownerUid'] as String?) ?? '',
                    ownerName: (d['ownerName'] as String?) ?? '',
                    playerCount: (d['playerCount'] as int?) ?? 0,
                  ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Schedule generation button — only shown when ≥ 4 teams ─────────────
  void _showScheduleOptions() {
    if (_registeredTeams.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'You need at least 4 teams to generate a schedule automatically.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // BUG FIX 3: lock schedule generation to the tournament's saved format
    final tournamentFormat = widget.tournament.format;
    final lockedFormat = (tournamentFormat?.isNotEmpty == true)
        ? _kFormats.firstWhere(
            (f) => f.id == tournamentFormat,
            orElse: () => _kFormats.first,
          )
        : null;

    // If format is locked, generate immediately without showing a picker
    if (lockedFormat != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Generate Schedule',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '${_registeredTeams.length} teams registered. '
                'Schedule will be generated using the tournament format.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Lock banner showing the fixed format
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(lockedFormat.icon,
                        color: const Color(0xFF00BCD4), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lockedFormat.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(lockedFormat.tagline,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline,
                        color: Color(0xFF00BCD4), size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _generateAndSaveSchedule(lockedFormat.id);
                },
                child: const Text('Generate Now',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Fallback: no format was set at creation — show free-pick list
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Generate Schedule',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '${_registeredTeams.length} teams registered. '
              'Choose a format to auto-generate fixtures.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ..._kFormats.map((fmt) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _generateAndSaveSchedule(fmt.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00BCD4).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(fmt.icon,
                            color: const Color(0xFF00BCD4), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmt.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(fmt.tagline,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.white38),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSaveSchedule(String formatId) async {
    final matchups = _generateScheduleFromTeams(formatId, _registeredTeams);

    if (matchups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not generate schedule for selected format.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournament.tournamentId)
        .collection('matches');

    for (final pair in matchups) {
      final ref = col.doc();
      batch.set(ref, {
        'matchId': ref.id,
        'tournamentId': widget.tournament.tournamentId,
        'teamId1': pair[0].teamId,
        'teamId2': pair[1].teamId,
        'teamId1Name': pair[0].teamName,
        'teamId2Name': pair[1].teamName,
        'teamId1OwnerUid': pair[0].ownerUid,
        'teamId2OwnerUid': pair[1].ownerUid,
        'overs': 20,
        'isCompleted': false,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        'format': formatId,
      });
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${matchups.length} matches scheduled successfully!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error generating schedule: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
  void _showAddTeamModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
            ),
            const Text(
              'Add Team to Tournament',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _modalOption(
              icon: Icons.group,
              label: 'Add from My Teams',
              subtitle: 'Pick a team you already created',
              onTap: () {
                Navigator.pop(context);
                _showMyTeamsPicker();
              },
            ),
            const SizedBox(height: 12),
            _modalOption(
              icon: Icons.add_circle_outline,
              label: 'Create Team Manually',
              subtitle: 'Create a new team with players',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTournamentTeamPage(
                      tournament: widget.tournament,
                      onTeamAdded: _loadRegisteredTeams,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _modalOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF00BCD4), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyTeamsPicker() async {
    // BUG FIX 1: removed ownerUid one-team-per-user guard entirely.
    // Now only teamName uniqueness is enforced (same team name can't be
    // added twice, but the same user can add multiple different teams).
    final alreadyAddedNames =
        _registeredTeams.map((t) => t.teamName.toLowerCase()).toSet();

    List<Team> myTeams = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            if (loading) {
              _fs.getMyTeams().then((teams) {
                if (ctx.mounted) {
                  setSheet(() {
                    myTeams = teams;
                    loading = false;
                  });
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select a Team',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00BCD4)))
                        : myTeams.isEmpty
                            ? const Center(
                                child: Text(
                                  'No teams found.\nCreate one first from the Teams section.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                itemCount: myTeams.length,
                                itemBuilder: (_, i) {
                                  final team = myTeams[i];
                                  // BUG FIX 1: block only if the exact team
                                  // name is already registered (case-insensitive)
                                  final alreadyInTournament =
                                      alreadyAddedNames.contains(
                                          team.teamName.toLowerCase());
                                  return GestureDetector(
                                    onTap: alreadyInTournament
                                        ? null
                                        : () async {
                                            Navigator.pop(sheetCtx);
                                            await _addExistingTeam(team);
                                          },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 10),
                                      padding:
                                          const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: alreadyInTournament
                                            ? const Color(0xFF0D0D1A)
                                                .withOpacity(0.5)
                                            : const Color(0xFF0D0D1A),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: alreadyInTournament
                                              ? Colors.white12
                                              : const Color(0xFF00BCD4)
                                                  .withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.group,
                                              color: Color(0xFF00BCD4),
                                              size: 22),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              team.teamName,
                                              style: TextStyle(
                                                color: alreadyInTournament
                                                    ? Colors.white38
                                                    : Colors.white,
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (alreadyInTournament)
                                            const Text('Added',
                                                style: TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 12)),
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
        );
      },
    );
  }

  Future<void> _addExistingTeam(Team team) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      final members = await _fs.getPlayers(user.uid, team.teamId);
      await TournamentTeam.addTeamToTournament(
        tournamentId: widget.tournament.tournamentId,
        teamId: team.teamId,
        teamName: team.teamName,
        ownerUid: user.uid,
        ownerName: user.displayName ?? '',
        playerCount: members.length,
      );
      await _loadRegisteredTeams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${team.teamName}" added to tournament!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
    }

    return Stack(
      children: [
        _registeredTeams.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined,
                        color: Color(0xFF00BCD4), size: 52),
                    const SizedBox(height: 12),
                    const Text('No teams registered yet.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 14)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Team'),
                      onPressed: _showAddTeamModal,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: _registeredTeams.length,
                      itemBuilder: (_, i) =>
                          _buildTeamCard(_registeredTeams[i]),
                    ),
                  ),
                  // ── Schedule button — shown only when ≥ 4 teams ──────────
                  if (_registeredTeams.length >= 4)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(
                              color: Color(0xFF00BCD4), width: 1),
                        ),
                        icon: const Icon(Icons.auto_fix_high,
                            color: Color(0xFF00BCD4), size: 18),
                        label: const Text(
                          'Auto-Generate Schedule',
                          style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showScheduleOptions,
                      ),
                    ),
                  if (_registeredTeams.length < 4)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Add ${4 - _registeredTeams.length} more team(s) to unlock auto-scheduling.',
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        if (_registeredTeams.isNotEmpty)
          Positioned(
            bottom: 70,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00BCD4),
              onPressed: _showAddTeamModal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Team',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamCard(TournamentTeam team) {
    final isOwner = team.ownerUid ==
        (FirebaseAuth.instance.currentUser?.uid ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00BCD4).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group,
                color: Color(0xFF00BCD4), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.teamName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  '${team.playerCount} player${team.playerCount == 1 ? '' : 's'}  •  '
                  '${team.ownerName.isNotEmpty ? team.ownerName : 'Unknown'}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('You',
                  style: TextStyle(
                      color: Color(0xFF00BCD4), fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

// ── About Tab ─────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final Tournament tournament;
  const _AboutTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
          left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutSection(
            icon: Icons.emoji_events_outlined,
            title: 'Tournament Info',
            rows: [
              _AboutRow(label: 'Name', value: tournament.name),
              _AboutRow(label: 'City', value: tournament.city),
              _AboutRow(label: 'Venue', value: tournament.ground),
            ],
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.calendar_month,
            title: 'Schedule',
            rows: [
              _AboutRow(
                  label: 'Start Date', value: _fmt(tournament.startDate)),
              _AboutRow(
                  label: 'End Date', value: _fmt(tournament.endDate)),
              _AboutRow(
                label: 'Duration',
                value:
                    '${tournament.endDate.difference(tournament.startDate).inDays} days',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.person_outline,
            title: 'Organizer',
            rows: [
              _AboutRow(
                  label: 'Name', value: tournament.organizerName),
              _AboutRow(
                  label: 'Phone', value: tournament.organizerPhone),
            ],
          ),
          if (tournament.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.category_outlined,
              title: 'Categories',
              rows: tournament.categories
                  .map((c) => _AboutRow(label: '', value: c))
                  .toList(),
            ),
          ],
          if (tournament.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.label_outline,
                          color: Color(0xFF00BCD4), size: 20),
                      SizedBox(width: 8),
                      Text('Tags',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tournament.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00BCD4), width: 1),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: Color(0xFF00BCD4), fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // ── PRO FEATURE SUGGESTIONS ──────────────────────────────────────
          const _ProFeatureSuggestions(),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ── Pro Feature Suggestions Panel ─────────────────────────────────────────

class _ProFeatureSuggestions extends StatelessWidget {
  static const _features = [
    (
      Icons.live_tv,
      'Live Scoring',
      'Ball-by-ball scoring with real-time updates for spectators and players.',
      Color(0xFFE53935),
    ),
    (
      Icons.emoji_events,
      'Player of the Match Awards',
      'Auto-calculate and display POTM based on performance stats each game.',
      Color(0xFFFFB300),
    ),
    (
      Icons.bar_chart,
      'Advanced Analytics',
      'Win probability, wagon wheel, wagon wheel heatmaps and batting/bowling trends.',
      Color(0xFF00BCD4),
    ),
    (
      Icons.share,
      'Share Scorecard',
      'One-tap shareable scorecards as images for WhatsApp and Instagram.',
      Color(0xFF43A047),
    ),
    (
      Icons.notifications_active,
      'Match Reminders',
      'Push notifications to teams and fans before each match starts.',
      Color(0xFF8E24AA),
    ),
    (
      Icons.people_alt_outlined,
      'Fan Voting',
      'Let spectators vote for best player, best moment after every match.',
      Color(0xFFFF7043),
    ),
    (
      Icons.monetization_on_outlined,
      'Prize Pool Tracker',
      'Display prize distribution, sponsor logos and final standings.',
      Color(0xFFFFD600),
    ),
    (
      Icons.camera_alt_outlined,
      'Match Gallery',
      'Upload and share photos/videos from each match inside the app.',
      Color(0xFF00ACC1),
    ),
  ];

  const _ProFeatureSuggestions();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF00BCD4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.rocket_launch_outlined,
                  color: Color(0xFF00BCD4), size: 20),
              SizedBox(width: 8),
              Text('Pro Feature Ideas',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Coming soon — features that make your tournament stand out',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: f.$4.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.$1, color: f.$4, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(f.$3,
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_AboutRow> rows;

  const _AboutSection({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: row.label.isEmpty
                    ? Text(row.value,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(row.label,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            child: Text(row.value,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
              )),
        ],
      ),
    );
  }
}

class _AboutRow {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});
}

// ═══════════════════════════════════════════════════════════════════════════
// _ScheduledMatchList — top-level widget
// Shows matches filtered by 'live' | 'upcoming' | 'past'
// Three-dot menu on each card allows the tournament creator to edit/delete
// ═══════════════════════════════════════════════════════════════════════════

class _ScheduledMatchList extends StatelessWidget {
  final Tournament tournament;
  final String filter; // 'live' | 'upcoming' | 'past'

  const _ScheduledMatchList({
    required this.tournament,
    required this.filter,
  });

  // ── Check if current user is tournament creator ──────────────────────────
  bool get _isCreator {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return tournament.createdBy == uid;
  }

  // ── Edit a match (bottom sheet) ──────────────────────────────────────────
  void _editMatch(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final t1Ctrl =
        TextEditingController(text: (data['teamId1Name'] as String?) ?? '');
    final t2Ctrl =
        TextEditingController(text: (data['teamId2Name'] as String?) ?? '');
    final oversCtrl = TextEditingController(
        text: ((data['overs'] as int?) ?? 20).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Edit Match',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _sheetField(t1Ctrl, 'Team 1 Name', Icons.group_outlined),
              const SizedBox(height: 10),
              _sheetField(t2Ctrl, 'Team 2 Name', Icons.group_outlined),
              const SizedBox(height: 10),
              _sheetField(oversCtrl, 'Overs', Icons.sports_cricket,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final overs =
                      int.tryParse(oversCtrl.text.trim()) ?? 20;
                  try {
                    await FirebaseFirestore.instance
                        .collection('tournaments')
                        .doc(tournament.tournamentId)
                        .collection('matches')
                        .doc(doc.id)
                        .update({
                      'teamId1Name': t1Ctrl.text.trim(),
                      'teamId2Name': t2Ctrl.text.trim(),
                      'overs': overs,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Match updated.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
        filled: true,
        fillColor: const Color(0xFF0D0D1A),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Delete a match with confirmation ─────────────────────────────────────
  Future<void> _deleteMatch(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Match',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this match?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournament.tournamentId)
            .collection('matches')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match deleted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting match: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournament.tournamentId)
          .collection('matches')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF00BCD4)));
        }

        final docs = snap.data?.docs ?? [];
        final now = DateTime.now();

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isCompleted = (data['isCompleted'] as bool?) ?? false;
          final createdAt =
              (data['createdAt'] as Timestamp?)?.toDate();
          if (filter == 'past') return isCompleted;
          if (filter == 'live')
            return !isCompleted &&
                createdAt != null &&
                now.difference(createdAt).inHours < 6;
          return !isCompleted &&
              (createdAt == null ||
                  now.difference(createdAt).inHours >= 6);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter == 'live'
                      ? Icons.sports_cricket
                      : filter == 'upcoming'
                          ? Icons.schedule
                          : Icons.history,
                  color: (filter == 'live'
                          ? Colors.green
                          : filter == 'upcoming'
                              ? const Color(0xFF00BCD4)
                              : Colors.grey)
                      .withOpacity(0.4),
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  filter == 'live'
                      ? 'No live matches right now.'
                      : filter == 'upcoming'
                          ? 'No upcoming matches scheduled.'
                          : 'No past matches yet.',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Schedule Match'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamPage(
                          tournamentId: tournament.tournamentId,
                          tournamentName: tournament.name,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length + 1,
          itemBuilder: (context, i) {
            // Last item = Schedule Match button
            if (i == filtered.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Schedule Match'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamPage(
                            tournamentId: tournament.tournamentId,
                            tournamentName: tournament.name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }

            final doc = filtered[i];
            final data = doc.data() as Map<String, dynamic>;
            final team1Name =
                (data['teamId1Name'] as String?) ?? 'Team 1';
            final team2Name =
                (data['teamId2Name'] as String?) ?? 'Team 2';
            final overs = (data['overs'] as int?) ?? 0;
            final isCompleted =
                (data['isCompleted'] as bool?) ?? false;
            final createdAt =
                (data['createdAt'] as Timestamp?)?.toDate();

            // BUG FIX 2: read the format field saved per match and resolve label+icon
            final matchFormatId = (data['format'] as String?) ?? '';
            final matchFormat = matchFormatId.isNotEmpty
                ? _kFormats.firstWhere(
                    (f) => f.id == matchFormatId,
                    orElse: () => _kFormats.first,
                  )
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$team1Name  vs  $team2Name',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isCompleted
                                  ? Colors.grey
                                  : Colors.green),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'Completed' : 'Scheduled',
                          style: TextStyle(
                              color: isCompleted
                                  ? Colors.grey
                                  : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      // ── THREE-DOT MENU (creator only) ─────────────────────
                      if (_isCreator)
                        PopupMenuButton<String>(
                          color: const Color(0xFF1A1A2E),
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white54, size: 20),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editMatch(context, doc);
                            } else if (value == 'delete') {
                              _deleteMatch(context, doc.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined,
                                    color: Color(0xFF00BCD4), size: 18),
                                SizedBox(width: 8),
                                Text('Edit',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style:
                                        TextStyle(color: Colors.red)),
                              ]),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$overs overs',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  // BUG FIX 2: display format icon + label on the match card
                  if (matchFormat != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(matchFormat.icon,
                            color: const Color(0xFF00BCD4), size: 12),
                        const SizedBox(width: 5),
                        Text(
                          matchFormat.label,
                          style: const TextStyle(
                              color: Color(0xFF00BCD4), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Scheduled: ${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        '  ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}