// main.dart

import 'package:flutter/material.dart';
import 'screens/roster_input_screen.dart';

void main() {
  runApp(WorkRosterApp());
}

class WorkRosterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Austrian Airlines Roster',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: Color(0xFFE30613), // Austrian Airlines Red
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Helvetica Neue',
      ),
      home: RosterInputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
