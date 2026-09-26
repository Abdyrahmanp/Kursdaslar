// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkmen (`tk`).
class AppLocalizationsTk extends AppLocalizations {
  AppLocalizationsTk([String locale = 'tk']) : super(locale);

  @override
  String get appName => 'Kursdaşlar';

  @override
  String get className => 'TOPAR-115';

  @override
  String get tabAnnouncements => 'Duyduryşlar';

  @override
  String get tabChat => 'Çat';

  @override
  String get tabTimetable => 'Raspisanie';

  @override
  String get tabSubjects => 'Sapaklar';

  @override
  String get tabSettings => 'Sazlamalar';

  @override
  String get chatTitle => 'Topar-115 Çat 💬';

  @override
  String get chatSubtitle => '25 talyp • Umumy söhbetdeşlik';

  @override
  String get chatEmpty => 'Söhbetdeşlikde entek hat ýok.';

  @override
  String get chatEmptyHint => 'Birinji bolup toparadaşlaryňyza salam ýazyň! 👋';

  @override
  String get chatLoadOlder => 'Öňki ýazyşmalary ýükle';

  @override
  String get chatHint => 'Hat ýazyň…';

  @override
  String get chatRefreshTooltip => 'Hatlary täzele';

  @override
  String chatReplyHint(String name) {
    return '$name üçin jogap…';
  }

  @override
  String chatReplyingTo(String name) {
    return 'Jogap berilýär: $name';
  }

  @override
  String get chatMenuReply => 'Jogap ber';

  @override
  String get chatMenuCopy => 'Teksti göçürip al';

  @override
  String get chatMenuEdit => 'Haty üýtget';

  @override
  String get chatMenuDelete => 'Haty poz';

  @override
  String get chatCopied => 'Hat göçürildi! 📋';

  @override
  String get chatEditTitle => 'Haty üýtget';

  @override
  String get chatEditHint => 'Täze tekst…';

  @override
  String get chatDeleteTitle => 'Haty pozmak';

  @override
  String get chatDeleteConfirm =>
      'Bu haty pozmak isleýärsiňizmi? Bu amal yza gaýtaryp bolmaz.';

  @override
  String get chatNo => 'Ýok';

  @override
  String get chatYesDelete => 'Hawa, poz';

  @override
  String get chatSave => 'Sakla';

  @override
  String get chatCancel => 'Ýatyr';

  @override
  String get chatDateToday => 'Şu gün';

  @override
  String get chatDateYesterday => 'Düýn';

  @override
  String get chatStatusOnline => 'Onlaýn Baglanan';

  @override
  String get chatStatusSyncing => 'Täzelenýär…';

  @override
  String get chatStatusOffline => 'GSM Offline';

  @override
  String get announcementsTitle => 'Kursdaşlar 🎓';

  @override
  String get announceComposeLabel => 'Habar ýazmak';

  @override
  String get announcePlaceholder => 'Habaryňyzy şu ýere ýazyň…';

  @override
  String get announceSearchHint =>
      'Toparadaşlary ady ýa-da nomeri boýunça gözlemek…';

  @override
  String get announceNoResults => 'Gözlege laýyk talyp tapylmady';

  @override
  String get announceNoResultsHint => 'Nomeri ýa-da ady täzeden barlap görüň.';

  @override
  String get announceUrgent => 'Gyssagly duýduryş';

  @override
  String get announceOnlineCloud => 'Onlaýn Bulut';

  @override
  String get announceModeInternet => 'Internet';

  @override
  String get announceModeSms => 'SMS GSM';

  @override
  String get announceModeDual => 'Ikisem';

  @override
  String get announceSentAll => '🌐 Duýduryş ähli talyplar üçin ugradyldy!';

  @override
  String announceSentSelected(int count) {
    return '🌐 Duýduryş saýlanan $count talyp üçin ugradyldy!';
  }

  @override
  String get announceSentFailed =>
      '⚠️ Serwere ugradylmady, emma ýerli ýatda saklandy.';

  @override
  String get announceFabUploading => 'Serwere ýüklenýär…';

  @override
  String get announceFabOnlineAll => '🌐 Ähli talyplar üçin Internetde paýlaş';

  @override
  String announceFabOnlineCount(int count) {
    return '🌐 $count talyp üçin serwere goý';
  }

  @override
  String announceFabSms(int count) {
    return '📱 $count talyba SMS ugrat';
  }

  @override
  String announceFabDual(int count) {
    return '⚡ Ikisem ($count talyp)';
  }

  @override
  String get announceFabIdle => 'Talyplary saýlaň we hat ýazyň';

  @override
  String get announceSelectAll => 'Hemmesini saýla';

  @override
  String get announceUnselectAll => 'Hemmesini aýyr';

  @override
  String announceCountBadge(int selected, int total) {
    return '$total sanynyň $selected saýlandy';
  }

  @override
  String get settingsTitle => 'Sazlamalar ⚙️';

  @override
  String settingsStarshy(String className) {
    return 'Topar Starşysy ⭐ • $className';
  }

  @override
  String settingsStudent(String className) {
    return 'Topar Talyby 🎓 • $className';
  }

  @override
  String get settingsLanguageTitle => 'Dil / Language';

  @override
  String get settingsLanguageSubtitle => 'Programmanyň görkezilýän dili';

  @override
  String get settingsThemeTitle => 'Tema / Theme';

  @override
  String get settingsThemeSubtitle => 'Görünüş rejesi (Açyk, Garaňky, Sistem)';

  @override
  String get settingsThemeSystem => 'Sistem ⚙️';

  @override
  String get settingsThemeLight => 'Açyk rejim ☀️';

  @override
  String get settingsThemeDark => 'Garaňky rejim 🌙';

  @override
  String get settingsPrivacyTitle => 'Howpsuzlyk & Düzgünler';

  @override
  String get settingsPrivacySubtitle => 'Gizlinlik syýasaty we ulanyş şertleri';

  @override
  String get settingsPrivacyExpand => 'Gizlinlik we Ulanyş Syýasaty';

  @override
  String get settingsPrivacyExpandSub => 'Maglumatlaryň goralmagy barada';

  @override
  String get settingsLogout => 'Hasapdan çykmak';

  @override
  String get settingsLogoutTitle => 'Hasapdan çykmak';

  @override
  String get settingsLogoutBody =>
      'Hakykatdan hem hasabyňyzdan çykmak isleýärsiňizmi?';

  @override
  String get settingsLogoutCancel => 'Ýatyr';

  @override
  String get settingsLogoutConfirm => 'Çykyş et';

  @override
  String get loginTitle => 'Kursdaşlar';

  @override
  String loginSubtitle(String className) {
    return '$className • Ulanyjy Giriş';
  }

  @override
  String get loginWelcome => 'Hoş geldiňiz! 👋';

  @override
  String get loginWelcomeSub => 'Topara girmek üçin maglumatlaryňyzy giriziň:';

  @override
  String get loginFirstName => 'Adyňyz';

  @override
  String get loginFirstNameHint => 'Adyňyzy giriziň';

  @override
  String get loginLastName => 'Familiýaňyz';

  @override
  String get loginLastNameHint => 'Familiýaňyzy giriziň';

  @override
  String get loginPhone => 'Telefon belgisi';

  @override
  String get loginButton => 'Ulgama gir';

  @override
  String get loginEmptyFields =>
      'Haýyş, adyňyzy, familiýaňyzy we telefon belgiňizi giriziň!';

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
