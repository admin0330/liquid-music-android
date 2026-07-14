package io.github.admin0330.real_liquid_glass_demo

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "real_liquid_glass_demo/updater"
    private var activeDownloadId: Long? = null

    private val downloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val completedId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
            if (completedId == activeDownloadId) {
                installDownloadedApk(completedId)
                activeDownloadId = null
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppVersion" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        result.success(info.versionName ?: "0.0.0")
                    }

                    "downloadAndInstall" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.error("INVALID_URL", "Missing APK URL", null)
                        } else if (requiresInstallPermission()) {
                            openInstallPermissionSettings()
                            result.success("permissionRequired")
                        } else {
                            startDownload(url)
                            result.success("started")
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        val filter = IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(downloadReceiver, filter, RECEIVER_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(downloadReceiver, filter)
        }
    }

    override fun onDestroy() {
        runCatching { unregisterReceiver(downloadReceiver) }
        super.onDestroy()
    }

    private fun requiresInstallPermission(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ),
            )
        }
    }

    private fun startDownload(url: String) {
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle("Real Liquid Glass 更新")
            .setDescription("正在从 GitHub Releases 下载新版 APK")
            .setMimeType("application/vnd.android.package-archive")
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(false)
            .setNotificationVisibility(
                DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED,
            )
            .setDestinationInExternalFilesDir(
                this,
                Environment.DIRECTORY_DOWNLOADS,
                "real-liquid-glass-update-${System.currentTimeMillis()}.apk",
            )

        val manager = getSystemService(DOWNLOAD_SERVICE) as DownloadManager
        activeDownloadId = manager.enqueue(request)
    }

    private fun installDownloadedApk(downloadId: Long) {
        val manager = getSystemService(DOWNLOAD_SERVICE) as DownloadManager
        manager.query(DownloadManager.Query().setFilterById(downloadId)).use { cursor ->
            if (!cursor.moveToFirst()) return
            val status = cursor.getInt(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS),
            )
            if (status != DownloadManager.STATUS_SUCCESSFUL) return
        }

        val apkUri = manager.getUriForDownloadedFile(downloadId) ?: return
        startActivity(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            },
        )
    }
}
