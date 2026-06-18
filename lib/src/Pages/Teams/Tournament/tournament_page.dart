import 'dart:async';
import 'dart:io';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_detail_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';


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
  final _maxTeamsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  File? _logoFile;
  String? _logoPath;
  List<String> _categories = [];
  List<String> _tags = [];
  bool _isCreating = false;


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
    _maxTeamsController.dispose();
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

  Future<void> _fetchAndFillCity() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.', Colors.orange);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.', Colors.orange);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack(
            'Location permission permanently denied. Enable it in settings.',
            Colors.red);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Detecting your location...'),
            ],
          ),
          duration: Duration(seconds: 10),
          backgroundColor: Color(0xFF1A237E),
        ),
      );

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final city = (placemark.locality?.isNotEmpty == true)
            ? placemark.locality!
            : (placemark.subAdministrativeArea?.isNotEmpty == true)
                ? placemark.subAdministrativeArea!
                : (placemark.administrativeArea ?? '');

        if (city.isNotEmpty) {
          setState(() => _cityController.text = city);
          _showSnack('City auto-filled: $city', Colors.green);
        } else {
          _showSnack('Could not determine city from location.', Colors.orange);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnack('Location error: $e', Colors.red);
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
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
          backgroundColor: const Color(0xFF0D0D1A),
          cropFrameColor: const Color(0xFF00BCD4),
          cropGridColor: Colors.white24,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Logo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped == null || !mounted) return;
    setState(() {
      _logoFile = File(cropped.path);
      _logoPath = cropped.path;
    });
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
  
  maxTeams: int.tryParse(_maxTeamsController.text.trim()) ?? 0,
);

      await Tournament.save(tournament);

     setState(() {
  _startDate = null;
  _endDate = null;
  _logoFile = null;
  _logoPath = null;
  _categories = [];
  _tags = [];
});
      _nameController.clear();
      _cityController.clear();
      _groundController.clear();
      _organizerNameController.clear();
      _organizerPhoneController.clear();
      _maxTeamsController.clear();

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
   _maxTeamsController.text = t.maxTeams > 0 ? t.maxTeams.toString() : '';
    setState(() {
  _startDate = t.startDate;
  _endDate = t.endDate;
  _logoPath = t.logoPath;
  _logoFile = null;
  _categories = List.from(t.categories);
  _tags = List.from(t.tags);
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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
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

  // ── Create Tab ──────────────────────────────────────────────────────────

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
    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
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
                    border: Border.all(color: const Color(0xFF00BCD4), width: 2),
                    image: _logoFile != null
                        ? DecorationImage(
                            image: FileImage(_logoFile!), fit: BoxFit.cover)
                        : (_logoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_logoPath!)),
                                fit: BoxFit.cover)
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
                        color: Color(0xFF00BCD4), shape: BoxShape.circle),
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
            _buildCityFieldWithLocationButton(),
            _buildStyledField(
                _groundController, 'Ground / Venue', Icons.stadium_outlined),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          icon: Icons.person_outline,
          title: 'Organizer Details',
          children: [
            _buildStyledField(_organizerNameController, 'Organizer Name',
                Icons.person_outline),
            _buildStyledField(_organizerPhoneController, 'Phone Number',
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
          icon: Icons.groups_outlined,
          title: 'Teams',
          children: [
            _buildStyledField(
              _maxTeamsController,
              'Maximum Teams (e.g. 8, 16 — leave blank for unlimited)',
              Icons.groups_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
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
  Widget _buildCityFieldWithLocationButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'City',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.location_city,
                    color: Color(0xFF00BCD4), size: 20),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _fetchAndFillCity,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.4)),
              ),
              child: const Icon(Icons.my_location,
                  color: Color(0xFF00BCD4), size: 22),
            ),
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
          prefixIcon:
              Icon(icon, color: const Color(0xFF00BCD4), size: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

  // ── List Tab ────────────────────────────────────────────────────────────

  Widget _buildListTab() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 15)),
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
      padding:
          const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 120),
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
                      backgroundImage:
                          (t.logoPath != null && t.logoPath!.isNotEmpty)
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
                                      color: Colors.white38, fontSize: 12)),
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
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text('${t.organizerName}  •  ${t.organizerPhone}',
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