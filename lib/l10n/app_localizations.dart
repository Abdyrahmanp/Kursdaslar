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
  /// **'Group Chat'**
  String get tabChat;

  /// No description provided for @tabAiTutor.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get tabAiTutor;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

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
