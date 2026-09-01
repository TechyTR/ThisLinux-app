package org.test.thislinux

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Process
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "org.test.thislinux/native"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val info = mapOf(
                        "device" to Build.DEVICE,
                        "model" to Build.MODEL,
                        "product" to Build.PRODUCT,
                        "brand" to Build.BRAND,
                        "display" to Build.DISPLAY,
                        "hardware" to Build.HARDWARE,
                        "manufacturer" to Build.MANUFACTURER,
                        "board" to Build.BOARD,
                        "bootloader" to Build.BOOTLOADER,
                        "fingerprint" to Build.FINGERPRINT,
                        "host" to Build.HOST,
                        "id" to Build.ID,
                        "tags" to Build.TAGS,
                        "type" to Build.TYPE,
                        "user" to Build.USER,
                        "cpu_abi" to Build.CPU_ABI,
                        "sdk_int" to Build.VERSION.SDK_INT.toString(),
                        "release" to Build.VERSION.RELEASE,
                        "incremental" to Build.VERSION.INCREMENTAL,
                        "security_patch" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Build.VERSION.SECURITY_PATCH else "N/A"
                    )
                    result.success(info)
                }
                "getBatteryStatus" -> {
                    val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                    val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                    val batteryPct = if (level != -1 && scale != -1) (level / scale.toFloat() * 100).toInt() else -1
                    
                    val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                    val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
                    
                    val plugged = batteryIntent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
                    val chargePlug = when (plugged) {
                        BatteryManager.BATTERY_PLUGGED_USB -> "USB"
                        BatteryManager.BATTERY_PLUGGED_AC -> "AC"
                        BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
                        else -> "None"
                    }

                    val info = mapOf(
                        "level" to batteryPct,
                        "isCharging" to isCharging,
                        "plugSource" to chargePlug
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
                    val uptimeMs = android.os.SystemClock.elapsedRealtime()
                    result.success(uptimeMs)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
