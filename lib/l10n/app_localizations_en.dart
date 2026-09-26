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
  String get tabChat => 'Chat';

  @override
  String get tabTimetable => 'Timetable';

  @override
  String get tabSubjects => 'Subjects';

  @override
  String get tabSettings => 'Settings';

  @override
  String get chatTitle => 'Group-115 Chat 💬';

  @override
  String get chatSubtitle => '25 students • Group chat';

  @override
  String get chatEmpty => 'No messages yet.';

  @override
  String get chatEmptyHint =>
      'Be the first to say hello to your classmates! 👋';

  @override
  String get chatLoadOlder => 'Load previous messages';

  @override
  String get chatHint => 'Write a message…';

  @override
  String get chatRefreshTooltip => 'Refresh messages';

  @override
  String chatReplyHint(String name) {
    return 'Reply to $name…';
  }

  @override
  String chatReplyingTo(String name) {
    return 'Replying to: $name';
  }

  @override
  String get chatMenuReply => 'Reply';

  @override
  String get chatMenuCopy => 'Copy text';

  @override
  String get chatMenuEdit => 'Edit message';

  @override
  String get chatMenuDelete => 'Delete message';

  @override
  String get chatCopied => 'Copied! 📋';

  @override
  String get chatEditTitle => 'Edit message';

  @override
  String get chatEditHint => 'New text…';

  @override
  String get chatDeleteTitle => 'Delete message';

  @override
  String get chatDeleteConfirm =>
      'Are you sure you want to delete this message? This cannot be undone.';

  @override
  String get chatNo => 'No';

  @override
  String get chatYesDelete => 'Yes, delete';

  @override
  String get chatSave => 'Save';

  @override
  String get chatCancel => 'Cancel';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String get chatStatusOnline => 'Online Connected';

  @override
  String get chatStatusSyncing => 'Syncing…';

  @override
  String get chatStatusOffline => 'GSM Offline';

  @override
  String get announcementsTitle => 'Kursdaşlar 🎓';

  @override
  String get announceComposeLabel => 'Write announcement';

  @override
  String get announcePlaceholder => 'Write your announcement here…';

  @override
  String get announceSearchHint => 'Search by name or phone…';

  @override
  String get announceNoResults => 'No student found';

  @override
  String get announceNoResultsHint => 'Check the name or phone number again.';

  @override
  String get announceUrgent => 'Urgent announcement';

  @override
  String get announceOnlineCloud => 'Online Cloud';

  @override
  String get announceModeInternet => 'Internet';

  @override
  String get announceModeSms => 'SMS GSM';

  @override
  String get announceModeDual => 'Both';

  @override
  String get announceSentAll => '🌐 Announcement sent to all students!';

  @override
  String announceSentSelected(int count) {
    return '🌐 Announcement sent to $count selected students!';
  }

  @override
  String get announceSentFailed => '⚠️ Not sent to server, but saved locally.';

  @override
  String get announceFabUploading => 'Uploading to server…';

  @override
  String get announceFabOnlineAll => '🌐 Share Online for All Students';

  @override
  String announceFabOnlineCount(int count) {
    return '🌐 Post for $count students';
  }

  @override
  String announceFabSms(int count) {
    return '📱 Send SMS to $count students';
  }

  @override
  String announceFabDual(int count) {
    return '⚡ Both ($count students)';
  }

  @override
  String get announceFabIdle => 'Select students and write a message';

  @override
  String get announceSelectAll => 'Select All';

  @override
  String get announceUnselectAll => 'Unselect All';

  @override
  String announceCountBadge(int selected, int total) {
    return '$selected of $total';
  }

  @override
  String get settingsTitle => 'Settings ⚙️';

  @override
  String settingsStarshy(String className) {
    return 'Class Captain ⭐ • $className';
  }

  @override
  String settingsStudent(String className) {
    return 'Group Student 🎓 • $className';
  }

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'App display language';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Appearance (Light, Dark, System)';

  @override
  String get settingsThemeSystem => 'System ⚙️';

  @override
  String get settingsThemeLight => 'Light mode ☀️';

  @override
  String get settingsThemeDark => 'Dark mode 🌙';

  @override
  String get settingsPrivacyTitle => 'Security & Rules';

  @override
  String get settingsPrivacySubtitle => 'Privacy policy and terms of use';

  @override
  String get settingsPrivacyExpand => 'Privacy and Usage Policy';

  @override
  String get settingsPrivacyExpandSub => 'About data protection';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutTitle => 'Sign out';

  @override
  String get settingsLogoutBody => 'Are you sure you want to sign out?';

  @override
  String get settingsLogoutCancel => 'Cancel';

  @override
  String get settingsLogoutConfirm => 'Sign out';

  @override
  String get loginTitle => 'Kursdaşlar';

  @override
  String loginSubtitle(String className) {
    return '$className • User Login';
  }

  @override
  String get loginWelcome => 'Welcome! 👋';

  @override
  String get loginWelcomeSub => 'Enter your details to join the group:';

  @override
  String get loginFirstName => 'First name';

  @override
  String get loginFirstNameHint => 'Enter your first name';

  @override
  String get loginLastName => 'Last name';

  @override
  String get loginLastNameHint => 'Enter your last name';

  @override
  String get loginPhone => 'Phone number';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginEmptyFields =>
      'Please enter your name, surname and phone number!';

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
