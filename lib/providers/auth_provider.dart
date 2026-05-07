import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

/// Holds the signed-in [AppUser] and auth actions.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth) {
    _sub = _auth.authStateChanges().listen(_onAuthState);
  }

  final AuthService _auth;
  StreamSubscription<User?>? _sub;

  AppUser? _appUser;
  bool _loading = true;
  String? _error;

  AppUser? get appUser => _appUser;
  bool get isLoading => _loading;
  String? get errorMessage => _error;
  bool get isAuthenticated => _appUser != null;

  Future<void> _onAuthState(User? user) async {
    _error = null;
    if (user == null) {
      _appUser = null;
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      _appUser = await _auth.getUserProfile(user.uid);
    } catch (e) {
      _error = e.toString();
      _appUser = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _appUser = await _auth.signIn(email: email, password: password);
    } catch (e) {
      _error = _humanizeAuthError(e);
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? sectorId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _appUser = await _auth.register(
        name: name,
        email: email,
        password: password,
        role: role,
        sectorId: sectorId,
      );
    } catch (e) {
      _error = _humanizeAuthError(e);
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    await _auth.signOut();
    _appUser = null;
    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _humanizeAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'That email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        default:
          return e.message ?? e.code;
      }
    }
    return e.toString();
  }
}
