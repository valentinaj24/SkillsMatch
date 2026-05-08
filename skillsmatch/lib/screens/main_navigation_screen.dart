import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'my_profile_screen.dart';
import 'users_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    ProfileScreen(),
    MyProfileScreen(),
    UsersListScreen(),
  ];

  final List<NavigationItem> items = [
    NavigationItem(icon: Icons.edit_note_rounded, label: 'Uredi'),
    NavigationItem(icon: Icons.person_rounded, label: 'Profil'),
    NavigationItem(icon: Icons.groups_rounded, label: 'Skupnost'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey(selectedIndex),
          child: screens[selectedIndex],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Container(
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff004d40),
                  Color(0xff009688),
                  Color(0xff26a69a),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 18 : 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 350),
                          tween: Tween(begin: 1, end: isSelected ? 1.18 : 1),
                          builder: (context, value, child) {
                            return Transform.scale(scale: value, child: child);
                          },
                          child: Icon(item.icon, color: Colors.white, size: 27),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: isSelected
                              ? Row(
                                  children: [
                                    const SizedBox(width: 9),
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({required this.icon, required this.label});
}
