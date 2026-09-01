package org.test.thislinux

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val channelName = "thislinux/updater"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "downloadAndInstall" -> {
                    val url =
                        call.argument<String>("url")

                    if (url.isNullOrBlank()) {
                        result.error(
                            "INVALID_URL",
                            "APK URL geçersiz.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    downloadAndInstall(
                        url,
                        result
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun downloadAndInstall(
        apkUrl: String,
        result: MethodChannel.Result
    ) {
        Thread {

            var connection:
                HttpURLConnection? = null

            try {
                val url = URL(apkUrl)

                if (url.protocol != "https") {
                    throw Exception(
                        "Sadece HTTPS adresleri kullanılabilir."
                    )
                }

                connection =
                    url.openConnection()
                        as HttpURLConnection

                connection.requestMethod = "GET"
                connection.connectTimeout = 15000
                connection.readTimeout = 30000
                connection.instanceFollowRedirects = true

                connection.connect()

                if (connection.responseCode !in 200..299) {
                    throw Exception(
                        "APK indirilemedi. HTTP ${connection.responseCode}"
                    )
                }

                val updateDirectory =
                    File(
                        cacheDir,
                        "updates"
                    )

                if (!updateDirectory.exists()) {
                    updateDirectory.mkdirs()
                }

                val apkFile =
                    File(
                        updateDirectory,
                        "thislinux-update.apk"
                    )

                if (apkFile.exists()) {
                    apkFile.delete()
                }

                connection.inputStream.use { input ->

                    apkFile.outputStream().use { output ->

                        val buffer =
                            ByteArray(8192)

                        while (true) {

                            val count =
                                input.read(buffer)

                            if (count == -1) {
                                break
                            }

                            output.write(
                                buffer,
                                0,
                                count
                            )
                        }

                        output.flush()
                    }
                }

                if (!apkFile.exists() ||
                    apkFile.length() <= 0
                ) {
                    throw Exception(
                        "İndirilen APK geçersiz."
                    )
                }

                Handler(
                    Looper.getMainLooper()
                ).post {

                    if (
                        Build.VERSION.SDK_INT >=
                        Build.VERSION_CODES.O
                    ) {

                        if (
                            !packageManager
                                .canRequestPackageInstalls()
                        ) {

                            openInstallPermissionSettings()

                            result.success(
                                "permission_required"
                            )

                            return@post
                        }
                    }

                    installApk(apkFile)

                    result.success(true)
                }

            } catch (e: Exception) {

                Handler(
                    Looper.getMainLooper()
                ).post {

                    result.error(
                        "UPDATE_FAILED",
                        e.message
                            ?: "APK güncellemesi başarısız.",
                        null
                    )
                }

            } finally {
                connection?.disconnect()
            }

        }.start()
    }

    private fun openInstallPermissionSettings() {

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O
        ) {

            val intent =
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES
                ).apply {

                    data = Uri.parse(
                        "package:$packageName"
                    )
                }

            startActivity(intent)
        }
    }

    private fun installApk(
        apkFile: File
    ) {

        val apkUri =
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                apkFile
            )

        val intent =
            Intent(Intent.ACTION_VIEW).apply {

                setDataAndType(
                    apkUri,
                    "application/vnd.android.package-archive"
                )

                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )

                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK
                )
            }

        startActivity(intent)
    }
}
