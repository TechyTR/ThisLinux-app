package org.test.thislinux

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
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
import rikka.shizuku.Shizuku
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val CHANNEL = "org.test.thislinux/native"
    private val UPDATER_CHANNEL = "thislinux/updater"

    companion object {
        private const val SHIZUKU_PACKAGE =
            "moe.shizuku.privileged.api"

        private const val SHIZUKU_PERMISSION_REQUEST_CODE = 2001
    }

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
                        getSystemService(
                            Context.ACTIVITY_SERVICE
                        ) as android.app.ActivityManager

                    val memoryInfo =
                        android.app.ActivityManager.MemoryInfo()

                    activityManager.getMemoryInfo(memoryInfo)

                    val storage =
                        StatFs(
                            Environment
                                .getDataDirectory()
                                .path
                        )

                    val displayMetrics =
                        resources.displayMetrics

                    val display =
                        windowManager.defaultDisplay

                    val cpuCount =
                        Runtime.getRuntime()
                            .availableProcessors()

                    val supportedAbis =
                        Build.SUPPORTED_ABIS
                            .joinToString(", ")

                    val info =
                        mutableMapOf<String, Any>(

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

                            "total_ram" to
                                memoryInfo.totalMem,

                            "available_ram" to
                                memoryInfo.availMem,

                            "total_storage" to
                                storage.totalBytes,

                            "available_storage" to
                                storage.availableBytes,

                            "screen_width" to
                                displayMetrics.widthPixels,

                            "screen_height" to
                                displayMetrics.heightPixels,

                            "density" to
                                displayMetrics.density,

                            "refresh_rate" to
                                display.refreshRate
                        )

                    if (
                        Build.VERSION.SDK_INT >=
                        Build.VERSION_CODES.S
                    ) {
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
                            (
                                level /
                                    scale.toFloat() *
                                    100
                            ).toInt()
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

                    result.success(
                        mapOf(
                            "level" to batteryPct,
                            "isCharging" to isCharging,
                            "plugSource" to chargePlug,
                            "temperature" to temperature,
                            "state" to when {
                                isCharging -> "Şarj oluyor"
                                batteryPct >= 0 -> "Şarj olmuyor"
                                else -> "Bilinmiyor"
                            },
                            "source" to chargePlug
                        )
                    )
                }

                "getShizukuStatus" -> {

                    val installed =
                        isShizukuInstalled()

                    var running = false
                    var permissionGranted = false
                    var suAvailable = false

                    if (installed) {

                        running =
                            try {
                                Shizuku.pingBinder()
                            } catch (_: Exception) {
                                false
                            }

                        if (running) {

                            permissionGranted =
                                try {
                                    Shizuku.checkSelfPermission() ==
                                        PackageManager.PERMISSION_GRANTED
                                } catch (_: Exception) {
                                    false
                                }

                            suAvailable =
                                try {
                                    Shizuku.getUid() == 0
                                } catch (_: Exception) {
                                    false
                                }
                        }
                    }

                    result.success(
                        mapOf(
                            "installed" to installed,
                            "running" to running,
                            "permissionGranted" to permissionGranted,
                            "suAvailable" to suAvailable
                        )
                    )
                }

                "connectShizuku" -> {

                    try {

                        if (!isShizukuInstalled()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "reason" to "not_installed"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        if (!Shizuku.pingBinder()) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "reason" to "not_running"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        if (
                            Shizuku.checkSelfPermission() ==
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(
                                mapOf(
                                    "success" to true,
                                    "permissionGranted" to true
                                )
                            )
                            return@setMethodCallHandler
                        }

                        if (
                            Shizuku.shouldShowRequestPermissionRationale()
                        ) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "reason" to "rationale"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        Shizuku.requestPermission(
                            SHIZUKU_PERMISSION_REQUEST_CODE
                        )

                        result.success(
                            mapOf(
                                "success" to true,
                                "permissionRequested" to true
                            )
                        )

                    } catch (e: Exception) {

                        result.error(
                            "SHIZUKU_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "openShizuku" -> {

                    try {

                        val intent =
                            packageManager
                                .getLaunchIntentForPackage(
                                    SHIZUKU_PACKAGE
                                )

                        if (intent == null) {

                            result.success(false)

                        } else {

                            intent.addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK
                            )

                            startActivity(intent)

                            result.success(true)
                        }

                    } catch (e: Exception) {

                        result.error(
                            "SHIZUKU_OPEN_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "getInstalledApps" -> {

                    try {

                        val apps =
                            packageManager
                                .getInstalledApplications(
                                    PackageManager.GET_META_DATA
                                )
                                .map {
                                    mapOf(
                                        "packageName" to
                                            it.packageName,
                                        "label" to
                                            packageManager
                                                .getApplicationLabel(it)
                                                .toString(),
                                        "system" to
                                            (
                                                it.flags and
                                                    android.content.pm.ApplicationInfo.FLAG_SYSTEM
                                            ) != 0
                                    )
                                }

                        result.success(apps)

                    } catch (e: Exception) {

                        result.error(
                            "APPS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "getSystemMonitorDetails" -> {

                    val cpuCount =
                        Runtime.getRuntime()
                            .availableProcessors()

                    val frequencies =
                        mutableListOf<Double>()

                    for (i in 0 until cpuCount) {

                        val paths =
                            listOf(
                                "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq",
                                "/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_cur_freq"
                            )

                        var frequency = -1.0

                        for (path in paths) {

                            try {

                                val file = File(path)

                                if (
                                    file.exists() &&
                                    file.canRead()
                                ) {

                                    val value =
                                        file.readText()
                                            .trim()
                                            .toLongOrNull()

                                    if (
                                        value != null &&
                                        value > 0
                                    ) {

                                        frequency =
                                            if (value > 100000) {
                                                value / 1000.0
                                            } else {
                                                value.toDouble()
                                            }

                                        break
                                    }
                                }

                            } catch (_: Exception) {
                            }
                        }

                        frequencies.add(frequency)
                    }

                    val onlineCpuList =
                        try {

                            val file =
                                File(
                                    "/sys/devices/system/cpu/online"
                                )

                            if (
                                file.exists() &&
                                file.canRead()
                            ) {
                                file.readText().trim()
                            } else {
                                "0-${cpuCount - 1}"
                            }

                        } catch (_: Exception) {
                            "Unknown"
                        }

                    val thermalZones =
                        mutableListOf<Map<String, Any>>()

                    try {

                        val directory =
                            File("/sys/class/thermal")

                        if (
                            directory.exists() &&
                            directory.isDirectory
                        ) {

                            val zones =
                                directory.listFiles()
                                    ?.filter {
                                        it.name.startsWith(
                                            "thermal_zone"
                                        )
                                    }
                                    ?.sortedBy {
                                        it.name
                                    }
                                    ?: emptyList()

                            for (zone in zones) {

                                try {

                                    val tempFile =
                                        File(
                                            zone,
                                            "temp"
                                        )

                                    if (
                                        !tempFile.exists() ||
                                        !tempFile.canRead()
                                    ) {
                                        continue
                                    }

                                    val raw =
                                        tempFile
                                            .readText()
                                            .trim()
                                            .toLongOrNull()
                                            ?: continue

                                    val temperature =
                                        raw / 1000.0

                                    if (
                                        temperature < -40 ||
                                        temperature > 150
                                    ) {
                                        continue
                                    }

                                    val type =
                                        try {
                                            File(
                                                zone,
                                                "type"
                                            )
                                                .readText()
                                                .trim()
                                        } catch (_: Exception) {
                                            zone.name
                                        }

                                    thermalZones.add(
                                        mapOf(
                                            "name" to zone.name,
                                            "type" to (
                                                if (type.isBlank()) {
                                                    zone.name
                                                } else {
                                                    type
                                                }
                                            ),
                                            "temperature" to
                                                temperature
                                        )
                                    )

                                } catch (_: Exception) {
                                }
                            }
                        }

                    } catch (_: Exception) {
                    }

                    result.success(
                        mapOf(
                            "cpu_count" to cpuCount,
                            "online_cpu_list" to onlineCpuList,
                            "cpu_frequencies" to frequencies,
                            "thermal_zones" to thermalZones
                        )
                    )
                }

                "checkRoot" -> {

                    val paths =
                        arrayOf(
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

                    var rooted = false

                    for (path in paths) {

                        if (File(path).exists()) {
                            rooted = true
                            break
                        }
                    }

                    result.success(rooted)
                }

                "getUptime" -> {

                    result.success(
                        android.os.SystemClock
                            .elapsedRealtime()
                    )
                }

                "hasStorageAccess" -> {

                    val access =
                        if (
                            Build.VERSION.SDK_INT >=
                            Build.VERSION_CODES.R
                        ) {
                            Environment
                                .isExternalStorageManager()
                        } else {
                            true
                        }

                    result.success(access)
                }

                "openStorageAccessSettings" -> {

                    try {

                        val intent =
                            if (
                                Build.VERSION.SDK_INT >=
                                Build.VERSION_CODES.R
                            ) {

                                Intent(
                                    Settings
                                        .ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION
                                ).apply {
                                    data =
                                        Uri.parse(
                                            "package:$packageName"
                                        )
                                }

                            } else {

                                Intent(
                                    Settings
                                        .ACTION_APPLICATION_DETAILS_SETTINGS
                                ).apply {
                                    data =
                                        Uri.parse(
                                            "package:$packageName"
                                        )
                                }
                            }

                        startActivity(intent)

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
                        call.argument<String>("url")

                    if (downloadUrl.isNullOrBlank()) {

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

                            connection.requestMethod = "GET"
                            connection.connectTimeout = 15000
                            connection.readTimeout = 30000
                            connection.instanceFollowRedirects = true

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
                                        FileProvider
                                            .getUriForFile(
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

    private fun isShizukuInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo(
                SHIZUKU_PACKAGE,
                0
            )
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}
