import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_gathering/models/user_profile.dart';
import 'package:the_gathering/providers/current_profile_provider.dart';
import 'package:the_gathering/services/interests_service.dart';
import 'package:the_gathering/services/profiles_service.dart';
import 'package:the_gathering/services/supabase_service.dart';

/// My Profile screen + edit flow (PR2).
/// - Collects full profile fields
/// - Multi-select interests from 4 areas
/// - Required avatar upload for activation gate
/// - Shows verification status
/// - Privacy notes
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

  // Form controllers
  final _nameController = TextEditingController(text: 'Member');
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _wardController = TextEditingController();
  final _stakeController = TextEditingController();

  String? _ageRange;
  List<String> _selectedInterests = [];
  String? _avatarUrl;
  bool _avatarSelected = false;
  XFile? _pickedImage;  // for immediate preview before/during upload

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
    // Load via provider (will also populate local state for editing)
    _loadProfile();
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
          // Sanitize any leftover local:// placeholders from failed uploads
          if (_avatarUrl != null && _avatarUrl!.startsWith('local://')) {
            _avatarUrl = null;
          }
          _ageRange = _profile.ageRange;
          _bioController.text = _profile.bio ?? '';
        });
        // Refresh provider for other parts of app
        ref.read(currentProfileProvider.notifier).refresh();
      }
    } catch (_) {
      // Profile load failed; keep defaults
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);

    if (image != null) {
      final user = SupabaseService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to upload a profile picture.')),
          );
        }
        return;
      }
      setState(() {
        _pickedImage = image;
        _avatarSelected = true;
      });
      setState(() => _isLoading = true);
      try {
        final userId = user.id;
        // Real upload to Supabase Storage
        final url = await ProfilesService.uploadAvatar(image, userId);
        setState(() {
          _avatarUrl = url;
          _pickedImage = null; // switch to remote URL
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar uploaded!')),
          );
        }
      } catch (e) {
        // Keep _pickedImage for local preview; clear _avatarUrl so we don't use stale remote
        setState(() {
          _avatarUrl = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed. Make sure "avatars" bucket exists in Supabase Storage (public) and policies from supabase/storage_policies.sql are applied. Error: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // PR2 requirement: Avatar is required to unlock full access
    if (_avatarUrl == null && !_avatarSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A profile photo is required to activate your account.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalAvatarUrl = (_avatarUrl != null && !_avatarUrl!.startsWith('local://')) 
          ? _avatarUrl 
          : _profile.avatarUrl;

      // If we have a picked image but no successful remote URL yet, try upload now (e.g. after creating bucket)
      if (_pickedImage != null && (finalAvatarUrl == null || finalAvatarUrl.startsWith('local://'))) {
        final userId = SupabaseService.currentUser!.id;
        final url = await ProfilesService.uploadAvatar(_pickedImage!, userId);
        finalAvatarUrl = url;
        _avatarUrl = url;
        _pickedImage = null;
      }

      final updatedProfile = UserProfile(
        id: _profile.id,
        displayName: _nameController.text.trim(),
        ageRange: _ageRange,
        bio: _bioController.text.trim(),
        interests: _selectedInterests,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        ward: _wardController.text.trim().isEmpty ? null : _wardController.text.trim(),
        stake: _stakeController.text.trim().isEmpty ? null : _stakeController.text.trim(),
        isVerifiedMember: _profile.isVerifiedMember,
        avatarUrl: finalAvatarUrl,
        createdAt: _profile.createdAt,
      );

      // Real upsert to Supabase
      final saved = await ProfilesService.saveProfile(updatedProfile);

      setState(() {
        _profile = saved;
        _isEditing = false;
        _pickedImage = null;
      });

      // Refresh the shared Riverpod provider so other screens see the update
      await ref.read(currentProfileProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved to Supabase!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
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
                  // Avatar (required gate)
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _pickedImage != null
                              ? FileImage(File(_pickedImage!.path)) as ImageProvider<Object>?
                              : (_avatarUrl != null && !_avatarUrl!.startsWith('local://')
                                  ? NetworkImage(_avatarUrl!)
                                  : null),
                          child: (_pickedImage == null && _avatarUrl == null)
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FloatingActionButton.small(
                              onPressed: _pickAvatar,
                              child: const Icon(Icons.camera_alt),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing && (_pickedImage == null && _avatarUrl == null && !_avatarSelected))
                    Center(
                      child: Text(
                        'Profile photo is required to activate your account.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Basic fields
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _ageRange,
                    decoration: const InputDecoration(labelText: 'Age Range (optional)'),
                    items: ['18-25', '26-35', '36-45', '46+'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: _isEditing ? (v) => setState(() => _ageRange = v) : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bioController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Short Bio'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Interests - 4 areas
                  const Text('Interests (select all that apply)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Helps match you with activities across Spiritual, Social, Physical, Intellectual areas.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),

                  ...InterestsService.grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                        Wrap(
                          spacing: 8,
                          children: entry.value.map((interest) {
                            final selected = _selectedInterests.contains(interest);
                            return FilterChip(
                              label: Text(interest),
                              selected: selected,
                              onSelected: _isEditing
                                  ? (sel) {
                                      setState(() {
                                        if (sel) {
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
                        const SizedBox(height: 12),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // Location / Ward (coarse + optional)
                  TextFormField(
                    controller: _cityController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'City (coarse location only)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _wardController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Ward (optional, self-reported)'),
                  ),
                  TextFormField(
                    controller: _stakeController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(labelText: 'Stake (optional)'),
                  ),

                  const SizedBox(height: 24),

                  // Verification status
                  Card(
                    color: _profile.isVerifiedMember
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(_profile.isVerifiedMember ? Icons.verified : Icons.pending),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _profile.isVerifiedMember
                                  ? 'Verified Member'
                                  : 'Pending Review (your account is in the review queue)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Privacy note: Only coarse city is stored. No precise location. Ward/stake is optional and not verified.',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: 32),

                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Save Profile'),
                          ),
                        ),
                      ],
                    )
                  else
                    FilledButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: const Text('Edit Profile'),
                    ),
                ],
              ),
            ),
    );
  }
}
