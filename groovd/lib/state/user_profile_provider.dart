import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_providers.dart';

class UserProfile {
  final String userId;
  final String userName;
  final String userHandle;
  final String bio;
  final String? avatarPath;
  final String? backdropPath;

  const UserProfile({
    this.userId = 'user_me',
    this.userName = 'CRITIC // YOU',
    this.userHandle = '@groovd_me',
    this.bio = 'Sonic explorer & vinyl enthusiast. Chronicling deep cuts and 10/10 masterpieces.',
    this.avatarPath,
    this.backdropPath,
  });

  UserProfile copyWith({
    String? userId,
    String? userName,
    String? userHandle,
    String? bio,
    String? avatarPath,
    String? backdropPath,
    bool clearAvatar = false,
    bool clearBackdrop = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      bio: bio ?? this.bio,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      backdropPath: clearBackdrop ? null : (backdropPath ?? this.backdropPath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userHandle': userHandle,
      'bio': bio,
      'avatarPath': avatarPath,
      'backdropPath': backdropPath,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String? ?? 'user_me',
      userName: map['userName'] as String? ?? 'CRITIC // YOU',
      userHandle: map['userHandle'] as String? ?? '@groovd_me',
      bio: map['bio'] as String? ??
          'Sonic explorer & vinyl enthusiast. Chronicling deep cuts and 10/10 masterpieces.',
      avatarPath: map['avatarPath'] as String?,
      backdropPath: map['backdropPath'] as String?,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  static const String _avatarKey = 'groovd_user_avatar_path_v1';
  static const String _backdropKey = 'groovd_user_backdrop_path_v1';
  static const String _nameKey = 'groovd_user_name_v1';
  static const String _handleKey = 'groovd_user_handle_v1';
  static const String _bioKey = 'groovd_user_bio_v1';

  final ImagePicker _picker = ImagePicker();

  @override
  UserProfile build() {
    _loadFromPrefs();

    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null) {
        syncWithFirebaseUser(user);
      }
    });

    return const UserProfile();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString(_avatarKey);
      final savedBackdrop = prefs.getString(_backdropKey);
      final savedName = prefs.getString(_nameKey);
      final savedHandle = prefs.getString(_handleKey);
      final savedBio = prefs.getString(_bioKey);

      String? validAvatarPath;
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        if (savedAvatar.startsWith('http://') || savedAvatar.startsWith('https://')) {
          validAvatarPath = savedAvatar;
        } else {
          final file = File(savedAvatar);
          if (await file.exists()) {
            validAvatarPath = savedAvatar;
          }
        }
      }

      String? validBackdropPath;
      if (savedBackdrop != null && savedBackdrop.isNotEmpty) {
        if (savedBackdrop.startsWith('http://') || savedBackdrop.startsWith('https://')) {
          validBackdropPath = savedBackdrop;
        } else {
          final file = File(savedBackdrop);
          if (await file.exists()) {
            validBackdropPath = savedBackdrop;
          }
        }
      }

      state = state.copyWith(
        userName: savedName ?? state.userName,
        userHandle: savedHandle ?? state.userHandle,
        bio: savedBio ?? state.bio,
        avatarPath: validAvatarPath,
        backdropPath: validBackdropPath,
      );
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.avatarPath != null) {
        await prefs.setString(_avatarKey, state.avatarPath!);
      } else {
        await prefs.remove(_avatarKey);
      }

      if (state.backdropPath != null) {
        await prefs.setString(_backdropKey, state.backdropPath!);
      } else {
        await prefs.remove(_backdropKey);
      }

      await prefs.setString(_nameKey, state.userName);
      await prefs.setString(_handleKey, state.userHandle);
      await prefs.setString(_bioKey, state.bio);

      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(state.userId)
            .set(state.toMap(), SetOptions(merge: true))
            .timeout(const Duration(milliseconds: 2500));
      }
    } catch (_) {}
  }

  /// Picks a raw photo from the user's gallery for framing/adjustment.
  Future<File?> pickRawImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (_) {
      return null;
    }
  }

  /// Sets the cropped/adjusted image path as the active avatar.
  Future<bool> setCustomAvatar(String croppedImagePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Clean up previous avatar if it was in the app directory and different
      if (state.avatarPath != null && state.avatarPath != croppedImagePath) {
        try {
          final oldFile = File(state.avatarPath!);
          if (await oldFile.exists() && oldFile.path.contains(appDir.path)) {
            await oldFile.delete();
          }
        } catch (_) {}
      }

      state = state.copyWith(avatarPath: croppedImagePath);
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Picks a new profile image from the user's gallery and saves it directly.
  Future<bool> pickAvatarFromGallery() async {
    try {
      final rawFile = await pickRawImageFromGallery();
      if (rawFile == null) return false;

      // Copy image into application documents directory so it is persistent
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');

      await rawFile.copy(savedImage.path);
      return await setCustomAvatar(savedImage.path);
    } catch (_) {
      return false;
    }
  }

  /// Removes the custom profile photo and reverts to the neo-brutalist monogram.
  Future<void> removeAvatar() async {
    if (state.avatarPath != null) {
      try {
        final oldFile = File(state.avatarPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (_) {}
    }

    state = state.copyWith(clearAvatar: true);
    await _persist();
  }

  /// Picks a new background photo (Patron backdrop) from gallery and saves it to local storage.
  Future<bool> pickBackdropFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2560,
        maxHeight: 1440,
        imageQuality: 95,
      );
      if (pickedFile == null) return false;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'backdrop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');

      if (state.backdropPath != null) {
        try {
          final oldFile = File(state.backdropPath!);
          if (await oldFile.exists() && oldFile.path.contains(appDir.path)) {
            await oldFile.delete();
          }
        } catch (_) {}
      }

      await File(pickedFile.path).copy(savedImage.path);
      state = state.copyWith(backdropPath: savedImage.path);
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes the custom background/backdrop photo.
  Future<void> removeBackdrop() async {
    if (state.backdropPath != null) {
      try {
        final oldFile = File(state.backdropPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (_) {}
    }

    state = state.copyWith(clearBackdrop: true);
    await _persist();
  }

  /// Updates critic bio / self-expression description.
  Future<void> updateBio(String newBio) async {
    state = state.copyWith(bio: newBio);
    await _persist();
  }

  Future<void> updateProfile({String? name, String? handle, String? bio}) async {
    state = state.copyWith(
      userName: name ?? state.userName,
      userHandle: handle ?? state.userHandle,
      bio: bio ?? state.bio,
    );
    await _persist();
  }

  /// Updates the user's Groovd display name and handle.
  Future<void> updateCriticIdentity({required String name, required String handle}) async {
    final cleanHandle = handle.trim().startsWith('@') ? handle.trim() : '@${handle.trim()}';
    state = state.copyWith(
      userName: name.trim(),
      userHandle: cleanHandle,
    );
    await _persist();
  }

  /// Syncs user profile state with authenticated Firebase User & Firestore.
  Future<void> syncWithFirebaseUser(User user) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        state = UserProfile(
          userId: user.uid,
          userName: data['userName'] as String? ?? (user.displayName ?? 'CRITIC').toUpperCase(),
          userHandle: data['userHandle'] as String? ?? '@${(user.displayName ?? 'critic').toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
          bio: data['bio'] as String? ?? state.bio,
          avatarPath: data['avatarPath'] as String? ?? user.photoURL,
          backdropPath: data['backdropPath'] as String?,
        );
      } else {
        state = state.copyWith(
          userId: user.uid,
          userName: (user.displayName ?? state.userName).toUpperCase(),
        );
      }
      await _persist();
    } catch (_) {
      state = state.copyWith(userId: user.uid);
    }
  }

  /// Resets user profile to local guest mode upon signing out.
  Future<void> resetToGuest() async {
    state = const UserProfile(userId: 'user_me');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_avatarKey);
      await prefs.remove(_backdropKey);
      await prefs.setString(_nameKey, state.userName);
      await prefs.setString(_handleKey, state.userHandle);
      await prefs.setString(_bioKey, state.bio);
    } catch (_) {}
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
