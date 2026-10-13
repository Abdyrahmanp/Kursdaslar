package com.example.topar_115

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.telephony.SmsManager
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val SMS_CHANNEL = "com.fifteen.app/sms"
        private const val FILE_PICKER_CHANNEL = "com.fifteen.app/file_picker"
        private const val REQUEST_CODE_PICK_FILE = 1001
    }

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── SMS Channel ────────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
                            val parts = smsManager.divideMessage(message)
                            smsManager.sendMultipartTextMessage(
                                phone,
                                null,
                                parts,
                                null,
                                null
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

        // ── Native File Picker Channel ─────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_PICKER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFile" -> {
                        if (pendingResult != null) {
                            result.error("ALREADY_ACTIVE", "Another picker operation is in progress.", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result

                        val filterType = call.argument<String>("type") ?: "*/*"
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            when (filterType) {
                                "image" -> type = "image/*"
                                "pdf" -> type = "application/pdf"
                                "pptx" -> {
                                    type = "*/*"
                                    putExtra(
                                        Intent.EXTRA_MIME_TYPES,
                                        arrayOf(
                                            "application/vnd.ms-powerpoint",
                                            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                                            "application/octet-stream"
                                        )
                                    )
                                }
                                else -> {
                                    type = "*/*"
                                    putExtra(
                                        Intent.EXTRA_MIME_TYPES,
                                        arrayOf(
                                            "image/*",
                                            "application/pdf",
                                            "application/vnd.ms-powerpoint",
                                            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
                                        )
                                    )
                                }
                            }
                        }

                        try {
                            startActivityForResult(
                                Intent.createChooser(intent, "Faýly saýlaň"),
                                REQUEST_CODE_PICK_FILE
                            )
                        } catch (e: Exception) {
                            pendingResult = null
                            result.error("ACTIVITY_NOT_FOUND", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_FILE) {
            val res = pendingResult ?: return
            pendingResult = null

            if (resultCode != Activity.RESULT_OK || data == null || data.data == null) {
                res.success(null)
                return
            }

            val uri: Uri = data.data!!
            try {
                var fileName = "faýl"
                var fileSize: Long = 0

                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (cursor.moveToFirst()) {
                        if (nameIndex != -1) fileName = cursor.getString(nameIndex) ?: "faýl"
                        if (sizeIndex != -1) fileSize = cursor.getLong(sizeIndex)
                    }
                }

                val lowerName = fileName.lowercase()
                val type = when {
                    lowerName.endsWith(".png") || lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg") || lowerName.endsWith(".webp") -> "image"
                    lowerName.endsWith(".pdf") -> "pdf"
                    lowerName.endsWith(".pptx") || lowerName.endsWith(".ppt") -> "pptx"
                    else -> "file"
                }

                val inputStream: InputStream? = contentResolver.openInputStream(uri)
                val bytes = inputStream?.readBytes() ?: ByteArray(0)
                inputStream?.close()

                if (fileSize == 0L) {
                    fileSize = bytes.size.toLong()
                }

                val sizeStr = formatFileSize(fileSize)
                val base64Data = Base64.encodeToString(bytes, Base64.NO_WRAP)
                val mimePrefix = when (type) {
                    "image" -> if (lowerName.endsWith(".png")) "data:image/png;base64," else "data:image/jpeg;base64,"
                    "pdf" -> "data:application/pdf;base64,"
                    "pptx" -> "data:application/vnd.openxmlformats-officedocument.presentationml.presentation;base64,"
                    else -> "data:application/octet-stream;base64,"
                }

                val fileResult = HashMap<String, Any>()
                fileResult["name"] = fileName
                fileResult["size"] = sizeStr
                fileResult["type"] = type
                fileResult["data"] = mimePrefix + base64Data
                fileResult["byteLength"] = bytes.size

                res.success(fileResult)
            } catch (e: Exception) {
                res.error("FILE_READ_ERROR", e.message ?: "Faýly okap bolmady", null)
            }
        }
    }

    private fun formatFileSize(bytes: Long): String {
        return when {
            bytes >= 1024 * 1024 -> String.format("%.1f MB", bytes.toDouble() / (1024 * 1024))
            bytes >= 1024 -> String.format("%d KB", bytes / 1024)
            else -> "$bytes B"
        }
    }

    @Suppress("DEPRECATION")
    private fun getCompatSmsManager(): SmsManager {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(SmsManager::class.java)
        } else {
            SmsManager.getDefault()
        }
    }
}
