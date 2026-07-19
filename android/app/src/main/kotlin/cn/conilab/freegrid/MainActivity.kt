package cn.conilab.freegrid

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val PLATFORM_CHANNEL = "cn.conilab.freegrid/platform"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppVersion" -> result.success(appVersionLabel())
                    "openExternalUrl" -> {
                        val source = call.argument<String>("url")
                        result.success(source != null && openExternalUrl(source))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun appVersionLabel(): String {
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }
        val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return "${info.versionName ?: "—"} ($build)"
    }

    private fun openExternalUrl(source: String): Boolean {
        val uri = Uri.parse(source)
        if (uri.scheme != "https") return false
        return try {
            startActivity(
                Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE),
            )
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }
}
