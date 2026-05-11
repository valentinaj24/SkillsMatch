import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'my_profile_screen.dart';
import 'users_list_screen.dart';

const _kPrimary = Color(0xFF4F46E5);

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int selectedIndex = 0;

  late final List<Widget> screens;
  late final List<AnimationController> _tapCtrls;
  late final List<Animation<double>> _tapScales;

  final List<_NavItem> items = const [
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    _NavItem(icon: Icons.groups_rounded, label: 'Skupnost'),
  ];

  @override
  void initState() {
    super.initState();

    screens = [
      MyProfileScreen(
        onNavigateToSkupnost: () {
          setState(() {
            selectedIndex = 1;
          });
        },
      ),
      const UsersListScreen(),
    ];

    _tapCtrls = List.generate(
      items.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 130),
      ),
    );

    _tapScales = _tapCtrls
        .map(
          (controller) => Tween<double>(begin: 1.0, end: 0.92).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _tapCtrls) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact();

    _tapCtrls[index].forward().then((_) {
      if (mounted) {
        _tapCtrls[index].reverse();
      }
    });

    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0FF),
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF3730A3),
                  Color(0xFF4F46E5),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(index),
                    child: ScaleTransition(
                      scale: _tapScales[index],
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.17)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          border: selected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.24),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.50),
                              size: selected ? 25 : 23,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.55),
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
