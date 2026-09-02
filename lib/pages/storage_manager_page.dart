package org.test.thislinux

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val CHANNEL = "org.test.thislinux/native"
    private val UPDATER_CHANNEL = "thislinux/updater"

    override fun configureFlutterEngine(
        @NonNull flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getDeviceInfo" -> {

                    val activityManager =
                        getSystemService(Context.ACTIVITY_SERVICE)
                                as android.app.ActivityManager

                    val memoryInfo =
                        android.app.ActivityManager.MemoryInfo()

                    activityManager.getMemoryInfo(memoryInfo)

                    val totalRam =
                        memoryInfo.totalMem

                    val availableRam =
                        memoryInfo.availMem

                    val storage =
                        StatFs(Environment.getDataDirectory().path)

                    val totalStorage =
                        storage.totalBytes

                    val availableStorage =
                        storage.availableBytes

                    val cpuCount =
                        Runtime.getRuntime().availableProcessors()

                    val supportedAbis =
                        Build.SUPPORTED_ABIS.joinToString(", ")

                    val displayMetrics =
                        resources.displayMetrics

                    val display =
                        windowManager.defaultDisplay

                    val refreshRate =
                        display.refreshRate

                    val info = mutableMapOf<String, Any>(

                        "device" to Build.DEVICE,

                        "model" to Build.MODEL,

                        "product" to Build.PRODUCT,

                        "brand" to Build.BRAND,

                        "manufacturer" to Build.MANUFACTURER,

                        "hardware" to Build.HARDWARE,

                        "board" to Build.BOARD,

                        "bootloader" to Build.BOOTLOADER,

                        "display" to Build.DISPLAY,

                        "fingerprint" to Build.FINGERPRINT,

                        "host" to Build.HOST,

                        "id" to Build.ID,

                        "type" to Build.TYPE,

                        "user" to Build.USER,

                        "cpu_abi" to Build.CPU_ABI,

                        "supported_abis" to supportedAbis,

                        "cpu_count" to cpuCount,

                        "sdk_int" to Build.VERSION.SDK_INT,

                        "release" to Build.VERSION.RELEASE,

                        "incremental" to Build.VERSION.INCREMENTAL,

                        "security_patch" to
                                if (
                                    Build.VERSION.SDK_INT >=
                                    Build.VERSION_CODES.M
                                ) {
                                    Build.VERSION.SECURITY_PATCH
                                } else {
                                    "N/A"
                                },

                        "total_ram" to totalRam,

                        "available_ram" to availableRam,

                        "total_storage" to totalStorage,

                        "available_storage" to availableStorage,

                        "screen_width" to
                                displayMetrics.widthPixels,

                        "screen_height" to
                                displayMetrics.heightPixels,

                        "density" to
                                displayMetrics.density,

                        "refresh_rate" to refreshRate
                    )

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {

                        info["soc_manufacturer"] =
                            Build.SOC_MANUFACTURER

                        info["soc_model"] =
                            Build.SOC_MODEL
                    }

                    result.success(info)
                }

                "getBatteryStatus" -> {

                    val batteryIntent =
                        registerReceiver(
                            null,
                            IntentFilter(
                                Intent.ACTION_BATTERY_CHANGED
                            )
                        )

                    val level =
                        batteryIntent?.getIntExtra(
                            BatteryManager.EXTRA_LEVEL,
                            -1
                        ) ?: -1

                    val scale =
                        batteryIntent?.getIntExtra(
                            BatteryManager.EXTRA_SCALE,
                            -1
                        ) ?: -1

                    val batteryPct =
                        if (
                            level != -1 &&
                            scale != -1
                        ) {
                            (level /
                                    scale.toFloat() *
                                    100).toInt()
                        } else {
                            -1
                        }

                    val status =
                        batteryIntent?.getIntExtra(
                            BatteryManager.EXTRA_STATUS,
                            -1
                        ) ?: -1

                    val isCharging =
                        status ==
                                BatteryManager.BATTERY_STATUS_CHARGING ||
                        status ==
                                BatteryManager.BATTERY_STATUS_FULL

                    val plugged =
                        batteryIntent?.getIntExtra(
                            BatteryManager.EXTRA_PLUGGED,
                            -1
                        ) ?: -1

                    val chargePlug =
                        when (plugged) {

                            BatteryManager.BATTERY_PLUGGED_USB ->
                                "USB"

                            BatteryManager.BATTERY_PLUGGED_AC ->
                                "AC"

                            BatteryManager.BATTERY_PLUGGED_WIRELESS ->
                                "Wireless"

                            else ->
                                "None"
                        }

                    val temperatureRaw =
                        batteryIntent?.getIntExtra(
                            BatteryManager.EXTRA_TEMPERATURE,
                            -1
                        ) ?: -1

                    val temperature =
                        if (temperatureRaw >= 0) {
                            temperatureRaw / 10.0
                        } else {
                            -1.0
                        }

                    val info =
                        mapOf(
                            "level" to batteryPct,
                            "isCharging" to isCharging,
                            "plugSource" to chargePlug,
                            "temperature" to temperature
                        )

                    result.success(info)
                }

                "checkRoot" -> {

                    val paths = arrayOf(

                        "/system/app/Superuser.apk",

                        "/sbin/su",

                        "/system/bin/su",

                        "/system/xbin/su",

                        "/data/local/xbin/su",

                        "/data/local/bin/su",

                        "/system/sd/xbin/su",

                        "/system/bin/failsafe/su",

                        "/data/local/su"
                    )

                    var isRooted = false

                    for (path in paths) {

                        if (File(path).exists()) {

                            isRooted = true
                            break
                        }
                    }

                    result.success(isRooted)
                }

                "getUptime" -> {

                    val uptimeMs =
                        android.os.SystemClock
                            .elapsedRealtime()

                    result.success(uptimeMs)
                }

                "hasStorageAccess" -> {

                    val hasAccess =
                        if (
                            Build.VERSION.SDK_INT >=
                            Build.VERSION_CODES.R
                        ) {
                            Environment.isExternalStorageManager()
                        } else {
                            true
                        }

                    result.success(hasAccess)
                }

                "openStorageAccessSettings" -> {

                    try {

                        if (
                            Build.VERSION.SDK_INT >=
                            Build.VERSION_CODES.R
                        ) {

                            val intent =
                                Intent(
                                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION
                                )

                            intent.data =
                                Uri.parse(
                                    "package:$packageName"
                                )

                            startActivity(intent)

                        } else {

                            val intent =
                                Intent(
                                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                )

                            intent.data =
                                Uri.parse(
                                    "package:$packageName"
                                )

                            startActivity(intent)
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "SETTINGS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "requestLegacyStoragePermission" -> {

                    if (
                        Build.VERSION.SDK_INT <
                        Build.VERSION_CODES.R
                    ) {

                        requestPermissions(
                            arrayOf(
                                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                            ),
                            1001
                        )
                    }

                    result.success(true)
                }

                else -> {

                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATER_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "downloadAndInstall" -> {

                    val downloadUrl =
                        call.argument<String>(
                            "url"
                        )

                    if (
                        downloadUrl.isNullOrBlank()
                    ) {

                        result.error(
                            "INVALID_URL",
                            "Download URL is empty.",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    Thread {

                        try {

                            val connection =
                                URL(downloadUrl)
                                    .openConnection()
                                    as HttpURLConnection

                            connection.requestMethod =
                                "GET"

                            connection.connectTimeout =
                                15000

                            connection.readTimeout =
                                30000

                            connection.instanceFollowRedirects =
                                true

                            connection.connect()

                            if (
                                connection.responseCode !in
                                200..299
                            ) {

                                throw Exception(
                                    "Download failed: HTTP ${connection.responseCode}"
                                )
                            }

                            val apkFile =
                                File(
                                    cacheDir,
                                    "stellar-center-update.apk"
                                )

                            if (apkFile.exists()) {
                                apkFile.delete()
                            }

                            connection.inputStream.use { input ->

                                apkFile.outputStream().use { output ->

                                    input.copyTo(
                                        output,
                                        8192
                                    )
                                }
                            }

                            connection.disconnect()

                            runOnUiThread {

                                try {

                                    val apkUri =
                                        FileProvider.getUriForFile(
                                            this,
                                            "$packageName.fileprovider",
                                            apkFile
                                        )

                                    val installIntent =
                                        Intent(
                                            Intent.ACTION_VIEW
                                        )

                                    installIntent.setDataAndType(
                                        apkUri,
                                        "application/vnd.android.package-archive"
                                    )

                                    installIntent.addFlags(
                                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                                    )

                                    installIntent.addFlags(
                                        Intent.FLAG_ACTIVITY_NEW_TASK
                                    )

                                    startActivity(
                                        installIntent
                                    )

                                    result.success(true)

                                } catch (e: Exception) {

                                    result.error(
                                        "INSTALL_ERROR",
                                        e.message,
                                        null
                                    )
                                }
                            }

                        } catch (e: Exception) {

                            runOnUiThread {

                                result.error(
                                    "DOWNLOAD_ERROR",
                                    e.message,
                                    null
                                )
                            }
                        }
                    }.start()
                }

                else -> {

                    result.notImplemented()
                }
            }
        }
    }
}
