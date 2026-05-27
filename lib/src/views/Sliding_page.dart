import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';
import 'package:TURF_TOWN_/src/Services/auth_service.dart'; // ← AuthService
import 'package:TURF_TOWN_/src/Screens/Phone_no.dart';
import 'package:TURF_TOWN_/src/views/Home.dart';

class SlidingPage extends StatefulWidget {
  @override
  _SlidingPageState createState() => _SlidingPageState();
}

class _SlidingPageState extends State<SlidingPage> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final _authService = AuthService(); // ← instance

  final List<Map<String, String>> pages = [
    {'image': 'assets/images/page1.png', 'text': 'Sport Trax.'},
    {'image': 'assets/images/page2.png', 'text': 'Your New Favourite Place.'},
    {'image': 'assets/images/page3.png', 'text': 'Meet new friends on court.'},
  ];

  // Called when Start is pressed — checks auth state then routes
  void _onStartPressed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StreamBuilder(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0094FF)),
                ),
              );
            }
            // Logged in → Home
            if (snapshot.hasData && snapshot.data != null) {
              return const Home();
            }
            // Not logged in → Phone
            return const PhoneNumberPage();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: Appbg1.mainGradient),
          ),
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: pages.length,
            itemBuilder: (context, index, realIdx) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  Text(
                    pages[index]['text']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Image.asset(
                    pages[index]['image']!,
                    height: 476,
                    width: 284,
                    fit: BoxFit.contain,
                  ),
                ],
              );
            },
            options: CarouselOptions(
              height: double.infinity,
              autoPlay: false,
              enlargeCenterPage: true,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),

          // Dot indicators
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: pages.asMap().entries.map((entry) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),

          // Skip button
          if (_currentIndex < pages.length - 1)
            Positioned(
              bottom: 30,
              left: 30,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C4FF).withOpacity(0.3),
                      const Color(0xFF0094FF).withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C4FF).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _carouselController.animateToPage(
                      pages.length - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.skip_next,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),

          // Next arrow button
          if (_currentIndex < pages.length - 1)
            Positioned(
              bottom: 30,
              right: 30,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C4FF).withOpacity(0.3),
                      const Color(0xFF0094FF).withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C4FF).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _carouselController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.arrow_forward,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),

          // Start button on last slide
          if (_currentIndex == pages.length - 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00C4FF).withOpacity(0.3),
                        const Color(0xFF0094FF).withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C4FF).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onStartPressed, // ← uses AuthService stream
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        child: const Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}