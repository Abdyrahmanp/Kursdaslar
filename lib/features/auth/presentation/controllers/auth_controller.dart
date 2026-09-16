import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topar_115/features/announcements/data/models/student_model.dart';
import 'package:topar_115/features/announcements/data/repositories/student_repository.dart';

@immutable
class AuthState {
  final Student? currentStudent;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.currentStudent,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isAuthenticated => currentStudent != null;
  bool get isStarshy => currentStudent?.isGroupLeader ?? false;
  bool get isGroupLeader => isStarshy;

  AuthState copyWith({
    Student? currentStudent,
    String? errorMessage,
    bool? isLoading,
    bool clearStudent = false,
    bool clearError = false,
  }) {
    return AuthState(
      currentStudent: clearStudent ? null : (currentStudent ?? this.currentStudent),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Attempts login using separate first name, last name & phone number.
  Future<bool> loginByFields({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    await Future.delayed(const Duration(milliseconds: 300)); // Smooth UI transition

    final match = StudentRepository.findStudentByFields(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    if (match != null) {
      state = AuthState(
        currentStudent: match,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Bu toparda beýle talyp tapylmady. Adyňyzy, familiýaňyzy ýa-da nomeriňizi barlaşdyryň.',
      );
      return false;
    }
  }

  /// Attempts login using student's full name & phone number.
  Future<bool> login({required String name, required String phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    await Future.delayed(const Duration(milliseconds: 300)); // Smooth UI transition

    final match = StudentRepository.findStudent(name, phone);

    if (match != null) {
      state = AuthState(
        currentStudent: match,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Bu toparda beýle talyp tapylmady. At, familiýa ýa-da nomeriňizi barlaşdyryň.',
      );
      return false;
    }
  }

  /// Logs out the current user.
  void logout() {
    state = const AuthState();
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
