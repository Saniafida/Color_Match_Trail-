import 'package:flutter/material.dart';
import '../../../core/localization/localization_config.dart';
import '../../../core/services/service_locator.dart';
// Removed app_colors.dart

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationManager = ServiceLocator.instance.localizationManager;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E2D3D), // matching settings dialogs
      title: Text(
        localizationManager.translate('settings.language'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: LocalizationConfig.supportedLocales.length + 1, // +1 for system
          separatorBuilder: (context, index) => const Divider(color: Colors.grey),
          itemBuilder: (context, index) {
            if (index == 0) {
              // System default option
              final isSelected = ServiceLocator.instance.settingsManager.state.language == 'system';
              return ListTile(
                title: const Text('System Default', style: TextStyle(color: Colors.white)),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
                onTap: () {
                  localizationManager.setLanguage('system');
                  Navigator.of(context).pop();
                },
              );
            }

            final locale = LocalizationConfig.supportedLocales[index - 1];
            final isSelected = ServiceLocator.instance.settingsManager.state.language == locale.languageCode;

            return ListTile(
              title: Text(
                locale.nativeName,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                locale.displayName,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.cyanAccent) : null,
              onTap: () {
                localizationManager.setLanguage(locale.languageCode);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
