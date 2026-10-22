package com.example.groovd

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.groovd/instagram_stories"
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToInstagramStories" -> {
                    val filePath = call.argument<String>("filePath")
                    val explicitMime = call.argument<String>("mimeType")
                    shareMediaToTarget(filePath, explicitMime, "instagram", result)
                }
                "shareToPlatform" -> {
                    val filePath = call.argument<String>("filePath")
                    val explicitMime = call.argument<String>("mimeType")
                    val platform = call.argument<String>("platform") ?: "system"
                    shareMediaToTarget(filePath, explicitMime, platform, result)
                }
                "encodeVideoFromFrames" -> {
                    val framePaths = call.argument<List<String>>("framePaths")
                    val outputPath = call.argument<String>("outputPath")
                    val width = call.argument<Int>("width") ?: 720
                    val height = call.argument<Int>("height") ?: 1280
                    val fps = call.argument<Int>("fps") ?: 60
                    val durationMs = call.argument<Int>("durationMs") ?: 11500
                    val activeDurationMs = call.argument<Int>("activeDurationMs") ?: 8500
                    val endHoldMs = call.argument<Int>("endHoldMs") ?: 3000

                    if (framePaths.isNullOrEmpty() || outputPath == null) {
                        result.error("INVALID_ARGS", "framePaths or outputPath is null", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        val success = encodeBitmapsToMp4(
                            framePaths,
                            outputPath,
                            width,
                            height,
                            fps,
                            durationMs,
                            activeDurationMs,
                            endHoldMs
                        )
                        Handler(Looper.getMainLooper()).post {
                            result.success(success)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun shareMediaToTarget(
        filePath: String?,
        explicitMime: String?,
        platform: String,
        result: MethodChannel.Result
    ) {
        if (filePath == null) {
            result.error("INVALID_PATH", "Story file path is null", null)
            return
        }

        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "Story file not found: $filePath", null)
                return
            }

            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val isVideo = filePath.endsWith(".mp4", ignoreCase = true)
            val mimeType = explicitMime ?: if (isVideo) "video/mp4" else "image/png"
            var launched = false

            when (platform.lowercase()) {
                "instagram" -> {
                    val instagramPackage = "com.instagram.android"
                    grantUriPermission(instagramPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                    val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                        setDataAndType(uri, mimeType)
                        clipData = ClipData.newRawUri("media", uri)
                        putExtra("source_application", applicationContext.packageName)
                        putExtra("background_asset_uri", uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        setPackage(instagramPackage)
                    }

                    try {
                        startActivity(intent)
                        launched = true
                    } catch (e: Exception) {
                        Log.w("MainActivity", "Direct Instagram launch failed: ${e.message}")
                        try {
                            intent.setPackage(null)
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
                                launched = true
                            }
                        } catch (e2: Exception) {
                            Log.e("MainActivity", "Fallback Instagram launch failed: ${e2.message}", e2)
                        }
                    }
                }
                "whatsapp" -> {
                    val whatsappPackages = listOf("com.whatsapp", "com.whatsapp.w4b")
                    for (pkg in whatsappPackages) {
                        try {
                            packageManager.getPackageInfo(pkg, 0)
                            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("media", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                setPackage(pkg)
                            }
                            startActivity(intent)
                            launched = true
                            break
                        } catch (_: Exception) {}
                    }
                }
                "tiktok" -> {
                    val tiktokPackages = listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill")
                    for (pkg in tiktokPackages) {
                        try {
                            packageManager.getPackageInfo(pkg, 0)
                            grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newRawUri("media", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                setPackage(pkg)
                            }
                            startActivity(intent)
                            launched = true
                            break
                        } catch (_: Exception) {}
                    }
                }
                else -> {
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = mimeType
                        putExtra(Intent.EXTRA_STREAM, uri)
                        clipData = ClipData.newRawUri("media", uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    val chooser = Intent.createChooser(intent, "Share Track Scorecard").apply {
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(chooser)
                    launched = true
                }
            }

            result.success(launched)
        } catch (e: Exception) {
            Log.e("MainActivity", "Share to $platform error: ${e.message}", e)
            result.success(false)
        }
    }

    private fun encodeBitmapsToMp4(
        framePaths: List<String>,
        outputPath: String,
        width: Int,
        height: Int,
        fps: Int,
        durationMs: Int,
        activeDurationMs: Int,
        endHoldMs: Int
    ): Boolean {
        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var inputSurface: Surface? = null
        var muxerStarted = false

        // 60 FPS for ultra-smooth fluid playback
        val targetFps = if (fps >= 30) fps else 60

        try {
            val outputFile = File(outputPath)
            if (outputFile.exists()) outputFile.delete()

            val mimeType = MediaFormat.MIMETYPE_VIDEO_AVC
            val format = MediaFormat.createVideoFormat(mimeType, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                setInteger(MediaFormat.KEY_BIT_RATE, 5_000_000)
                setInteger(MediaFormat.KEY_FRAME_RATE, targetFps)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            }

            encoder = MediaCodec.createEncoderByType(mimeType)
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            inputSurface = encoder.createInputSurface()
            encoder.start()

            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            var videoTrackIndex = -1
            val bufferInfo = MediaCodec.BufferInfo()
            val destRect = Rect(0, 0, width, height)
            var outputFrameIndex = 0L

            fun drain(endOfStream: Boolean) {
                val timeoutUs = 10000L
                var loop = true
                var noOutputCounter = 0
                while (loop) {
                    val encoderStatus = encoder?.dequeueOutputBuffer(bufferInfo, timeoutUs) ?: break
                    if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        if (!endOfStream) {
                            loop = false
                        } else {
                            noOutputCounter++
                            if (noOutputCounter > 30) {
                                loop = false
                            }
                        }
                    } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        if (!muxerStarted && encoder != null) {
                            videoTrackIndex = muxer?.addTrack(encoder!!.outputFormat) ?: -1
                            muxer?.start()
                            muxerStarted = true
                        }
                    } else if (encoderStatus >= 0) {
                        noOutputCounter = 0
                        val encodedData = encoder?.getOutputBuffer(encoderStatus)
                        if (encodedData != null && muxerStarted && videoTrackIndex >= 0) {
                            if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                                bufferInfo.size = 0
                            }
                            if (bufferInfo.size != 0) {
                                bufferInfo.presentationTimeUs = outputFrameIndex * 1_000_000L / targetFps
                                outputFrameIndex++
                                encodedData.position(bufferInfo.offset)
                                encodedData.limit(bufferInfo.offset + bufferInfo.size)
                                muxer?.writeSampleData(videoTrackIndex, encodedData, bufferInfo)
                            }
                        }
                        encoder?.releaseOutputBuffer(encoderStatus, false)
                        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            loop = false
                        }
                    }
                }
            }

            // Calculate active frames (e.g. 8.5s * 60fps = 510 frames)
            val activeTargetFrames = (activeDurationMs.toLong() * targetFps / 1000L).toInt()
            val repeatPerFrame = if (framePaths.isNotEmpty()) maxOf(1, activeTargetFrames / framePaths.size) else 1
            // End hold frames (e.g. 3.0s * 60fps = 180 frames)
            val endHoldFrames = (endHoldMs.toLong() * targetFps / 1000L).toInt()

            for (i in framePaths.indices) {
                val path = framePaths[i]
                val bmp = BitmapFactory.decodeFile(path) ?: continue
                val surface = inputSurface ?: break

                for (r in 0 until repeatPerFrame) {
                    val canvas = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        surface.lockHardwareCanvas()
                    } else {
                        surface.lockCanvas(null)
                    }
                    canvas.drawBitmap(bmp, null, destRect, null)
                    surface.unlockCanvasAndPost(canvas)
                    drain(false)
                }

                // If this is the final frame of the animation, hold it still for the additional end-hold duration
                if (i == framePaths.size - 1 && endHoldFrames > 0) {
                    for (h in 0 until endHoldFrames) {
                        val canvas = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            surface.lockHardwareCanvas()
                        } else {
                            surface.lockCanvas(null)
                        }
                        canvas.drawBitmap(bmp, null, destRect, null)
                        surface.unlockCanvasAndPost(canvas)
                        drain(false)
                    }
                }

                bmp.recycle()
            }

            encoder.signalEndOfInputStream()
            drain(true)

            val finished = outputFile.exists() && outputFile.length() > 5000L
            Log.d("MainActivity", "encodeBitmapsToMp4 finished=$finished, size=${outputFile.length()}, frames=$outputFrameIndex")
            return finished
        } catch (e: Exception) {
            Log.e("MainActivity", "encodeBitmapsToMp4 error: ${e.message}", e)
            return false
        } finally {
            try {
                encoder?.stop()
                encoder?.release()
            } catch (_: Exception) {}
            try {
                if (muxerStarted) {
                    muxer?.stop()
                }
                muxer?.release()
            } catch (_: Exception) {}
            try {
                inputSurface?.release()
            } catch (_: Exception) {}
        }
    }
}

