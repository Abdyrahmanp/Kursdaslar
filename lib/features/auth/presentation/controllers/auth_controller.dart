import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topar_115/features/announcements/data/models/student_model.dart';
import 'package:topar_115/features/announcements/data/repositories/student_repository.dart';

@immutable
class AuthState {
  final Student? currentStudent;
  final String? errorMessage;
  final bool isLoading;
  final bool isInitialized;

  const AuthState({
    this.currentStudent,
    this.errorMessage,
    this.isLoading = false,
    this.isInitialized = false,
  });

  bool get isAuthenticated => currentStudent != null;
  bool get isStarshy => currentStudent?.isGroupLeader ?? false;
  bool get isGroupLeader => isStarshy;

  /// Sapak temasyny diňe Starşy (Tuşiýewa Abadan) we Döwletgulyýew Abdyrahman goşup bilýär!
  bool get canManageTopics {
    final s = currentStudent;
    if (s == null) return false;
    if (s.isGroupLeader) return true; // Starşy
    final normName = StudentRepository.normalizeName(s.name);
    if (normName.contains('döwletguly') ||
        normName.contains('dowletguly') ||
        s.phone.contains('65254766')) {
      return true;
    }
    return false;
  }

  AuthState copyWith({
    Student? currentStudent,
    String? errorMessage,
    bool? isLoading,
    bool? isInitialized,
    bool clearStudent = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentStudent: clearStudent ? null : (currentStudent ?? this.currentStudent),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _prefKeyId = 'topar115_saved_student_id';

  AuthNotifier() : super(const AuthState()) {
    _tryAutoLogin();
  }

  /// App açylanda öňki girişi barlaýar we awtomatiki açýar.
  Future<void> _tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKeyId);
      if (savedId != null && savedId.isNotEmpty) {
        final match = StudentRepository.findStudentById(savedId);
        if (match != null) {
          state = AuthState(
            currentStudent: match,
            isLoading: false,
            isInitialized: true,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Auto-login error: $e');
    }
    state = state.copyWith(isInitialized: true);
  }

  Future<void> _persistLogin(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyId, id);
    } catch (e) {
      debugPrint('[AuthNotifier] Persist login error: $e');
    }
  }


  /// Attempts login using separate first name, last name, phone number & password.
  Future<bool> loginByFields({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    await Future.delayed(const Duration(milliseconds: 250));

    final match = StudentRepository.findStudentByFields(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      password: password,
    );

    if (match != null) {
      await _persistLogin(match.id);
      state = AuthState(
        currentStudent: match,
        isLoading: false,
        isInitialized: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Maglumatlaryňyz ýalňyş. Ad, familiýa, telefon belgisi ýa-da şifre dogry däl.',
      );
      return false;
    }
  }



  /// Logs out the current user and clears persistent session.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyId);
    } catch (e) {
      debugPrint('[AuthNotifier] Logout error: $e');
    }
    state = const AuthState(isInitialized: true);
  }

  /// Clears any visible error message.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
