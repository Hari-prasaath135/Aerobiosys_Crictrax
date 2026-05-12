import 'package:flutter/material.dart';

import 'package:TURF_TOWN_/src/CommonParameters/AppBackGround1/Appbg1.dart';


class Appbg2 extends StatefulWidget {
  const Appbg2({super.key});

  @override
  State<Appbg2> createState() => _Appbg2State();
}

class _Appbg2State extends State<Appbg2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(gradient: Appbg1.mainGradient),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 35),
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 3.0),
                      child: IconButton(
                        icon: Icon(Icons.menu),
                        color: Colors.white,
                        iconSize: 30.0,
                        tooltip: 'Menu',
                        onPressed: () {
                          // Remove the navigation to Board since it doesn't exist
                          // Add your menu functionality here
                          print('Menu pressed');
                        },
                      ),
                    ),
                    Text(
                      'Cricket',
                      style: TextStyle(fontSize: 35, color: Colors.white),
                    ),
                    SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        'Scorer',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}