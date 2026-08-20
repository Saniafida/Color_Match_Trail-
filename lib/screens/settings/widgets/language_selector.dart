import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
// Removed app_colors.dart
import 'language_selection_dialog.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // We expect to be wrapped in a listener/builder if the UI needs to react 
    // to changes immediately. The root ListenableBuilder in main.dart handles the app-wide rebuild.
    final locManager = ServiceLocator.instance.localizationManager;
    final isSystem = ServiceLocator.instance.settingsManager.state.language == 'system';
    final displayText = isSystem 
        ? 'System (${locManager.currentLocale.nativeName})'
        : locManager.currentLocale.nativeName;

    return ListTile(
      leading: const Icon(Icons.language, color: Colors.cyanAccent),
      title: Text(
        locManager.translate('settings.language'),
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const LanguageSelectionDialog(),
        );
      },
    );
  }
}
