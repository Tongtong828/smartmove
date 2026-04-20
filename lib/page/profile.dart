import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/tag.dart';
import '../store/store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _nameKey = 'profile_name';
  static const String _bioKey = 'profile_bio';
  static const String _avatarPathKey = 'profile_avatar_path';

  final ImagePicker _picker = ImagePicker();

  String _name = 'City Explorer';
  String _bio = 'Collect places, moments and memories.';
  String? _avatarPath;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _name = prefs.getString(_nameKey) ?? 'City Explorer';
      _bio = prefs.getString(_bioKey) ?? 'Collect places, moments and memories.';
      _avatarPath = prefs.getString(_avatarPathKey);
      _isLoadingProfile = false;
    });
  }

  Future<void> _saveProfile({
    required String name,
    required String bio,
    String? avatarPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_bioKey, bio);

    if (avatarPath != null && avatarPath.isNotEmpty) {
      await prefs.setString(_avatarPathKey, avatarPath);
    } else {
      await prefs.remove(_avatarPathKey);
    }

    if (!mounted) return;

    setState(() {
      _name = name;
      _bio = bio;
      _avatarPath = (avatarPath == null || avatarPath.isEmpty)
          ? null
          : avatarPath;
    });
  }

  Future<String> _persistImage(XFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folder = Directory('${appDir.path}/profile_images');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final ext = file.path.contains('.')
        ? file.path.split('.').last
        : 'jpg';

    final target = File(
      '${folder.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );

    final copied = await File(file.path).copy(target.path);
    return copied.path;
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1200,
    );

    if (file == null) return;

    final savedPath = await _persistImage(file);
    await _saveProfile(
      name: _name,
      bio: _bio,
      avatarPath: savedPath,
    );
  }

  Future<void> _showAvatarOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Edit Avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _sheetActionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAvatar(ImageSource.gallery);
                  },
                ),
                _sheetActionTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Take a Photo',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAvatar(ImageSource.camera);
                  },
                ),
                _sheetActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Avatar',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    await _saveProfile(
                      name: _name,
                      bio: _bio,
                      avatarPath: '',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _name);
    final bioController = TextEditingController(text: _bio);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Signature',
                        hintText: 'Write a short signature',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final nextName = nameController.text.trim().isEmpty
                              ? 'City Explorer'
                              : nameController.text.trim();

                          final nextBio = bioController.text.trim().isEmpty
                              ? 'Collect places, moments and memories.'
                              : bioController.text.trim();

                          Navigator.pop(context);
                          await _saveProfile(
                            name: nextName,
                            bio: nextBio,
                            avatarPath: _avatarPath ?? '',
                          );
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save Changes'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
    bioController.dispose();
  }

  Widget _sheetActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? Colors.black87;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onTap: onTap,
    );
  }

  Color _colorForTagKey(String key) {
    for (final tag in availableTags) {
      if (tag.key == key) return tag.color;
    }
    return const Color(0xFF78909C);
  }

  IconData _iconForTagKey(String key) {
    for (final tag in availableTags) {
      if (tag.key == key) return tag.icon;
    }
    return Icons.sell_rounded;
  }

  String _labelForTagKey(String key) {
    for (final tag in availableTags) {
      if (tag.key == key) return tag.label;
    }

    if (key.startsWith('custom:')) {
      return key.substring('custom:'.length).trim();
    }

    return key;
  }

  Widget _buildAvatar(BuildContext context) {
    final hasAvatar =
        _avatarPath != null &&
        _avatarPath!.trim().isNotEmpty &&
        File(_avatarPath!).existsSync();

    return Stack(
      children: [
        GestureDetector(
          onTap: _showAvatarOptions,
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            backgroundImage: hasAvatar ? FileImage(File(_avatarPath!)) : null,
            child: hasAvatar
                ? null
                : const Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showAvatarOptions,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CheckInStore.instance,
      builder: (context, _) {
        final records = CheckInStore.instance.records;
        final latest = records.isEmpty ? null : records.first;

        final usedTags = <String>{};
        for (final record in records) {
          usedTags.addAll(record.tags);
        }

        final tagCounts = <String, int>{};
        for (final record in records) {
          for (final key in record.tags) {
            tagCounts[key] = (tagCounts[key] ?? 0) + 1;
          }
        }

        final sortedTagKeys = tagCounts.keys.toList()
          ..sort((a, b) => (tagCounts[b] ?? 0).compareTo(tagCounts[a] ?? 0));

        if (_isLoadingProfile) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6C7CFF),
                      Color(0xFF8E7CFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C7CFF).withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(context),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _bio,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      height: 1.45,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Edit Profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showAvatarOptions,
                              icon: const Icon(Icons.photo_camera_rounded),
                              label: const Text('Edit Avatar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.bookmark_added_rounded,
                    title: 'Check-ins',
                    value: records.length.toString(),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.sell_rounded,
                    title: 'Used Tags',
                    value: usedTags.length.toString(),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.history_rounded,
                    title: 'Latest',
                    value: latest == null ? '--' : '1',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Memory Summary',
                subtitle: 'A quick view of your recent place collection.',
                child: Column(
                  children: [
                    _summaryRow(
                      'Latest check-in',
                      latest == null ? '--' : latest.title,
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Saved address',
                      latest == null
                          ? '--'
                          : (latest.address.isEmpty ? 'No address' : latest.address),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Latest note',
                      latest == null
                          ? '--'
                          : (latest.note.isEmpty ? 'No notes' : latest.note),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Top Tags',
                subtitle: 'Most frequently used place tags.',
                child: sortedTagKeys.isEmpty
                    ? Text(
                        'No tags used yet.',
                        style: TextStyle(color: Colors.grey.shade700),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: sortedTagKeys.map((key) {
                          final color = _colorForTagKey(key);
                          final icon = _iconForTagKey(key);
                          final label = _labelForTagKey(key);
                          final count = tagCounts[key] ?? 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 16, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  '$label · $count',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Your Space',
                subtitle: 'Make this app feel more personal.',
                child: Row(
                  children: [
                    Expanded(
                      child: _miniActionCard(
                        icon: Icons.badge_rounded,
                        title: 'Edit Name',
                        onTap: _showEditProfileDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniActionCard(
                        icon: Icons.short_text_rounded,
                        title: 'Edit Signature',
                        onTap: _showEditProfileDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniActionCard(
                        icon: Icons.face_rounded,
                        title: 'Edit Avatar',
                        onTap: _showAvatarOptions,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}