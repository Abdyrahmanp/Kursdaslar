import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tk'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kursdaşlar'**
  String get appName;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'TOPAR-115'**
  String get className;

  /// No description provided for @tabAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get tabAnnouncements;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabTimetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get tabTimetable;

  /// No description provided for @tabSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get tabSubjects;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Group-115 Chat 💬'**
  String get chatTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'25 students • Group chat'**
  String get chatSubtitle;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get chatEmpty;

  /// No description provided for @chatEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Be the first to say hello to your classmates! 👋'**
  String get chatEmptyHint;

  /// No description provided for @chatLoadOlder.
  ///
  /// In en, this message translates to:
  /// **'Load previous messages'**
  String get chatLoadOlder;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get chatHint;

  /// No description provided for @chatRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh messages'**
  String get chatRefreshTooltip;

  /// No description provided for @chatReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}…'**
  String chatReplyHint(String name);

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to: {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatMenuReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatMenuReply;

  /// No description provided for @chatMenuCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get chatMenuCopy;

  /// No description provided for @chatMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatMenuEdit;

  /// No description provided for @chatMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chatMenuDelete;

  /// No description provided for @chatCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied! 📋'**
  String get chatCopied;

  /// No description provided for @chatEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatEditTitle;

  /// No description provided for @chatEditHint.
  ///
  /// In en, this message translates to:
  /// **'New text…'**
  String get chatEditHint;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message? This cannot be undone.'**
  String get chatDeleteConfirm;

  /// No description provided for @chatNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get chatNo;

  /// No description provided for @chatYesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get chatYesDelete;

  /// No description provided for @chatSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get chatSave;

  /// No description provided for @chatCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chatCancel;

  /// No description provided for @chatDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDateToday;

  /// No description provided for @chatDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDateYesterday;

  /// No description provided for @chatStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online Connected'**
  String get chatStatusOnline;

  /// No description provided for @chatStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get chatStatusSyncing;

  /// No description provided for @chatStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'GSM Offline'**
  String get chatStatusOffline;

  /// No description provided for @announcementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Kursdaşlar 🎓'**
  String get announcementsTitle;

  /// No description provided for @announceComposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Write announcement'**
  String get announceComposeLabel;

  /// No description provided for @announcePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your announcement here…'**
  String get announcePlaceholder;

  /// No description provided for @announceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone…'**
  String get announceSearchHint;

  /// No description provided for @announceNoResults.
  ///
  /// In en, this message translates to:
  /// **'No student found'**
  String get announceNoResults;

  /// No description provided for @announceNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Check the name or phone number again.'**
  String get announceNoResultsHint;

  /// No description provided for @announceUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent announcement'**
  String get announceUrgent;

  /// No description provided for @announceOnlineCloud.
  ///
  /// In en, this message translates to:
  /// **'Online Cloud'**
  String get announceOnlineCloud;

  /// No description provided for @announceModeInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get announceModeInternet;

  /// No description provided for @announceModeSms.
  ///
  /// In en, this message translates to:
  /// **'SMS GSM'**
  String get announceModeSms;

  /// No description provided for @announceModeDual.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get announceModeDual;

  /// No description provided for @announceSentAll.
  ///
  /// In en, this message translates to:
  /// **'🌐 Announcement sent to all students!'**
  String get announceSentAll;

  /// No description provided for @announceSentSelected.
  ///
  /// In en, this message translates to:
  /// **'🌐 Announcement sent to {count} selected students!'**
  String announceSentSelected(int count);

  /// No description provided for @announceSentFailed.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Not sent to server, but saved locally.'**
  String get announceSentFailed;

  /// No description provided for @announceFabUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading to server…'**
  String get announceFabUploading;

  /// No description provided for @announceFabOnlineAll.
  ///
  /// In en, this message translates to:
  /// **'🌐 Share Online for All Students'**
  String get announceFabOnlineAll;

  /// No description provided for @announceFabOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'🌐 Post for {count} students'**
  String announceFabOnlineCount(int count);

  /// No description provided for @announceFabSms.
  ///
  /// In en, this message translates to:
  /// **'📱 Send SMS to {count} students'**
  String announceFabSms(int count);

  /// No description provided for @announceFabDual.
  ///
  /// In en, this message translates to:
  /// **'⚡ Both ({count} students)'**
  String announceFabDual(int count);

  /// No description provided for @announceFabIdle.
  ///
  /// In en, this message translates to:
  /// **'Select students and write a message'**
  String get announceFabIdle;

  /// No description provided for @announceSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get announceSelectAll;

  /// No description provided for @announceUnselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect All'**
  String get announceUnselectAll;

  /// No description provided for @announceCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total}'**
  String announceCountBadge(int selected, int total);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings ⚙️'**
  String get settingsTitle;

  /// No description provided for @settingsStarshy.
  ///
  /// In en, this message translates to:
  /// **'Class Captain ⭐ • {className}'**
  String settingsStarshy(String className);

  /// No description provided for @settingsStudent.
  ///
  /// In en, this message translates to:
  /// **'Group Student 🎓 • {className}'**
  String settingsStudent(String className);

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance (Light, Dark, System)'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System ⚙️'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light mode ☀️'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode 🌙'**
  String get settingsThemeDark;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & Rules'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy and terms of use'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsPrivacyExpand.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Usage Policy'**
  String get settingsPrivacyExpand;

  /// No description provided for @settingsPrivacyExpandSub.
  ///
  /// In en, this message translates to:
  /// **'About data protection'**
  String get settingsPrivacyExpandSub;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsLogoutBody;

  /// No description provided for @settingsLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsLogoutCancel;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutConfirm;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Kursdaşlar'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{className} • User Login'**
  String loginSubtitle(String className);

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome! 👋'**
  String get loginWelcome;

  /// No description provided for @loginWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to join the group:'**
  String get loginWelcomeSub;

  /// No description provided for @loginFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get loginFirstName;

  /// No description provided for @loginFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get loginFirstNameHint;

  /// No description provided for @loginLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get loginLastName;

  /// No description provided for @loginLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get loginLastNameHint;

  /// No description provided for @loginPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhone;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name, surname and phone number!'**
  String get loginEmptyFields;

  /// No description provided for @composeLabel.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get composeLabel;

  /// No description provided for @composePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your announcement here…'**
  String get composePlaceholder;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @unselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect All'**
  String get unselectAll;

  /// Recipient selection count indicator
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} selected'**
  String selectedCount(int count, int total);

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send to {count} students'**
  String sendButton(int count);

  /// No description provided for @metricChars.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get metricChars;

  /// No description provided for @metricSmsPerson.
  ///
  /// In en, this message translates to:
  /// **'SMS / person'**
  String get metricSmsPerson;

  /// No description provided for @metricTotalSms.
  ///
  /// In en, this message translates to:
  /// **'Total SMS'**
  String get metricTotalSms;

  /// No description provided for @dispatchSending.
  ///
  /// In en, this message translates to:
  /// **'Sending SMS…'**
  String get dispatchSending;

  /// No description provided for @dispatchProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} sent'**
  String dispatchProgress(int current, int total);

  /// No description provided for @summaryAllSent.
  ///
  /// In en, this message translates to:
  /// **'All messages sent! 🎉'**
  String get summaryAllSent;

  /// No description provided for @summaryPartial.
  ///
  /// In en, this message translates to:
  /// **'Dispatch complete'**
  String get summaryPartial;

  /// No description provided for @summarySentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students notified via GSM SMS.'**
  String summarySentCount(int count);

  /// No description provided for @summaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get summaryDone;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'SMS permission denied. Please allow it in Settings.'**
  String get permissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'GSM Offline'**
  String get offlineMode;

  /// No description provided for @keepAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Please keep the app open…'**
  String get keepAppOpen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tk':
      return AppLocalizationsTk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
