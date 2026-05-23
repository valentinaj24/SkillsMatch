import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: () => themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252438) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 18,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
            ),
          ),
        );
      },
    );
  }
}