import 'package:flutter/material.dart';
import '../../app/routes/routes.dart';
import '../../core/services/service_locator.dart';
import '../../widgets/common/wood_sign_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _manager = ServiceLocator.instance.settingsManager;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _manager.state;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Garden Background
          Image.asset(
            'assets/images/backgrounds/bg_garden.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Overlay
          Container(
            color: Colors.black.withAlpha(50),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                WoodSignHeader(
                  title: 'Settings',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EC), // Cream board
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 6),
                      ],
                    ),
                    child: ListView(
                      children: [
                        _buildSwitchRow(
                          icon: Icons.music_note_rounded,
                          title: 'Music',
                          value: state.musicEnabled,
                          onChanged: (_) => _manager.toggleMusic(),
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1),
                        _buildSwitchRow(
                          icon: Icons.volume_up_rounded,
                          title: 'Sound Effects',
                          value: state.soundEnabled,
                          onChanged: (_) => _manager.toggleSound(),
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1),
                        _buildSwitchRow(
                          icon: Icons.vibration_rounded,
                          title: 'Vibration',
                          value: state.hapticsEnabled,
                          onChanged: (_) => _manager.toggleHaptics(),
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1),
                        _buildNavRow(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          valueText: 'English',
                          onTap: () {},
                        ),
                        const Divider(color: Color(0xFFE2CCAE), thickness: 1),
                        _buildNavRow(
                          icon: Icons.palette_rounded,
                          title: 'Theme',
                          valueText: 'Garden',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.themes),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Support & Privacy Policy Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSecondaryButton(
                                icon: Icons.headset_mic_rounded,
                                label: 'Support',
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSecondaryButton(
                                icon: Icons.verified_user_rounded,
                                label: 'Privacy Policy',
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5D3A1A), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3E200C),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          // Glossy Green Switch
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFF8CE03E),
            inactiveThumbColor: const Color(0xFF8D6E63),
            inactiveTrackColor: const Color(0xFFD7CCC8),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required String valueText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5D3A1A), size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF3E200C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              valueText,
              style: const TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8D6E63), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0D4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF5D3A1A), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3E200C),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
