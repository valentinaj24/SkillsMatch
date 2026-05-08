import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'my_profile_screen.dart';
import 'users_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    ProfileScreen(),
    MyProfileScreen(),
    UsersListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: Colors.teal.shade100,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Uredi'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Moj profil'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Skupnost'),
        ],
      ),
    );
  }
}
