import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_gathering/models/user_profile.dart';
import 'package:the_gathering/providers/auth_provider.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/interests_service.dart';
import 'package:the_gathering/services/profiles_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// My Profile screen + edit flow (PR2).
/// Web-safe avatar preview (no dart:io).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isEditing = false;

  final _nameController = TextEditingController(text: 'Member');
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _wardController = TextEditingController();
  final _stakeController = TextEditingController();

  String? _ageRange;
  List<String> _selectedInterests = [];
  String? _avatarUrl;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile(
      id: SupabaseService.currentUser?.id ?? '',
      displayName: 'Member',
      interests: [],
      isVerifiedMember: false,
      createdAt: DateTime.now(),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _stakeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final loaded = await ProfilesService.fetchCurrentProfile();
      if (loaded != null) {
        setState(() {
          _profile = loaded;
          _nameController.text = _profile.displayName;
          _selectedInterests = List.from(_profile.interests);
          _cityController.text = _profile.city ?? '';
          _wardController.text = _profile.ward ?? '';
          _stakeController.text = _profile.stake ?? '';
          _avatarUrl = _profile.avatarUrl;
          if (_avatarUrl != null && _avatarUrl!.startsWith('local://')) {
            _avatarUrl = null;
          }
          _ageRange = _profile.ageRange;
          _bioController.text = _profile.bio ?? '';
        });
        ref.read(currentProfileProvider.notifier).refresh();
      }
    } catch (_) {
      // keep defaults
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    final user = SupabaseService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to upload a profile picture.')),
        );
      }
      return;
    }

    final bytes = await image.readAsBytes();
    setState(() {
      _pickedImage = image;
      _pickedImageBytes = bytes;
    });

    setState(() => _isLoading = true);
    try {
      final url = await ProfilesService.uploadAvatar(image, user.id);
      setState(() {
        _avatarUrl = url;
        _pickedImage = null;
        _pickedImageBytes = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar uploaded!')),
        );
      }
    } catch (e) {
      // Keep local preview; profile can still be saved without remote avatar in beta.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo preview saved locally, but upload failed. '
              'Run supabase/beta_setup.sql (avatars bucket). Error: $e',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will return to the sign-in screen. '
          'Use this before a friend creates their own account on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/auth');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? finalAvatarUrl =
          (_avatarUrl != null && !_avatarUrl!.startsWith('local://'))
              ? _avatarUrl
              : _profile.avatarUrl;

      if (_pickedImage != null &&
          (finalAvatarUrl == null || finalAvatarUrl.startsWith('local://'))) {
        try {
          final userId = SupabaseService.currentUser!.id;
          final url = await ProfilesService.uploadAvatar(_pickedImage!, userId);
          finalAvatarUrl = url;
          _avatarUrl = url;
          _pickedImage = null;
          _pickedImageBytes = null;
        } catch (_) {
          // Allow save without photo for beta when storage is not set up.
        }
      }

      final updatedProfile = UserProfile(
        id: _profile.id,
        displayName: _nameController.text.trim(),
        ageRange: _ageRange,
        bio: _bioController.text.trim(),
        interests: _selectedInterests,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        ward: _wardController.text.trim().isEmpty
            ? null
            : _wardController.text.trim(),
        stake: _stakeController.text.trim().isEmpty
            ? null
            : _stakeController.text.trim(),
        isVerifiedMember: _profile.isVerifiedMember,
        avatarUrl: finalAvatarUrl,
        createdAt: _profile.createdAt,
      );

      final saved = await ProfilesService.saveProfile(updatedProfile);

      setState(() {
        _profile = saved;
        _isEditing = false;
        _pickedImage = null;
        _pickedImageBytes = null;
      });

      await ref.read(currentProfileProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalAvatarUrl == null
                  ? 'Profile saved. (Add a photo when the avatars bucket is ready.)'
                  : 'Profile saved!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? get _avatarProvider {
    if (_pickedImageBytes != null) {
      return MemoryImage(_pickedImageBytes!);
    }
    if (_avatarUrl != null && !_avatarUrl!.startsWith('local://')) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Reports inbox',
            onPressed: () => context.push('/reports'),
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit profile',
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _isLoading ? null : _signOut,
          ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_isEditing) ...[
                    Material(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signed in as ${SupabaseService.currentUser?.email ?? _profile.displayName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Friends must create their own account. '
                              'Tap Sign out (top right) or the button below before they use this browser.',
                              style: TextStyle(fontSize: 13, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Near top so it is not buried under interests.
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.flag,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text(
                          'Reports inbox',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Review community reports (beta moderation)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/reports'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _avatarProvider,
                          child: _avatarProvider == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FloatingActionButton.small(
                              onPressed: _isLoading ? null : _pickAvatar,
                              child: const Icon(Icons.camera_alt),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    Center(
                      child: Text(
                        'Photo optional for beta — recommended for trust.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _ageRange,
                    decoration: const InputDecoration(labelText: 'Age range'),
                    items: const [
                      DropdownMenuItem(value: '18-25', child: Text('18–25')),
                      DropdownMenuItem(value: '26-35', child: Text('26–35')),
                      DropdownMenuItem(value: '36-45', child: Text('36–45')),
                      DropdownMenuItem(value: '46-55', child: Text('46–55')),
                      DropdownMenuItem(value: '56+', child: Text('56+')),
                    ],
                    onChanged: _isEditing
                        ? (v) => setState(() => _ageRange = v)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bioController,
                    enabled: _isEditing,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Short bio',
                      hintText: 'What kinds of gatherings do you enjoy?',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cityController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'City (coarse location)',
                      helperText: 'We only store city — not your precise home address.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _wardController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Ward (optional, private)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _stakeController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Stake (optional, private)',
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Interests (4 areas)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...InterestsService.grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: entry.value.map((interest) {
                            final selected = _selectedInterests.contains(interest);
                            return FilterChip(
                              label: Text(interest),
                              selected: selected,
                              onSelected: _isEditing
                                  ? (v) {
                                      setState(() {
                                        if (v) {
                                          _selectedInterests.add(interest);
                                        } else {
                                          _selectedInterests.remove(interest);
                                        }
                                      });
                                    }
                                  : null,
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),
                  if (_isEditing)
                    FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save profile'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: const Text('Edit profile'),
                    ),

                  const SizedBox(height: 16),
                  Text(
                    'Verification: ${_profile.isVerifiedMember ? 'Verified member' : 'Pending review'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'After sign out, Create Account works for the next person on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
