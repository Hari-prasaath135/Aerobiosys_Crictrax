import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:TURF_TOWN_/src/Menus/setting.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Data Model ---
class TurfItem {
  final String imagePath;
  final String title;
  final String subtitle;
  final String rating;
  final String description;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;

  TurfItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.description,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  String get id => title;
}

class CricketScorerHeader extends StatefulWidget {
  const CricketScorerHeader({super.key});

  @override
  State<CricketScorerHeader> createState() => _CricketScorerHeaderState();
}

class _CricketScorerHeaderState extends State<CricketScorerHeader> {
  static const Color accentColor = Colors.white;
  static const Color searchBarBackgroundColor = Color(0xFF545454);
  static const double iconSize = 25.0;
  static const Color dividerColor = Color(0xFFFFFFFF);
  static const Color favouritesContainerColor = Color(0xFFD9D9D9);

  int _selectedIndex = 2;
  
  // Initialize PageController if you're using it for navigation
  late PageController _pageController;

  final List<TurfItem> _allTurfs = [
    TurfItem(
      imagePath: 'assets/images/cricket_ground_1.png.jpg',
      title: 'Goat Sports...',
      subtitle: 'Lawspet',
      rating: '4.5',
      description: 'Premium cricket turf with international standard pitch. Well-maintained grass surface with excellent drainage system and floodlights for night matches.',
      address: 'No. 45, MG Road, Lawspet, Puducherry - 605008',
      phone: '+91 9876543210',
      latitude: 11.9416,
      longitude: 79.8083,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_2.png.jpg',
      title: 'The Sports S...',
      subtitle: 'Kottakuppam',
      rating: '4.0',
      description: 'Modern sports facility with multiple playing areas. Features include changing rooms, seating area, and professional coaching available.',
      address: 'Beach Road, Kottakuppam, Puducherry - 605104',
      phone: '+91 9876543211',
      latitude: 11.9500,
      longitude: 79.8300,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_10.png.jpeg',
      title: 'Providence Turf',
      subtitle: 'Gorimedu',
      rating: '4.6',
      description: 'State-of-the-art turf with artificial grass and modern amenities. Perfect for professional practice sessions and tournaments.',
      address: '123, Providence Street, Gorimedu, Puducherry - 605006',
      phone: '+91 9876543212',
      latitude: 11.9350,
      longitude: 79.8250,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_4.png.jpg',
      title: 'Turf 10',
      subtitle: 'Ellaipillaichavady ~ 3.5km',
      rating: '4.2',
      description: 'Spacious turf ground with quality pitch and boundary markings. Ideal for weekend matches and practice sessions.',
      address: 'ECR Road, Ellaipillaichavady, Puducherry - 605014',
      phone: '+91 9876543213',
      latitude: 11.9600,
      longitude: 79.8400,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_6.png.png',
      title: 'Pondy Pitch',
      subtitle: 'Ariyankuppam ~ 7.3km',
      rating: '4.8',
      description: 'Premium cricket facility with professional grade turf. Equipped with pavilion, scoreboard, and refreshment area.',
      address: 'NH-45A, Ariyankuppam, Puducherry - 605007',
      phone: '+91 9876543214',
      latitude: 11.9700,
      longitude: 79.8500,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_7.png.png',
      title: 'Goat Sports Arena',
      subtitle: 'Lawspet ~ 0.7km',
      rating: '4.8',
      description: 'Top-rated sports arena with excellent facilities. Features include parking, cafeteria, and equipment rental.',
      address: '78, Arena Complex, Lawspet, Puducherry - 605008',
      phone: '+91 9876543215',
      latitude: 11.9420,
      longitude: 79.8090,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_8.png.png',
      title: 'Lotus',
      subtitle: 'Lawspet ~ 0.5km',
      rating: '4.1',
      description: 'Community cricket ground with natural grass pitch. Affordable rates and flexible booking options available.',
      address: 'Lotus Gardens, Lawspet, Puducherry - 605008',
      phone: '+91 9876543216',
      latitude: 11.9410,
      longitude: 79.8080,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_9.png.png',
      title: 'Aadukalam',
      subtitle: 'Lawspet ~ 0.5km',
      rating: '3.7',
      description: 'Budget-friendly cricket ground suitable for casual matches. Basic facilities with good playing surface.',
      address: 'Aadukalam Street, Lawspet, Puducherry - 605008',
      phone: '+91 9876543217',
      latitude: 11.9400,
      longitude: 79.8070,
    ),
    TurfItem(
      imagePath: 'assets/images/cricket_ground_4.png.jpg',
      title: 'The Sports Studio',
      subtitle: 'Lawspet ~ 0.5km',
      rating: '4.5',
      description: 'Multi-sport facility with dedicated cricket area. Professional coaching and training programs available.',
      address: 'Studio Lane, Lawspet, Puducherry - 605008',
      phone: '+91 9876543218',
      latitude: 11.9430,
      longitude: 79.8085,
    ),
  ];

  final List<String> _favoriteTurfIds = ['Goat Sports...', 'The Sports S...', 'Providence Turf'];

  @override
  void initState() {
    super.initState();
    // Initialize the PageController
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    // Dispose the PageController to free up resources
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String turfId) {
    setState(() {
      if (_favoriteTurfIds.contains(turfId)) {
        _favoriteTurfIds.remove(turfId);
      } else {
        _favoriteTurfIds.add(turfId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<TurfItem> favoriteCards =
        _allTurfs.where((turf) => _favoriteTurfIds.contains(turf.id)).toList();

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Appbg1.mainGradient,
        ),
        child: Column(
          children: [
            // --- HEADER SECTION ---
            SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          'Cricket',
                          style: GoogleFonts.poppins(
                            color: accentColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Scorer',
                            style: GoogleFonts.poppins(
                              color: accentColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(Icons.headset_mic_outlined, color: Color(0xFF140088)),
                                    const SizedBox(width: 10),
                                    const Text('Support'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'For any queries or support, please contact us:',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.email, size: 20, color: Color(0xFF140088)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SelectableText(
                                            'antony.cyril@aerobiosys.com',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.business, size: 20, color: Color(0xFF140088)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Aerobiosys Innovation Pvt.Ltd',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Close', style: GoogleFonts.poppins()),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.headset_mic_outlined,
                            color: Colors.white,
                            size: 25.0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 25.0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- SEARCH BAR (same style as Home Page) ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF545454),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    hintText: "Search...",
                    hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // --- DIVIDER 1 ---
            Center(
              child: SizedBox(
                width: 360.0,
                child: Container(
                  height: 1.0,
                  color: dividerColor,
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // --- YOUR FAVORITES LABEL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 116.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: favouritesContainerColor,
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Your Favourites',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // --- FAVORITES LIST ---
            SizedBox(
              height: favoriteCards.isEmpty ? 0 : 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: favoriteCards.length,
                itemBuilder: (context, index) {
                  final item = favoriteCards[index];
                  return Padding(
                    padding: index < favoriteCards.length - 1
                        ? const EdgeInsets.only(right: 16.0)
                        : EdgeInsets.zero,
                    child: FavouriteCard(
                      imagePath: item.imagePath,
                      title: item.title,
                      subtitle: item.subtitle,
                      turfItem: item,
                      onToggleFavorite: () => _toggleFavorite(item.id),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 2.0),

            // --- DIVIDER 2 ---
            Center(
              child: SizedBox(
                width: 360.0,
                child: Container(
                  height: 1.0,
                  color: dividerColor,
                ),
              ),
            ),

            // --- GRID VIEW (All turfs) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _allTurfs.length,
                  itemBuilder: (context, index) {
                    final item = _allTurfs[index];
                    final bool isFavorite = _favoriteTurfIds.contains(item.id);
                    return TurfCard(
                      imagePath: item.imagePath,
                      title: item.title,
                      subtitle: item.subtitle,
                      rating: item.rating,
                      isFavorite: isFavorite,
                      turfItem: item,
                      onToggleFavorite: () => _toggleFavorite(item.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TurfDetailsScreen ---
class TurfDetailsScreen extends StatefulWidget {
  final TurfItem turf;

  const TurfDetailsScreen({super.key, required this.turf});

  @override
  State<TurfDetailsScreen> createState() => _TurfDetailsScreenState();
}

class _TurfDetailsScreenState extends State<TurfDetailsScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;

  final List<String> timeSlots = [
    '06:00 AM - 07:00 AM',
    '07:00 AM - 08:00 AM',
    '08:00 AM - 09:00 AM',
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '01:00 PM - 02:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM',
    '06:00 PM - 07:00 PM',
    '07:00 PM - 08:00 PM',
    '08:00 PM - 09:00 PM',
  ];

  // Sample booked slots (you can make this dynamic later)
  final List<String> bookedSlots = [
    '09:00 AM - 10:00 AM',
    '02:00 PM - 03:00 PM',
    '06:00 PM - 07:00 PM',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset time slot when date changes
      });
    }
  }

  void _bookSlot() {
    if (selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          'Confirm Booking',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Book ${widget.turf.title} on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $selectedTimeSlot?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking confirmed for $selectedTimeSlot'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: Appbg1.mainGradient,
        ),
        child: Column(
          children: [
            // Header with image
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Image.asset(
                    widget.turf.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Details Section
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.turf.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  widget.turf.rating,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'About',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.turf.description,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Location Details
                      Text(
                        'Location',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.turf.address,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.turf.phone,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Date Selection
                      Text(
                        'Select Date',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(Icons.calendar_today, color: Colors.white),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time Slots
                      Text(
                        'Available Time Slots',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: timeSlots.map((slot) {
                          final isBooked = bookedSlots.contains(slot);
                          final isSelected = selectedTimeSlot == slot;
                          return InkWell(
                            onTap: isBooked
                                ? null
                                : () {
                                    setState(() {
                                      selectedTimeSlot = slot;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.red.withOpacity(0.3)
                                    : isSelected
                                        ? Colors.green
                                        : const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isBooked
                                      ? Colors.red
                                      : isSelected
                                          ? Colors.green
                                          : Colors.white24,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.poppins(
                                  color: isBooked
                                      ? Colors.white38
                                      : Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: _bookSlot,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Book Now',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- FavouriteCard ---
class FavouriteCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final double cardWidth;
  final double cardHeight;
  final double imageHeight;
  final VoidCallback? onToggleFavorite;
  final TurfItem turfItem;

  const FavouriteCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.cardWidth = 150,
    this.cardHeight = 180,
    this.imageHeight = 110,
    this.onToggleFavorite,
    required this.turfItem,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TurfDetailsScreen(turf: turfItem),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.red, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TurfCard ---
class TurfCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String rating;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final TurfItem turfItem;

  const TurfCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.isFavorite,
    this.onToggleFavorite,
    required this.turfItem,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TurfDetailsScreen(turf: turfItem),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 85,
              child: Stack(
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0 ? Colors.white : Colors.white54,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            rating,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.white, size: 10),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}