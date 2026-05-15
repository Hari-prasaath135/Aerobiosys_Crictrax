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
    // Minimum 2 days eligibility check
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

  /// Returns status label based on dates
  String _getStatus(Tournament t) {
    final now = DateTime.now();
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
          // Logo picker
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

          // Tournament Info Card
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

          // Organizer Details Card
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

          // Schedule Card
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
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day); // only present & future

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? firstDate,
            firstDate: firstDate,           // freeze past dates
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
        final t = _tournaments[i];
        final status = _getStatus(t);
        final statusColor = _getStatusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: logo + name + status + 3-dot menu
              Row(
                children: [
                  // Logo / avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0D0D1A),
                    child: t.logoPath != null
                        ? null // TODO: show image
                        : const Icon(Icons.emoji_events,
                            color: Color(0xFF00BCD4), size: 22),
                  ),
                  const SizedBox(width: 10),
                  // Name + location
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
                  // Status badge
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
                  // Three-dot menu
                  PopupMenuButton<String>(
                    color: const Color(0xFF1A1A2E),
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) {
                      if (value == 'delete') _deleteTournament(t);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
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
              // Date row
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
              // Organizer row
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
        );
      },
    );
  }
}