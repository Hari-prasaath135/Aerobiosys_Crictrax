import 'dart:async';
import 'dart:io';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_detail_page.dart';
import 'package:TURF_TOWN_/src/Pages/Teams/Tournament/tournament_formats.dart';
import 'package:TURF_TOWN_/src/theme/tournament_colors.dart';
import 'package:TURF_TOWN_/src/widgets/empty_state_widget.dart';
import 'package:TURF_TOWN_/src/widgets/search_filter_bar.dart';
import 'package:TURF_TOWN_/src/widgets/section_header.dart';
import 'package:TURF_TOWN_/src/widgets/tournament_card.dart';
import 'package:TURF_TOWN_/src/widgets/tournament_logo_picker.dart';
import 'package:TURF_TOWN_/src/widgets/tournament_skeleton_card.dart';
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
  // ── Form controllers (unchanged) ──────────────────────────────────────
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

  // ── New: search & filter UI state (presentation-only, no business logic) ──
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribeToTournaments();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
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
    _searchController.dispose();
    super.dispose();
  }

  // ── Business logic (unchanged) ────────────────────────────────────────

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
        _showSnack('Location services are disabled.', TournamentColors.warning);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.', TournamentColors.warning);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack(
            'Location permission permanently denied. Enable it in settings.',
            TournamentColors.error);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
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
          duration: const Duration(seconds: 10),
          backgroundColor: TournamentColors.surfaceSecondary,
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
          setState(() => _cityController.text = city.toUpperCase());
          _showSnack('City auto-filled: ${city.toUpperCase()}', TournamentColors.success);
        } else {
          _showSnack('Could not determine city from location.', TournamentColors.warning);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnack('Location error: $e', TournamentColors.error);
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
          toolbarColor: TournamentColors.surfaceSecondary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: TournamentColors.primaryAccent,
          backgroundColor: TournamentColors.background,
          cropFrameColor: TournamentColors.primaryAccent,
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
      _showSnack('Please enter tournament name', TournamentColors.error);
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnack('Please enter city', TournamentColors.error);
      return false;
    }
    if (_groundController.text.trim().isEmpty) {
      _showSnack('Please enter ground name', TournamentColors.error);
      return false;
    }
    if (_organizerNameController.text.trim().isEmpty) {
      _showSnack('Please enter organizer name', TournamentColors.error);
      return false;
    }
    if (_organizerPhoneController.text.trim().length < 10) {
      _showSnack('Please enter valid phone number', TournamentColors.error);
      return false;
    }
    if (_startDate == null) {
      _showSnack('Please select start date', TournamentColors.error);
      return false;
    }
    if (_endDate == null) {
      _showSnack('Please select end date', TournamentColors.error);
      return false;
    }
    if (_endDate!.difference(_startDate!).inDays < 2) {
      _showSnack('Tournament must be at least 2 days long', TournamentColors.error);
      return false;
    }
    return true;
  }

  Future<void> _createTournament() async {
    if (!_validate()) return;
    if (Tournament.currentUserIsAnonymous) {
      _showSnack(
          'You must be signed in with a registered account to create a tournament.',
          TournamentColors.error);
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isCreating = true);

    try {
      final tournament = Tournament(
        tournamentId: Tournament.generateId(),
        name: _nameController.text.trim().toUpperCase(),
        city: _cityController.text.trim().toUpperCase(),
        ground: _groundController.text.trim().toUpperCase(),
        organizerName: _organizerNameController.text.trim().toUpperCase(),
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

      _showSnack('Tournament created successfully!', TournamentColors.success);
      _tabController.animateTo(1);
    } catch (e) {
      _showSnack('Error creating tournament: $e', TournamentColors.error);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteTournament(Tournament t) async {
    if (!t.isOwnedByCurrentUser) {
      _showSnack('You can only delete your own tournaments.', TournamentColors.error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TournamentColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Tournament',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${t.name}"?',
            style: const TextStyle(color: TournamentColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: TournamentColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: TournamentColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Tournament.delete(t.tournamentId);
        _showSnack('Tournament deleted', TournamentColors.warning);
      } catch (e) {
        _showSnack('Error deleting tournament: $e', TournamentColors.error);
      }
    }
  }

  void _editTournament(Tournament t) {
    if (!t.isOwnedByCurrentUser) {
      _showSnack('You can only edit your own tournaments.', TournamentColors.error);
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
        TournamentColors.primaryAccent);
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

  Color _getStatusColor(String status) => TournamentColors.statusColor(status);

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

  // ── Presentation-only helper: filtered list for search & status chips ──
  List<Tournament> get _filteredTournaments {
    return _tournaments.where((t) {
      final matchesStatus =
          _selectedFilter == 'All' || _getStatus(t) == _selectedFilter;
      if (!matchesStatus) return false;
      if (_searchQuery.isEmpty) return true;
      final haystack =
          '${t.name} ${t.city} ${t.ground} ${t.organizerName}'.toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TournamentColors.background,
      appBar: AppBar(
        backgroundColor: TournamentColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: TournamentColors.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Tournaments',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: TournamentColors.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: TournamentColors.accentGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              splashBorderRadius: BorderRadius.circular(30),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: TournamentColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
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
      return EmptyStateWidget(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in required',
        message:
            'Please sign in with a registered account to create tournaments.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TournamentLogoPicker(
              logoFile: _logoFile,
              logoPath: _logoPath,
              onTap: _pickLogo,
            ),
          ),
          const SizedBox(height: 22),
          _buildSectionCard(
            icon: Icons.info_outline_rounded,
            title: 'Tournament Details',
            subtitle: 'Name, city and venue',
            children: [
              _buildStyledField(_nameController, 'Tournament Name',
                  Icons.emoji_events_outlined),
              _buildCityFieldWithLocationButton(),
              _buildStyledField(
                  _groundController, 'Ground / Venue', Icons.stadium_outlined),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Organizer Details',
            subtitle: 'Who to contact about this tournament',
            children: [
              _buildStyledField(_organizerNameController, 'Organizer Name',
                  Icons.person_outline),
              _buildStyledField(_organizerPhoneController, 'Phone Number',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.calendar_month_rounded,
            title: 'Schedule',
            subtitle: 'Minimum 2-day duration',
            children: [
              _buildStyledDateRow('Start Date', _startDate,
                  (d) => setState(() => _startDate = d)),
              _buildStyledDateRow('End Date', _endDate,
                  (d) => setState(() => _endDate = d)),
            ],
          ),
          const SizedBox(height: 14),
          _buildSectionCard(
            icon: Icons.groups_outlined,
            title: 'Teams',
            subtitle: 'Optional capacity limit',
            children: [
              _buildStyledField(
                _maxTeamsController,
                'Maximum Teams (e.g. 8, 16 — leave blank for unlimited)',
                Icons.groups_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 26),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: TournamentColors.accentGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: TournamentColors.primaryAccent.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isCreating ? null : _createTournament,
        child: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Create Tournament',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'City',
                hintStyle: const TextStyle(color: TournamentColors.textSecondary),
                prefixIcon: const Icon(Icons.location_city_rounded,
                    color: TournamentColors.primaryAccent, size: 20),
                filled: true,
                fillColor: TournamentColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                color: TournamentColors.primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: TournamentColors.primaryAccent.withOpacity(0.4)),
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: TournamentColors.primaryAccent, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TournamentColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: icon, title: title, subtitle: subtitle),
          const SizedBox(height: 14),
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
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: TournamentColors.textSecondary),
          prefixIcon:
              Icon(icon, color: TournamentColors.primaryAccent, size: 20),
          filled: true,
          fillColor: TournamentColors.background,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStyledDateRow(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
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
                  primary: TournamentColors.primaryAccent,
                  surface: TournamentColors.surface,
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
            color: TournamentColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: TournamentColors.primaryAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value == null ? label : '$label: ${_formatDate(value)}',
                  style: TextStyle(
                    color: value == null
                        ? TournamentColors.textSecondary
                        : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const Text('Select',
                  style: TextStyle(
                      color: TournamentColors.textSecondary, fontSize: 13)),
              const Icon(Icons.arrow_drop_down_rounded,
                  color: TournamentColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ── List Tab ────────────────────────────────────────────────────────────

  Widget _buildListTab() {
    if (_loadError != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        message: _loadError!,
        iconColor: TournamentColors.error,
      );
    }

    if (_isLoadingTournaments) {
      return ListView.builder(
        padding:
            const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 120),
        itemCount: 4,
        itemBuilder: (context, i) => const TournamentSkeletonCard(),
      );
    }

    if (_tournaments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.emoji_events_outlined,
        title: 'No tournaments yet',
        message:
            'Create your first tournament from the Create New tab to see it listed here.',
      );
    }

    final filtered = _filteredTournaments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SearchFilterBar(
            controller: _searchController,
            onChanged: (_) {}, // handled via controller listener above
            selectedFilter: _selectedFilter,
            onFilterSelected: (f) => setState(() => _selectedFilter = f),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  message: 'Try a different search term or filter.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 4, bottom: 120),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    final status = _getStatus(t);
                    return TournamentCard(
                      tournament: t,
                      status: status,
                      formatDate: _formatDate,
                      index: i,
                      onTap: () => _openTournamentDetail(t),
                      onEdit: () => _editTournament(t),
                      onDelete: () => _deleteTournament(t),
                    );
                  },
                ),
        ),
      ],
    );
  }
}