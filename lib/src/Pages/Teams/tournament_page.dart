import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:TURF_TOWN_/src/models/tournament_model.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _groundController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerPhoneController = TextEditingController();
  final _categoryInputController = TextEditingController();
  final _tagInputController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _logoPath;
  List<String> _categories = [];
  List<String> _tags = [];
  bool _isCreating = false;

  List<Tournament> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    final list = await Tournament.getAll();
    setState(() {
      _tournaments = list.reversed.toList();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _groundController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    _categoryInputController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _logoPath = picked.path);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? now
          : (_startDate ?? now).add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00C4FF),
            surface: Color(0xFF1C2026),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addCategory() {
    final val = _categoryInputController.text.trim();
    if (val.isEmpty) return;
    if (_categories.contains(val)) {
      _showSnack('Category already added', Colors.orange);
      return;
    }
    setState(() => _categories.add(val));
    _categoryInputController.clear();
  }

  void _addTag() {
    final val = _tagInputController.text.trim();
    if (val.isEmpty) return;
    if (_tags.contains(val)) {
      _showSnack('Tag already added', Colors.orange);
      return;
    }
    setState(() => _tags.add(val));
    _tagInputController.clear();
  }

  Future<void> _createTournament() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter tournament name', Colors.red);
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnack('Please enter city', Colors.red);
      return;
    }
    if (_groundController.text.trim().isEmpty) {
      _showSnack('Please enter ground name', Colors.red);
      return;
    }
    if (_organizerNameController.text.trim().isEmpty) {
      _showSnack('Please enter organizer name', Colors.red);
      return;
    }
    if (_organizerPhoneController.text.trim().length < 10) {
      _showSnack('Please enter valid phone number', Colors.red);
      return;
    }
    if (_startDate == null) {
      _showSnack('Please select start date', Colors.red);
      return;
    }
    if (_endDate == null) {
      _showSnack('Please select end date', Colors.red);
      return;
    }

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
      );

      await Tournament.save(tournament);
      await _loadTournaments();

      _nameController.clear();
      _cityController.clear();
      _groundController.clear();
      _organizerNameController.clear();
      _organizerPhoneController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _logoPath = null;
        _categories = [];
        _tags = [];
      });

      _showSnack('Tournament created successfully!', Colors.green);
      _tabController.animateTo(1);
    } catch (e) {
      _showSnack('Error creating tournament: $e', Colors.red);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF000000)],
            stops: [0.0, 0.1, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreateForm(),
                    _buildTournamentList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.emoji_events, color: Color(0xFF00C4FF), size: 28),
          const SizedBox(width: 10),
          Text(
            'Tournaments',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00C4FF),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Create New'),
          Tab(text: 'All Tournaments'),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLogoPicker(),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Tournament Info',
            icon: Icons.info_outline,
            children: [
              _buildTextField(
                  _nameController, 'Tournament Name', Icons.military_tech),
              const SizedBox(height: 12),
              _buildTextField(_cityController, 'City', Icons.location_city),
              const SizedBox(height: 12),
              _buildTextField(
                  _groundController, 'Ground / Venue', Icons.stadium),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Organizer Details',
            icon: Icons.person,
            children: [
              _buildTextField(_organizerNameController, 'Organizer Name',
                  Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(
                _organizerPhoneController,
                'Phone Number',
                Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Schedule',
            icon: Icons.calendar_month,
            children: [
              _buildDateRow(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 12),
              _buildDateRow(
                label: 'End Date',
                date: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Categories',
            icon: Icons.category,
            children: [
              _buildChipInput(
                controller: _categoryInputController,
                hint: 'e.g. Under-19, Open',
                onAdd: _addCategory,
                items: _categories,
                onRemove: (val) => setState(() => _categories.remove(val)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Tags',
            icon: Icons.label,
            children: [
              _buildChipInput(
                controller: _tagInputController,
                hint: 'e.g. T20, Knockout',
                onAdd: _addTag,
                items: _tags,
                onRemove: (val) => setState(() => _tags.remove(val)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCreateButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLogoPicker() {
    return GestureDetector(
      onTap: _pickLogo,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2026),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00C4FF), width: 2),
        ),
        child: _logoPath != null
            ? ClipOval(
                child: Image.file(
                  File(_logoPath!),
                  fit: BoxFit.cover,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo,
                      color: Color(0xFF00C4FF), size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Logo',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00C4FF), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style:
          const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Colors.white38, fontFamily: 'Poppins'),
        prefixIcon:
            Icon(icon, color: const Color(0xFF00C4FF), size: 20),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF00C4FF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final fmt = DateFormat('dd MMM yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: Color(0xFF00C4FF), size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Poppins',
                  fontSize: 13),
            ),
            const Spacer(),
            Text(
              date != null ? fmt.format(date) : 'Select',
              style: TextStyle(
                color: date != null ? Colors.white : Colors.white38,
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: date != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildChipInput({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required List<String> items,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontFamily: 'Poppins',
                      fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF00C4FF), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items
                .map((item) => Chip(
                      label: Text(item,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 12)),
                      backgroundColor:
                          const Color(0xFF00C4FF).withOpacity(0.2),
                      deleteIconColor: Colors.white54,
                      side: const BorderSide(
                          color: Color(0xFF00C4FF), width: 0.8),
                      onDeleted: () => onRemove(item),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createTournament,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C4FF),
          disabledBackgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
        child: _isCreating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'Create Tournament',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTournamentList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF00C4FF)));
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'No tournaments yet',
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tournament!',
              style: GoogleFonts.poppins(
                  color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tournaments.length,
      itemBuilder: (context, index) =>
          _buildTournamentCard(_tournaments[index]),
    );
  }

  Widget _buildTournamentCard(Tournament t) {
    final fmt = DateFormat('dd MMM yyyy');
    final isActive = DateTime.now().isBefore(t.endDate) &&
        DateTime.now().isAfter(t.startDate);
    final isUpcoming = DateTime.now().isBefore(t.startDate);

    String status =
        isActive ? 'Active' : isUpcoming ? 'Upcoming' : 'Completed';
    Color statusColor = isActive
        ? Colors.green
        : isUpcoming
            ? const Color(0xFF00C4FF)
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFF00C4FF).withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF00C4FF), width: 1.5),
                  ),
                  child: t.logoPath != null
                      ? ClipOval(
                          child: Image.file(File(t.logoPath!),
                              fit: BoxFit.cover))
                      : const Icon(Icons.emoji_events,
                          color: Color(0xFF00C4FF), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white38, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${t.city} • ${t.ground}',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor, width: 0.8),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(
                  Icons.calendar_today,
                  '${fmt.format(t.startDate)} → ${fmt.format(t.endDate)}',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person,
                    color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${t.organizerName}  •  ${t.organizerPhone}',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            if (t.categories.isNotEmpty || t.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...t.categories.map(
                      (c) => _smallChip(c, const Color(0xFF00C4FF))),
                  ...t.tags
                      .map((tag) => _smallChip(tag, Colors.orange)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _smallChip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withOpacity(0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}