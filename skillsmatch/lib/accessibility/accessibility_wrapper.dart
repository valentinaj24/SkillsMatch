import 'package:flutter/material.dart';
import 'app_accessibility.dart';

const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryDark = Color(0xFF312E81);
const _kViolet = Color(0xFF7C3AED);
const _kLightPurple = Color(0xFFA78BFA);

const _kText = Color(0xFF111827);
const _kSub = Color(0xFF4B5563);

const _kBg = Color(0xFFF5F3FF);
const _kBorder = Color(0xFFE5E7EB);

class AccessibilityWrapper extends StatelessWidget {
  final Widget child;

  const AccessibilityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppAccessibility.instance,
      builder: (context, _) {
        final senior = AppAccessibility.instance.seniorMode;
        final showButton = AppAccessibility.instance.showFloatingButton;

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(senior ? 1.25 : 1.0)),
   
            child: child,
                    
        );
      },
    );
  }
}

class _SeniorFloatingButton extends StatelessWidget {
  const _SeniorFloatingButton();

  @override
  Widget build(BuildContext context) {
    final senior = AppAccessibility.instance.seniorMode;

    return Positioned(
      right: 18,
      bottom: MediaQuery.of(context).padding.bottom + 140,
      child: GestureDetector(
        onTap: _showSeniorModeSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: senior
                  ? const [_kLightPurple, _kViolet]
                  : const [_kPrimary, _kPrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: (senior ? _kViolet : _kPrimaryDark).withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            senior ? Icons.text_increase_rounded : Icons.text_fields_rounded,
            color: Colors.white,
            size: senior ? 29 : 27,
          ),
        ),
      ),
    );
  }

  void _showSeniorModeSheet() async {
    final navContext = AppAccessibility.instance.navigatorKey.currentContext;

    if (navContext == null) return;

    AppAccessibility.instance.setFloatingVisible(false);

    await showModalBottomSheet(
      context: navContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return AnimatedBuilder(
          animation: AppAccessibility.instance,
          builder: (context, _) {
            final senior = AppAccessibility.instance.seniorMode;

            return Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: const Color(0xFFE9D5FF), width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: senior
                              ? const [_kLightPurple, _kViolet]
                              : const [_kPrimary, _kPrimaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (senior ? _kViolet : _kPrimary).withOpacity(
                              0.30,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        senior
                            ? Icons.text_increase_rounded
                            : Icons.text_fields_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      senior ? 'Senior način je vključen' : 'Dostopni način',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Poveča velikost besedila in izboljša vidljivost aplikacije.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kSub,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD8B4FE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: senior
                                    ? const [_kLightPurple, _kViolet]
                                    : const [_kPrimary, _kPrimaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimary.withOpacity(0.22),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              senior
                                  ? Icons.zoom_in_rounded
                                  : Icons.text_fields_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 16),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Večji prikaz',
                                  style: TextStyle(
                                    color: _kText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Boljša berljivost in večji elementi aplikacije',
                                  style: TextStyle(
                                    color: _kSub,
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Switch(
                            value: senior,
                            activeColor: Colors.white,
                            activeTrackColor: _kViolet,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            onChanged: (value) {
                              AppAccessibility.instance.setSeniorMode(value);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Shrani nastavitev'),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    AppAccessibility.instance.setFloatingVisible(true);
  }
}
