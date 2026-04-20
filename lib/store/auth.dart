import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthUser {
  final String email;
  final String passwordHash;
  final String displayName;
  final String bio;
  final String? avatarPath;
  final String createdAtIso;

  const LocalAuthUser({
    required this.email,
    required this.passwordHash,
    required this.displayName,
    required this.bio,
    required this.avatarPath,
    required this.createdAtIso,
  });

  LocalAuthUser copyWith({
    String? email,
    String? passwordHash,
    String? displayName,
    String? bio,
    String? avatarPath,
    bool clearAvatar = false,
    String? createdAtIso,
  }) {
    return LocalAuthUser(
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      createdAtIso: createdAtIso ?? this.createdAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'displayName': displayName,
      'bio': bio,
      'avatarPath': avatarPath,
      'createdAtIso': createdAtIso,
    };
  }

  factory LocalAuthUser.fromJson(Map<String, dynamic> json) {
    return LocalAuthUser(
      email: (json['email'] ?? '').toString(),
      passwordHash: (json['passwordHash'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      avatarPath: json['avatarPath']?.toString(),
      createdAtIso: (json['createdAtIso'] ?? DateTime.now().toIso8601String())
          .toString(),
    );
  }
}

class AuthActionResult {
  final bool success;
  final String message;

  const AuthActionResult({
    required this.success,
    required this.message,
  });
}

class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  static const String _usersKey = 'auth_users_v1';
  static const String _currentEmailKey = 'auth_current_email_v1';

  bool _isInitialized = false;
  final List<LocalAuthUser> _users = [];
  String? _currentEmail;

  bool get isInitialized => _isInitialized;

  List<LocalAuthUser> get users => List.unmodifiable(_users);

  LocalAuthUser? get currentUser {
    if (_currentEmail == null) return null;
    for (final user in _users) {
      if (user.email.toLowerCase() == _currentEmail!.toLowerCase()) {
        return user;
      }
    }
    return null;
  }

  bool get isLoggedIn => currentUser != null;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    final usersRaw = prefs.getString(_usersKey);
    final currentEmailRaw = prefs.getString(_currentEmailKey);

    _users.clear();

    if (usersRaw != null && usersRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(usersRaw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _users.add(LocalAuthUser.fromJson(item));
            } else if (item is Map) {
              _users.add(
                LocalAuthUser.fromJson(
                  item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                ),
              );
            }
          }
        }
      } catch (_) {
        // Ignore broken local data.
      }
    }

    _currentEmail = currentEmailRaw;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_users.map((e) => e.toJson()).toList());
    await prefs.setString(_usersKey, encoded);

    if (_currentEmail == null || _currentEmail!.isEmpty) {
      await prefs.remove(_currentEmailKey);
    } else {
      await prefs.setString(_currentEmailKey, _currentEmail!);
    }
  }

  String _hashPassword(String rawPassword) {
    return sha256.convert(utf8.encode(rawPassword)).toString();
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  bool _isValidEmail(String email) {
    final normalized = _normalizeEmail(email);
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
  }

  LocalAuthUser? _findUserByEmail(String email) {
    final normalized = _normalizeEmail(email);
    for (final user in _users) {
      if (user.email.toLowerCase() == normalized) {
        return user;
      }
    }
    return null;
  }

  Future<AuthActionResult> register({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await ensureInitialized();

    final cleanName = displayName.trim();
    final cleanEmail = _normalizeEmail(email);
    final cleanPassword = password.trim();
    final cleanConfirm = confirmPassword.trim();

    if (cleanName.isEmpty) {
      return const AuthActionResult(
        success: false,
        message: 'Please enter your name.',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      return const AuthActionResult(
        success: false,
        message: 'Please enter a valid email address.',
      );
    }

    if (cleanPassword.length < 6) {
      return const AuthActionResult(
        success: false,
        message: 'Password must be at least 6 characters.',
      );
    }

    if (cleanPassword != cleanConfirm) {
      return const AuthActionResult(
        success: false,
        message: 'Passwords do not match.',
      );
    }

    if (_findUserByEmail(cleanEmail) != null) {
      return const AuthActionResult(
        success: false,
        message: 'This email is already registered.',
      );
    }

    final newUser = LocalAuthUser(
      email: cleanEmail,
      passwordHash: _hashPassword(cleanPassword),
      displayName: cleanName,
      bio: 'Collect places, moments and memories.',
      avatarPath: null,
      createdAtIso: DateTime.now().toIso8601String(),
    );

    _users.add(newUser);
    _currentEmail = cleanEmail;
    await _persist();
    notifyListeners();

    return const AuthActionResult(
      success: true,
      message: 'Registration successful.',
    );
  }

  Future<AuthActionResult> login({
    required String email,
    required String password,
  }) async {
    await ensureInitialized();

    final cleanEmail = _normalizeEmail(email);
    final cleanPassword = password.trim();

    if (!_isValidEmail(cleanEmail)) {
      return const AuthActionResult(
        success: false,
        message: 'Please enter a valid email address.',
      );
    }

    if (cleanPassword.isEmpty) {
      return const AuthActionResult(
        success: false,
        message: 'Please enter your password.',
      );
    }

    final user = _findUserByEmail(cleanEmail);
    if (user == null) {
      return const AuthActionResult(
        success: false,
        message: 'No account found for this email.',
      );
    }

    if (user.passwordHash != _hashPassword(cleanPassword)) {
      return const AuthActionResult(
        success: false,
        message: 'Incorrect password.',
      );
    }

    _currentEmail = user.email;
    await _persist();
    notifyListeners();

    return const AuthActionResult(
      success: true,
      message: 'Login successful.',
    );
  }

  Future<void> logout() async {
    await ensureInitialized();
    _currentEmail = null;
    await _persist();
    notifyListeners();
  }

  Future<AuthActionResult> updateCurrentUserProfile({
    required String displayName,
    required String bio,
    String? avatarPath,
    bool clearAvatar = false,
  }) async {
    await ensureInitialized();

    final user = currentUser;
    if (user == null) {
      return const AuthActionResult(
        success: false,
        message: 'No user is currently logged in.',
      );
    }

    final cleanName = displayName.trim().isEmpty
        ? 'City Explorer'
        : displayName.trim();
    final cleanBio = bio.trim().isEmpty
        ? 'Collect places, moments and memories.'
        : bio.trim();

    final index = _users.indexWhere(
      (item) => item.email.toLowerCase() == user.email.toLowerCase(),
    );

    if (index == -1) {
      return const AuthActionResult(
        success: false,
        message: 'User not found.',
      );
    }

    _users[index] = _users[index].copyWith(
      displayName: cleanName,
      bio: cleanBio,
      avatarPath: avatarPath,
      clearAvatar: clearAvatar,
    );

    await _persist();
    notifyListeners();

    return const AuthActionResult(
      success: true,
      message: 'Profile updated.',
    );
  }
}