import 'package:flutter/material.dart';
import '../../game/profile/player_profile_manager.dart';
import 'widgets/avatar_selector.dart';

class EditProfileScreen extends StatefulWidget {
  final PlayerProfileManager manager;

  const EditProfileScreen({Key? key, required this.manager}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedAvatarId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.manager.profile.displayName);
    _selectedAvatarId = widget.manager.profile.avatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    
    await widget.manager.updateIdentity(
      newName: _nameController.text,
      newAvatarId: _selectedAvatarId,
    );
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator(color: Colors.amber)))
          else
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Display Name',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              maxLength: 16,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter your display name',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Choose Avatar',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AvatarSelector(
              availableAvatars: widget.manager.availableAvatars,
              currentAvatarId: _selectedAvatarId,
              onAvatarSelected: (id) {
                setState(() {
                  _selectedAvatarId = id;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
