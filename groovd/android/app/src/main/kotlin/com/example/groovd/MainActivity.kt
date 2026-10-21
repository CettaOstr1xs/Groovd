package com.example.groovd

import android.content.ActivityNotFoundException
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
                    if (filePath == null) {
                        result.error("INVALID_PATH", "Story file path is null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "Story file not found: $filePath", null)
                            return@setMethodCallHandler
                        }

                        val uri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val isVideo = filePath.endsWith(".mp4", ignoreCase = true)
                        val explicitMime = call.argument<String>("mimeType")
                        val mimeType = explicitMime ?: if (isVideo) "video/mp4" else "image/png"

                        val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                            type = mimeType
                            putExtra("background_asset_uri", uri)
                            putExtra("source_application", applicationContext.packageName)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        val instagramPackage = "com.instagram.android"
                        grantUriPermission(instagramPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                        var launched = false
                        try {
                            val targetedIntent = Intent(intent).apply {
                                setPackage(instagramPackage)
                            }
                            startActivity(targetedIntent)
                            launched = true
                        } catch (_: Exception) {
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
                        }

                        result.success(launched)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Instagram Stories share error: ${e.message}", e)
                        result.success(false)
                    }
                }
                "encodeVideoFromFrames" -> {
                    val framePaths = call.argument<List<String>>("framePaths")
                    val outputPath = call.argument<String>("outputPath")
                    val width = call.argument<Int>("width") ?: 720
                    val height = call.argument<Int>("height") ?: 1280
                    val fps = call.argument<Int>("fps") ?: 20

                    if (framePaths.isNullOrEmpty() || outputPath == null) {
                        result.error("INVALID_ARGS", "framePaths or outputPath is null", null)
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        val success = encodeBitmapsToMp4(framePaths, outputPath, width, height, fps)
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

    private fun encodeBitmapsToMp4(
        framePaths: List<String>,
        outputPath: String,
        width: Int,
        height: Int,
        fps: Int
    ): Boolean {
        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var inputSurface: Surface? = null
        var muxerStarted = false

        try {
            val outputFile = File(outputPath)
            if (outputFile.exists()) outputFile.delete()

            val mimeType = MediaFormat.MIMETYPE_VIDEO_AVC
            val format = MediaFormat.createVideoFormat(mimeType, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                setInteger(MediaFormat.KEY_BIT_RATE, 3_500_000)
                setInteger(MediaFormat.KEY_FRAME_RATE, fps)
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

            fun drain(endOfStream: Boolean) {
                val timeoutUs = 10000L
                var loop = true
                while (loop) {
                    val encoderStatus = encoder?.dequeueOutputBuffer(bufferInfo, timeoutUs) ?: break
                    if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        if (!endOfStream) loop = false
                    } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        if (!muxerStarted && encoder != null) {
                            videoTrackIndex = muxer?.addTrack(encoder!!.outputFormat) ?: -1
                            muxer?.start()
                            muxerStarted = true
                        }
                    } else if (encoderStatus >= 0) {
                        val encodedData = encoder?.getOutputBuffer(encoderStatus)
                        if (encodedData != null && muxerStarted && videoTrackIndex >= 0) {
                            if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                                bufferInfo.size = 0
                            }
                            if (bufferInfo.size != 0) {
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

            for (path in framePaths) {
                val bmp = BitmapFactory.decodeFile(path) ?: continue
                val surface = inputSurface ?: break
                val canvas = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    surface.lockHardwareCanvas()
                } else {
                    surface.lockCanvas(null)
                }
                canvas.drawBitmap(bmp, null, destRect, null)
                surface.unlockCanvasAndPost(canvas)
                bmp.recycle()
                drain(false)
            }

            encoder.signalEndOfInputStream()
            drain(true)

            return true
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

