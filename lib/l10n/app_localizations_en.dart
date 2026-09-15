// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kursdaşlar';

  @override
  String get className => 'TOPAR-115';

  @override
  String get tabAnnouncements => 'Announcements';

  @override
  String get tabChat => 'Group Chat';

  @override
  String get tabAiTutor => 'AI Tutor';

  @override
  String get tabSettings => 'Settings';

  @override
  String get composeLabel => 'Announcement';

  @override
  String get composePlaceholder => 'Type your announcement here…';

  @override
  String get selectAll => 'Select All';

  @override
  String get unselectAll => 'Unselect All';

  @override
  String selectedCount(int count, int total) {
    return '$count of $total selected';
  }

  @override
  String sendButton(int count) {
    return 'Send to $count students';
  }

  @override
  String get metricChars => 'Characters';

  @override
  String get metricSmsPerson => 'SMS / person';

  @override
  String get metricTotalSms => 'Total SMS';

  @override
  String get dispatchSending => 'Sending SMS…';

  @override
  String dispatchProgress(int current, int total) {
    return '$current / $total sent';
  }

  @override
  String get summaryAllSent => 'All messages sent! 🎉';

  @override
  String get summaryPartial => 'Dispatch complete';

  @override
  String summarySentCount(int count) {
    return '$count students notified via GSM SMS.';
  }

  @override
  String get summaryDone => 'Done';

  @override
  String get permissionDenied =>
      'SMS permission denied. Please allow it in Settings.';

  @override
  String get openSettings => 'Settings';

  @override
  String get offlineMode => 'GSM Offline';

  @override
  String get keepAppOpen => 'Please keep the app open…';
}
