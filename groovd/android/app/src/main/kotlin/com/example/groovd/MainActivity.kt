package com.example.groovd

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.groovd/instagram_stories"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToInstagramStories") {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_PATH", "Story image file path is null", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "Story image file not found: $filePath", null)
                        return@setMethodCallHandler
                    }

                    val uri: Uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        file
                    )

                    val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                        setDataAndType(uri, "image/png")
                        putExtra("background_asset_uri", uri)
                        putExtra("source_application", applicationContext.packageName)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    val instagramPackage = "com.instagram.android"
                    val isInstagramInstalled = try {
                        packageManager.getPackageInfo(instagramPackage, 0)
                        true
                    } catch (e: Exception) {
                        false
                    }

                    if (isInstagramInstalled) {
                        intent.setPackage(instagramPackage)
                        grantUriPermission(instagramPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        val activities = packageManager.queryIntentActivities(intent, 0)
                        if (activities.isNotEmpty()) {
                            for (resolveInfo in activities) {
                                grantUriPermission(
                                    resolveInfo.activityInfo.packageName,
                                    uri,
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                                )
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                } catch (e: ActivityNotFoundException) {
                    result.success(false)
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}

