import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';
import '../../services/sms_method_channel.dart';

// ── Dispatch Status ──────────────────────────────────────────────────────────

/// Sealed hierarchy representing the current dispatch pipeline status.
sealed class DispatchStatus {
  const DispatchStatus();
}

/// No dispatch in progress. FAB is actionable.
class DispatchIdle extends DispatchStatus {
  const DispatchIdle();
}

/// Actively sending — shows animated progress modal.
class DispatchSending extends DispatchStatus {
  /// 1-based index of the current recipient being sent to.
  final int current;
  final int total;
  final String currentStudentName;

  const DispatchSending({
    required this.current,
    required this.total,
    required this.currentStudentName,
  });

  double get progress => total == 0 ? 0 : current / total;
}

/// Batch complete — triggers summary bottom sheet.
class DispatchDone extends DispatchStatus {
  final int sentCount;
  final int failedCount;
  final List<String> failedNames;

  const DispatchDone({
    required this.sentCount,
    required this.failedCount,
    required this.failedNames,
  });

  bool get allSuccess => failedCount == 0;
}

/// Permission was denied by the user.
class DispatchPermissionDenied extends DispatchStatus {
  const DispatchPermissionDenied();
}

// ── State ────────────────────────────────────────────────────────────────────

/// Immutable state snapshot for the SMS Dispatcher screen.
class SmsDispatcherState {
  final List<Student> students;
  final Set<String> selectedIds;
  final String message;
  final String searchQuery;
  final DispatchStatus status;

  const SmsDispatcherState({
    required this.students,
    this.selectedIds = const {},
    this.message = '',
    this.searchQuery = '',
    this.status = const DispatchIdle(),
  });

  factory SmsDispatcherState.initial() => const SmsDispatcherState(
        students: StudentRepository.classStudents,
        selectedIds: {},
        message: '',
        searchQuery: '',
        status: DispatchIdle(),
      );

  // ── Derived Metrics ──────────────────────────────────────────────────────

  int get charCount => message.length;

  /// Number of SMS parts per recipient (GSM 7-bit segmentation).
  /// Single SMS: ≤ 160 chars. Each multipart segment: ≤ 153 chars.
  int get smsParts {
    if (charCount == 0) return 1;
    if (charCount <= AppConstants.smsMaxSinglePart) return 1;
    return ((charCount - 1) ~/ AppConstants.smsMaxMultiPart) + 1;
  }

  /// Total SMS messages that will be consumed across all selected recipients.
  int get totalSmsCount => selectedIds.length * smsParts;

  bool get allSelected =>
      students.isNotEmpty && selectedIds.length == students.length;

  bool get noneSelected => selectedIds.isEmpty;

  bool get canDispatch =>
      selectedIds.isNotEmpty &&
      message.trim().isNotEmpty &&
      status is DispatchIdle;

  List<Student> get selectedStudents =>
      students.where((s) => selectedIds.contains(s.id)).toList();

  List<Student> get filteredStudents {
    if (searchQuery.trim().isEmpty) return students;
    final q = searchQuery.trim().toLowerCase();
    return students.where((s) {
      final nameMatch = s.name.toLowerCase().contains(q);
      final phoneMatch = s.phone.contains(q) ||
          StudentRepository.normalizePhone(s.phone).contains(q);
      return nameMatch || phoneMatch;
    }).toList();
  }

  // ── Copy ─────────────────────────────────────────────────────────────────

  SmsDispatcherState copyWith({
    List<Student>? students,
    Set<String>? selectedIds,
    String? message,
    String? searchQuery,
    DispatchStatus? status,
  }) {
    return SmsDispatcherState(
      students: students ?? this.students,
      selectedIds: selectedIds ?? this.selectedIds,
      message: message ?? this.message,
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Global provider — consumed by [AnnouncementsScreen] and all child widgets.
final smsDispatcherProvider =
    NotifierProvider<SmsDispatcherNotifier, SmsDispatcherState>(
  SmsDispatcherNotifier.new,
);

// ── Notifier ─────────────────────────────────────────────────────────────────

class SmsDispatcherNotifier extends Notifier<SmsDispatcherState> {
  @override
  SmsDispatcherState build() => SmsDispatcherState.initial();

  // ── Message ──────────────────────────────────────────────────────────────

  void updateMessage(String value) {
    state = state.copyWith(message: value);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // ── Selection ────────────────────────────────────────────────────────────

  void toggleStudent(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
    HapticUtils.light();
  }

  void selectAll() {
    state = state.copyWith(
      selectedIds: state.students.map((s) => s.id).toSet(),
    );
    HapticUtils.medium();
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
    HapticUtils.medium();
  }

  void toggleSelectAll() {
    state.allSelected ? clearSelection() : selectAll();
  }

  // ── Dispatch ─────────────────────────────────────────────────────────────

  /// Requests SEND_SMS permission, then iterates over [selectedStudents],
  /// calling [SmsMethodChannel.sendSingleSms] for each with a
  /// [AppConstants.smsSendDelay] anti-spam pause between sends.
  Future<void> dispatch() async {
    if (!state.canDispatch) return;

    // ── Permission check ──────────────────────────────────────────────────
    final permStatus = await Permission.sms.status;
    if (!permStatus.isGranted) {
      final requested = await Permission.sms.request();
      if (!requested.isGranted) {
        state = state.copyWith(status: const DispatchPermissionDenied());
        HapticUtils.error();
        return;
      }
    }

    final recipients = state.selectedStudents;
    final msg = state.message.trim();
    int sentCount = 0;
    int failedCount = 0;
    final failedNames = <String>[];

    // ── Send loop ─────────────────────────────────────────────────────────
    for (int i = 0; i < recipients.length; i++) {
      final student = recipients[i];

      state = state.copyWith(
        status: DispatchSending(
          current: i + 1,
          total: recipients.length,
          currentStudentName: student.shortName,
        ),
      );

      try {
        await SmsMethodChannel.sendSingleSms(
          phone: student.phone,
          message: msg,
        );
        sentCount++;
      } on PlatformException {
        failedCount++;
        failedNames.add(student.shortName);
      }

      // Anti-spam delay — skip after the last recipient.
      if (i < recipients.length - 1) {
        await Future.delayed(AppConstants.smsSendDelay);
      }
    }

    HapticUtils.heavy();

    state = state.copyWith(
      status: DispatchDone(
        sentCount: sentCount,
        failedCount: failedCount,
        failedNames: failedNames,
      ),
    );
  }

  /// Resets status back to [DispatchIdle] — called after the summary sheet
  /// is dismissed by the user.
  void resetToIdle() {
    state = state.copyWith(status: const DispatchIdle());
  }
}
