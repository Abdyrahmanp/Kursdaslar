/// App-wide compile-time constants for the "Fifteen" application.
abstract final class AppConstants {
  // ── MethodChannel ─────────────────────────────────────────────────────────
  /// SMS MethodChannel name. Must match [MainActivity.SMS_CHANNEL] in Kotlin.
  static const String smsChannelName = 'com.fifteen.app/sms';

  // ── SMS Dispatch ──────────────────────────────────────────────────────────
  /// Delay between each recipient SMS to prevent carrier spam-blocking.
  static const Duration smsSendDelay = Duration(milliseconds: 500);

  /// Maximum characters in a single-part SMS (GSM 7-bit).
  static const int smsMaxSinglePart = 160;

  /// Maximum characters per part in a multipart SMS (GSM 7-bit, with UDH header).
  static const int smsMaxMultiPart = 153;

  // ── Class Info ────────────────────────────────────────────────────────────
  static const String className = 'TOPAR-115';
  static const String appName = 'Kursdaşlar';
  static const int totalStudents = 25;

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
