import 'package:flutter/material.dart';
import 'settings_row.dart';

class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      title: title,
      description: description,
      control: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.amber,
        activeTrackColor: Colors.amber.withAlpha(128),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withAlpha(128),
      ),
    );
  }
}
