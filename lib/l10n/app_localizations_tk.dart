// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkmen (`tk`).
class AppLocalizationsTk extends AppLocalizations {
  AppLocalizationsTk([String locale = 'tk']) : super(locale);

  @override
  String get appName => 'On Bäş';

  @override
  String get className => 'TOPAR-115';

  @override
  String get tabAnnouncements => 'Duyurular';

  @override
  String get tabChat => 'Topar Çat';

  @override
  String get tabAiTutor => 'AI Mugallym';

  @override
  String get tabSettings => 'Sazlamalar';

  @override
  String get composeLabel => 'Duyuru / Habar';

  @override
  String get composePlaceholder => 'Duyuryňyzy ýazyň…';

  @override
  String get selectAll => 'Hemmesini saýla';

  @override
  String get unselectAll => 'Hemmesini aýyr';

  @override
  String selectedCount(int count, int total) {
    return '$total sanynyň $count saýlandy';
  }

  @override
  String sendButton(int count) {
    return '$count talypba iberi';
  }

  @override
  String get metricChars => 'Harplar';

  @override
  String get metricSmsPerson => 'SMS / adam';

  @override
  String get metricTotalSms => 'Jemi SMS';

  @override
  String get dispatchSending => 'SMS iberilýär…';

  @override
  String dispatchProgress(int current, int total) {
    return '$current / $total iberildi';
  }

  @override
  String get summaryAllSent => 'Ähli habarlar iberildi! 🎉';

  @override
  String get summaryPartial => 'Iberiş tamamlandy';

  @override
  String summarySentCount(int count) {
    return '$count talyp GSM SMS arkaly habarly edildi.';
  }

  @override
  String get summaryDone => 'Ýapmak';

  @override
  String get permissionDenied =>
      'SMS rugsady ret edildi. Sazlamalarda rugsat beriň.';

  @override
  String get openSettings => 'Sazlamalar';

  @override
  String get offlineMode => 'GSM Awtonom';

  @override
  String get keepAppOpen => 'Programmany açyk saklaň…';
}
