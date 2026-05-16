import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tournament_model.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage>
    with SingleTickerProviderStateMixin {

  final _nameController           = TextEditingController();
  final _cityController           = TextEditingController();
  final _groundController         = TextEditingController();
  final _organizerNameController  = TextEditingController();
  final _organizerPhoneController = TextEditingController();

  DateTime?    _startDate;
  DateTime?    _endDate;
  String?      _logoPath;
  List<String> _categories = [];
  List<String> _tags       = [];
  bool         _isCreating = false;
  late TabController _tabController;
  List<Tournament>   _tournaments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _groundController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _loadTournaments() async {
    final list = await Tournament.getAll();
    setState(() => _tournaments = list);
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
    final diff = _endDate!.difference(_startDate!).inDays;
    if (diff < 2) {
      _showSnack('Tournament must be at least 2 days long', Colors.red);
      return false;
    }
    return true;
  }

  Future<void> _createTournament() async {
    if (!_validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('You must be logged in to create a tournament', Colors.red);
      return;
    }

    setState(() => _isCreating = true);

    try {
      final tournament = Tournament(
        tournamentId:   Tournament.generateId(),
        name:           _nameController.text.trim(),
        city:           _cityController.text.trim(),
        ground:         _groundController.text.trim(),
        organizerName:  _organizerNameController.text.trim(),
        organizerPhone: _organizerPhoneController.text.trim(),
        startDate:      _startDate!,
        endDate:        _endDate!,
        categories:     List.from(_categories),
        tags:           List.from(_tags),
        logoPath:       _logoPath,
        createdAt:      DateTime.now(),
      );

      await Tournament.save(tournament);
      await _loadTournaments();

      setState(() {
        _startDate  = null;
        _endDate    = null;
        _logoPath   = null;
        _categories = [];
        _tags       = [];
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Tournament', style: TextStyle(color: Colors.white)),
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
        await _loadTournaments();
        _showSnack('Tournament deleted', Colors.orange);
      } catch (e) {
        _showSnack('Error deleting tournament: $e', Colors.red);
      }
    }
  }

  // ─── Edit Tournament ──────────────────────────────────────────────────────

  void _editTournament(Tournament t) {
    _nameController.text           = t.name;
    _cityController.text           = t.city;
    _groundController.text         = t.ground;
    _organizerNameController.text  = t.organizerName;
    _organizerPhoneController.text = t.organizerPhone;
    setState(() {
      _startDate  = t.startDate;
      _endDate    = t.endDate;
      _logoPath   = t.logoPath;
      _categories = List.from(t.categories);
      _tags       = List.from(t.tags);
    });
    _tabController.animateTo(0);
    _showSnack('Edit the fields and tap Create Tournament to save changes.',
        const Color(0xFF00BCD4));
  }

  String _getStatus(Tournament t) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
    final end   = DateTime(t.endDate.year,   t.endDate.month,   t.endDate.day);

    if (today.isBefore(start)) return 'Upcoming';
    if (today.isAfter(end))    return 'Completed';
    return 'Live';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Live':      return Colors.green;
      case 'Upcoming':  return const Color(0xFF00BCD4);
      case 'Completed': return Colors.grey;
      default:          return Colors.grey;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  // ─── Navigate to Tournament Detail ────────────────────────────────────────

  void _openTournamentDetail(Tournament t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentDetailPage(
          tournament: t,
          formatDate: _formatDate,
          getStatus: _getStatus,
          getStatusColor: _getStatusColor,
          onDelete: () async {
            await _deleteTournament(t);
          },
          onEdit: () {
            Navigator.pop(context);
            _editTournament(t);
          },
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Color(0xFF00BCD4)),
            SizedBox(width: 8),
            Text('Tournaments',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ─── Create Tab ───────────────────────────────────────────────────────────

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                // TODO: implement image picker
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(color: const Color(0xFF00BCD4), width: 2),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Color(0xFF00BCD4), size: 32),
                    SizedBox(height: 4),
                    Text('Logo', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            icon: Icons.info_outline,
            title: 'Tournament Info',
            children: [
              _buildStyledField(_nameController,  'Tournament Name', Icons.emoji_events_outlined),
              _buildStyledField(_cityController,   'City',           Icons.location_city),
              _buildStyledField(_groundController, 'Ground / Venue', Icons.stadium_outlined),
            ],
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.person_outline,
            title: 'Organizer Details',
            children: [
              _buildStyledField(_organizerNameController,  'Organizer Name', Icons.person_outline),
              _buildStyledField(_organizerPhoneController, 'Phone Number',   Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
            ],
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.calendar_month,
            title: 'Schedule',
            children: [
              _buildStyledDateRow('Start Date', _startDate, (d) => setState(() => _startDate = d),
                  isStart: true),
              _buildStyledDateRow('End Date', _endDate, (d) => setState(() => _endDate = d),
                  isStart: false),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isCreating ? null : _createTournament,
            child: _isCreating
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Tournament',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
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
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
    final today     = DateTime.now();
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF00BCD4), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value == null ? label : '$label: ${_formatDate(value)}',
                  style: TextStyle(
                    color: value == null ? Colors.white38 : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const Text('Select', style: TextStyle(color: Colors.white38, fontSize: 13)),
              const Icon(Icons.arrow_drop_down, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // ─── List Tab ─────────────────────────────────────────────────────────────

  Widget _buildListTab() {
    if (_tournaments.isEmpty) {
      return const Center(
        child: Text('No tournaments yet.', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tournaments.length,
      itemBuilder: (context, i) {
        final t           = _tournaments[i];
        final status      = _getStatus(t);
        final statusColor = _getStatusColor(status);

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
                      child: t.logoPath != null
                          ? null
                          : const Icon(Icons.emoji_events,
                              color: Color(0xFF00BCD4), size: 22),
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
                                      color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const SizedBox(width: 4),
                    // ── 3-dot menu on list card ───────────────────────
                    PopupMenuButton<String>(
                      color: const Color(0xFF1A1A2E),
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      onSelected: (value) {
                        if (value == 'edit')   _editTournament(t);
                        if (value == 'delete') _deleteTournament(t);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: Color(0xFF00BCD4), size: 18),
                              SizedBox(width: 8),
                              Text('Edit',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(t.startDate)}  →  ${_formatDate(t.endDate)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text('${t.organizerName}  •  ${t.organizerPhone}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
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
// Tabs: Matches / Leaderboard / Points Table / Stats / Teams
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

  // 6 tabs — Heroes and Sponsors removed per request, About added
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
    final status      = widget.getStatus(widget.tournament);
    final statusColor = widget.getStatusColor(status);
    final t           = widget.tournament;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── 1. Plain pinned AppBar (no FlexibleSpaceBar, no clipping) ──
          SliverAppBar(
            backgroundColor: const Color(0xFF1A237E),
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            leading: const BackButton(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
              // ── 3-dot menu (Edit + Delete) ──────────────────────────
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
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: Color(0xFF00BCD4), size: 18),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            // ── Sticky tab bar ────────────────────────────────────────
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
                      .map((label) => Tab(height: 46, child: Text(label)))
                      .toList(),
                ),
              ),
            ),
          ),

          // ── 2. Logo + info row — lives BELOW the AppBar, never clipped ──
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF1A237E),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo — full circle, guaranteed no clipping
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D0D1A),
                      border: Border.all(
                          color: const Color(0xFF00BCD4), width: 2),
                    ),
                    child: t.logoPath != null
                        ? ClipOval(
                            child: Image.asset(t.logoPath!,
                                fit: BoxFit.cover))
                        : const Icon(Icons.emoji_events,
                            color: Color(0xFF00BCD4), size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(_dateRange,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Status badge
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
            ),
          ),
        ],

        // ── Tab bodies ────────────────────────────────────────────────
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

// ── Matches Tab (Live / Upcoming / Past sub-tabs) ─────────────────────────

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
    _matchTabController = TabController(length: _matchTabs.length, vsync: this);
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
        // Sub-tab row: Live / Upcoming / Past
        Container(
          color: const Color(0xFF0D0D1A),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
              _emptyMatchState('No live matches right now.',
                  Icons.sports_cricket, Colors.green),
              _emptyMatchState('No upcoming matches scheduled.',
                  Icons.schedule, const Color(0xFF00BCD4)),
              _emptyMatchState('No past matches yet.',
                  Icons.history, Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyMatchState(String msg, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.4), size: 52),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Start a Match'),
            onPressed: () {
              // TODO: navigate to start-match flow
            },
          ),
        ],
      ),
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
                            bottom: 8, right: col < 2 ? 8.0 : 0.0),
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
          // Table header
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
          // Placeholder row
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
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
    ('Matches',  '0', '0', '0'),
    ('Wickets',  '0', '0', '0'),
    ('Runs',     '0', '0', '0 LB RUNS'),
    ('SR / AVG', '0', '0', '0 LB RUNS'),
    ('Economy',  '0', '0', '0 STRICTURES'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
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
          // Stats rows
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
                                    color: Colors.white70, fontSize: 13)),
                          ),
                          Text(item.$2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Text(item.$3,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                          const SizedBox(width: 16),
                          Text(item.$4,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
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

class _TeamsTab extends StatelessWidget {
  final Tournament tournament;
  const _TeamsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined,
              color: Color(0xFF00BCD4), size: 52),
          const SizedBox(height: 12),
          const Text('No teams registered yet.',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
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
            onPressed: () {
              // TODO: team add flow
            },
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Info card
          _AboutSection(
            icon: Icons.emoji_events_outlined,
            title: 'Tournament Info',
            rows: [
              _AboutRow(label: 'Name',  value: tournament.name),
              _AboutRow(label: 'City',  value: tournament.city),
              _AboutRow(label: 'Venue', value: tournament.ground),
            ],
          ),
          const SizedBox(height: 12),

          // Schedule card
          _AboutSection(
            icon: Icons.calendar_month,
            title: 'Schedule',
            rows: [
              _AboutRow(
                label: 'Start Date',
                value: _fmt(tournament.startDate),
              ),
              _AboutRow(
                label: 'End Date',
                value: _fmt(tournament.endDate),
              ),
              _AboutRow(
                label: 'Duration',
                value:
                    '${tournament.endDate.difference(tournament.startDate).inDays} days',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Organizer card
          _AboutSection(
            icon: Icons.person_outline,
            title: 'Organizer',
            rows: [
              _AboutRow(label: 'Name',  value: tournament.organizerName),
              _AboutRow(label: 'Phone', value: tournament.organizerPhone),
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
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
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
                                    color: Colors.white38, fontSize: 13)),
                          ),
                          Expanded(
                            child: Text(row.value,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
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