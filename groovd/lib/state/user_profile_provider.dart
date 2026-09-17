import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String userId;
  final String userName;
  final String userHandle;
  final String? avatarPath;

  const UserProfile({
    this.userId = 'user_me',
    this.userName = 'CRITIC // YOU',
    this.userHandle = '@groovd_me',
    this.avatarPath,
  });

  UserProfile copyWith({
    String? userId,
    String? userName,
    String? userHandle,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userHandle': userHandle,
      'avatarPath': avatarPath,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String? ?? 'user_me',
      userName: map['userName'] as String? ?? 'CRITIC // YOU',
      userHandle: map['userHandle'] as String? ?? '@groovd_me',
      avatarPath: map['avatarPath'] as String?,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  static const String _avatarKey = 'groovd_user_avatar_path_v1';
  static const String _nameKey = 'groovd_user_name_v1';
  static const String _handleKey = 'groovd_user_handle_v1';

  final ImagePicker _picker = ImagePicker();

  @override
  UserProfile build() {
    _loadFromPrefs();
    return const UserProfile();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString(_avatarKey);
      final savedName = prefs.getString(_nameKey);
      final savedHandle = prefs.getString(_handleKey);

      String? validAvatarPath;
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        final file = File(savedAvatar);
        if (await file.exists()) {
          validAvatarPath = savedAvatar;
        }
      }

      state = state.copyWith(
        userName: savedName ?? state.userName,
        userHandle: savedHandle ?? state.userHandle,
        avatarPath: validAvatarPath,
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
      await prefs.setString(_nameKey, state.userName);
      await prefs.setString(_handleKey, state.userHandle);

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

  Future<void> updateProfile({String? name, String? handle}) async {
    state = state.copyWith(
      userName: name ?? state.userName,
      userHandle: handle ?? state.userHandle,
    );
    await _persist();
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
