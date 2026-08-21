import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../game/settings/vibration_strength.dart';
import 'widgets/settings_header.dart';
import 'widgets/settings_switch_row.dart';
import 'widgets/settings_selection_row.dart';
import 'widgets/reset_settings_dialog.dart';
import 'widgets/language_selector.dart';
import '../tutorial/tutorial_replay_screen.dart';

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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Future<void> _handleReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const ResetSettingsDialog(),
    );
    if (confirm == true) {
      await _manager.resetToDefaults();
      if (mounted) {
        final loc = ServiceLocator.instance.localizationManager;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('settings.reset')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReplayTutorial() async {
    // Navigate to the new tutorial replay screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorialReplayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _manager.state;
    final loc = ServiceLocator.instance.localizationManager;

    return Scaffold(
      backgroundColor: const Color(0xFF141E2A),
      appBar: const SettingsHeader(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _buildSectionHeader('AUDIO'),
          SettingsSwitchRow(
            title: loc.translate('settings.sound'),
            description: 'Gameplay sounds and interface clicks',
            value: state.soundEnabled,
            onChanged: (v) => _manager.toggleSound(),
          ),
          SettingsSwitchRow(
            title: loc.translate('settings.music'),
            description: 'Background music',
            value: state.musicEnabled,
            onChanged: (v) => _manager.toggleMusic(),
          ),

          _buildSectionHeader('FEEDBACK'),
          SettingsSwitchRow(
            title: loc.translate('settings.haptics'),
            description: 'Vibration feedback during gameplay',
            value: state.hapticsEnabled,
            onChanged: (v) => _manager.toggleHaptics(),
          ),
          if (state.hapticsEnabled)
            SettingsSelectionRow<VibrationStrength>(
              title: 'Vibration Strength',
              description: 'Intensity of haptic feedback',
              value: state.vibrationStrength,
              items: VibrationStrength.values,
              itemLabel: (v) => v.displayName,
              onChanged: (v) {
                if (v != null) _manager.setVibrationStrength(v);
              },
            ),
          SettingsSwitchRow(
            title: loc.translate('settings.effects'),
            description: 'Disable large animations for better performance',
            value: state.reducedEffects,
            onChanged: (v) => _manager.toggleReducedEffects(),
          ),

          _buildSectionHeader('NOTIFICATIONS'),
          SettingsSwitchRow(
            title: loc.translate('settings.notifications'),
            description: 'Get alerted about daily challenges and events',
            value: state.notificationsEnabled,
            onChanged: (v) => _manager.toggleNotifications(),
          ),

          _buildSectionHeader('LANGUAGE'),
          const LanguageSelector(),

          _buildSectionHeader('OTHER'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleReplayTutorial,
                icon: const Icon(Icons.school_outlined, size: 18),
                label: const Text('REPLAY TUTORIAL', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.translate('settings.reset'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
