import 'package:flutter/services.dart';
import 'package:topar_115/core/constants/app_constants.dart';

/// Type-safe Dart wrapper around the Android SMS [MethodChannel].
///
/// All channel communication is centralised here so that:
///   • The channel name is a single source of truth ([AppConstants.smsChannelName]).
///   • Platform exceptions are surfaced as typed [PlatformException]s.
///   • Future enhancements (e.g., EventChannel for delivery receipts) are
///     added here without touching business logic.
abstract final class SmsMethodChannel {
  static const MethodChannel _channel =
      MethodChannel(AppConstants.smsChannelName);

  /// Sends a single (possibly multipart) SMS to [phone].
  ///
  /// The Android side calls [SmsManager.divideMessage] + [sendMultipartTextMessage]
  /// so messages exceeding 160 chars are automatically split into linked parts.
  ///
  /// Throws a [PlatformException] with code:
  ///   • `"INVALID_ARGS"` — if phone or message is blank.
  ///   • `"SMS_SEND_ERROR"` — if SmsManager throws on the native side.
  static Future<void> sendSingleSms({
    required String phone,
    required String message,
  }) async {
    await _channel.invokeMethod<bool>('sendSingleSms', {
      'phone': phone,
      'message': message,
    });
  }
}
