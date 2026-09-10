package com.example.topar_115

import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — Flutter host activity for "Fifteen" app.
 *
 * Registers a MethodChannel on [SMS_CHANNEL] to expose Android SmsManager
 * to the Flutter/Dart layer. This enables the Offline GSM SMS Dispatcher
 * feature (Step 1) without requiring any third-party SMS plugins.
 *
 * Channel: "com.fifteen.app/sms"
 * Methods:
 *   • sendSingleSms(phone: String, message: String) → Boolean
 *     Sends a (possibly multipart) SMS to a single recipient.
 *     Returns true on success; throws PlatformException on failure.
 */
class MainActivity : FlutterActivity() {

    companion object {
        /** MethodChannel name. Must match [SmsMethodChannel.channelName] in Dart. */
        private const val SMS_CHANNEL = "com.fifteen.app/sms"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── sendSingleSms ──────────────────────────────────────────
                    "sendSingleSms" -> {
                        val phone = call.argument<String>("phone")
                        val message = call.argument<String>("message")

                        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                            result.error(
                                "INVALID_ARGS",
                                "Both 'phone' and 'message' are required.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            val smsManager = getCompatSmsManager()
                            // divideMessage handles GSM 7-bit (160 chars) and
                            // UCS-2 Unicode (70 chars) multipart splitting automatically.
                            val parts = smsManager.divideMessage(message)
                            smsManager.sendMultipartTextMessage(
                                phone,   // destinationAddress
                                null,    // scAddress (use device default)
                                parts,   // message parts
                                null,    // sentIntents  — add PendingIntents in Step 2 for delivery receipts
                                null     // deliveryIntents
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error(
                                "SMS_SEND_ERROR",
                                e.message ?: "Unknown error while sending SMS.",
                                null
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Returns the appropriate [SmsManager] instance based on API level.
     *
     * • API 31+ (Android 12+): [getSystemService] returns a subscription-aware
     *   SmsManager that correctly handles multi-SIM devices.
     * • API < 31: Falls back to the deprecated [SmsManager.getDefault].
     */
    @Suppress("DEPRECATION")
    private fun getCompatSmsManager(): SmsManager {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(SmsManager::class.java)
        } else {
            SmsManager.getDefault()
        }
    }
}
