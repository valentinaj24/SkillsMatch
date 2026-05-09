import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_screen.dart';
import 'my_profile_screen.dart';
import 'users_list_screen.dart';

// ─── Color System (isti kot ostale zaslone) ───────────────────────────────────
const _kPrimary  = Color(0xFF4F46E5);
const _kViolet   = Color(0xFF7C3AED);
const _kNavBg    = Color(0xFF1E1B4B); // temno indigo za navbar

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int selectedIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      const ProfileScreen(),
      MyProfileScreen(onNavigateToSkupnost: () =>
          setState(() => selectedIndex = 2)),
      const UsersListScreen(),
    ];
    _tapCtrls = List.generate(items.length, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130)));
    _tapScales = _tapCtrls.map((c) =>
        Tween<double>(begin: 1.0, end: 0.88).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
  }

  final List<_NavItem> items = const [
    _NavItem(icon: Icons.edit_note_rounded,  label: 'Uredi'),
    _NavItem(icon: Icons.person_rounded,     label: 'Profil'),
    _NavItem(icon: Icons.groups_rounded,     label: 'Skupnost'),
  ];

  late List<AnimationController> _tapCtrls;
  late List<Animation<double>>   _tapScales;

  @override
  void dispose() {
    for (final c in _tapCtrls) { c.dispose(); }
    super.dispose();
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    _tapCtrls[index].forward().then((_) => _tapCtrls[index].reverse());
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      backgroundColor: const Color(0xFFF0F0FF),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0.04, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(selectedIndex),
          child: screens[selectedIndex],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
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
                    color: _kPrimary.withOpacity(0.38),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item     = items[i];
                  final selected = selectedIndex == i;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(i),
                    child: ScaleTransition(
                      scale: _tapScales[i],
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: selected ? 16 : 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: selected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.20),
                                  width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0,
                                  end: selected ? 1.12 : 1.0),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              builder: (_, v, child) =>
                                  Transform.scale(scale: v, child: child),
                              child: Icon(item.icon,
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.40),
                                  size: 25),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              Text(item.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.1,
                                )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}