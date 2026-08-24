import 'package:flutter/material.dart';
import '../../widgets/common/wood_sign_header.dart';
import '../../widgets/buttons/glossy_button.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  int _selectedTheme = 0;

  final List<Map<String, dynamic>> _themes = [
    {
      'title': 'Default',
      'isDefault': true,
      'gradient': [Color(0xFF81C784), Color(0xFF388E3C)],
      'icon': Icons.park_rounded,
      'imagePath': 'assets/images/backgrounds/bg_garden.jpg',
    },
    {
      'title': 'Forest',
      'isDefault': false,
      'gradient': [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      'icon': Icons.forest_rounded,
      'imagePath': 'assets/images/backgrounds/bg_world_map.jpg',
    },
    {
      'title': 'Beach',
      'isDefault': false,
      'gradient': [Color(0xFF4FC3F7), Color(0xFF0288D1)],
      'icon': Icons.beach_access_rounded,
      'imagePath': 'assets/images/backgrounds/bg_garden.jpg',
    },
    {
      'title': 'Winter',
      'isDefault': false,
      'gradient': [Color(0xFF90CAF9), Color(0xFF5C6BC0)],
      'icon': Icons.ac_unit_rounded,
      'imagePath': 'assets/images/backgrounds/bg_world_map.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                  title: 'Themes',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),

                // 2x2 Grid of Theme Preview Cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      itemCount: _themes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final isSelected = _selectedTheme == index;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedTheme = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6D4222),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF76FF03) : const Color(0xFFFFD54F),
                                width: isSelected ? 3.5 : 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected ? const Color(0xFF76FF03).withAlpha(140) : Colors.black38,
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Preview Image Container
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            theme['imagePath'] as String,
                                            fit: BoxFit.cover,
                                          ),
                                          if (theme['isDefault'] as bool)
                                            Positioned(
                                              bottom: 6,
                                              left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4CAF50),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.white, width: 1),
                                                ),
                                                child: const Text(
                                                  'Default',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Theme Name
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                                  child: Text(
                                    theme['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Big Glossy Green Apply Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
                  child: GlossyButton(
                    text: 'Apply',
                    color: GlossyButtonColor.green,
                    height: 54,
                    fontSize: 20,
                    width: double.infinity,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Theme applied successfully!'),
                          backgroundColor: Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
