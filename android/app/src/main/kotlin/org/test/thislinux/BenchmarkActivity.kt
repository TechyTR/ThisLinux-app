package org.test.thislinux

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.ui.PlayerView

class BenchmarkActivity : Activity() {

    companion object {
        const val RESULT_AVERAGE_FPS = "averageFps"
        const val RESULT_MINIMUM_FPS = "minimumFps"
        const val RESULT_ONE_PERCENT_LOW = "onePercentLow"
        const val RESULT_DROPPED_FRAMES = "droppedFrames"
        const val RESULT_RENDERED_FRAMES = "renderedFrames"
        const val RESULT_FRAME_TIME_MS = "frameTimeMs"
        const val RESULT_STUTTER_RATE = "stutterRate"
        const val RESULT_VIDEO_WIDTH = "videoWidth"
        const val RESULT_VIDEO_HEIGHT = "videoHeight"
        const val RESULT_VIDEO_FPS = "videoFps"
        const val RESULT_ERROR = "error"
    }

    private var player: ExoPlayer? = null

    private var droppedFrames = 0
    private var renderedFrames = 0

    private var firstFrameTimeMs = 0L
    private var lastFrameTimeMs = 0L

    private var totalProcessingOffsetUs = 0L
    private var processingFrameCount = 0

    private var minObservedFps = Double.MAX_VALUE

    private var videoWidth = 0
    private var videoHeight = 0
    private var videoFps = 0.0

    private lateinit var statusText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        window.decorView.systemUiVisibility =
            (
                android.view.View.SYSTEM_UI_FLAG_FULLSCREEN
                    or android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )

        val root = FrameLayout(this)

        statusText = TextView(this).apply {
            text = "4K 120 FPS benchmark hazırlanıyor..."
            textSize = 18f
            setTextColor(
                ContextCompat.getColor(
                    this@BenchmarkActivity,
                    android.R.color.white
                )
            )
            setBackgroundColor(
                ContextCompat.getColor(
                    this@BenchmarkActivity,
                    android.R.color.black
                )
            )
            setPadding(32, 32, 32, 32)
        }

        root.addView(
            statusText,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        setContentView(root)

        startBenchmark(root)
    }

    private fun startBenchmark(root: FrameLayout) {
        try {
            val playerView = PlayerView(this).apply {
                useController = false
                keepScreenOn = true
                setBackgroundColor(
                    ContextCompat.getColor(
                        this@BenchmarkActivity,
                        android.R.color.black
                    )
                )
            }

            root.removeAllViews()
            root.addView(
                playerView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )

            player = ExoPlayer.Builder(this)
                .build()
                .also { exoPlayer ->

                    playerView.player = exoPlayer

                    exoPlayer.addAnalyticsListener(
                        object : AnalyticsListener {

                            override fun onDroppedVideoFrames(
                                eventTime: AnalyticsListener.EventTime,
                                droppedFrames: Int,
                                elapsedMs: Long
                            ) {
                                this@BenchmarkActivity
                                    .droppedFrames += droppedFrames
                            }

                            override fun onRenderedFirstFrame(
                                eventTime: AnalyticsListener.EventTime,
                                output: Any,
                                renderTimeMs: Long
                            ) {
                                if (firstFrameTimeMs == 0L) {
                                    firstFrameTimeMs =
                                        renderTimeMs
                                }

                                lastFrameTimeMs =
                                    renderTimeMs
                            }

                            override fun onVideoFrameProcessingOffset(
                                eventTime: AnalyticsListener.EventTime,
                                totalProcessingOffsetUs: Long,
                                frameCount: Int
                            ) {
                                this@BenchmarkActivity
                                    .totalProcessingOffsetUs +=
                                    totalProcessingOffsetUs

                                this@BenchmarkActivity
                                    .processingFrameCount +=
                                    frameCount
                            }

                            override fun onVideoSizeChanged(
                                eventTime: AnalyticsListener.EventTime,
                                videoSize: androidx.media3.common.VideoSize
                            ) {
                                videoWidth =
                                    videoSize.width

                                videoHeight =
                                    videoSize.height
                            }

                            override fun onVideoInputFormatChanged(
                                eventTime: AnalyticsListener.EventTime,
                                format: androidx.media3.common.Format,
                                decoderReuseEvaluation:
                                    androidx.media3.exoplayer.mediacodec.DecoderReuseEvaluation?
                            ) {
                                if (format.frameRate > 0f) {
                                    videoFps =
                                        format.frameRate
                                            .toDouble()
                                }

                                if (format.width > 0) {
                                    videoWidth =
                                        format.width
                                }

                                if (format.height > 0) {
                                    videoHeight =
                                        format.height
                                }
                            }
                        }
                    )

                    exoPlayer.addListener(
                        object : Player.Listener {

                            override fun onPlaybackStateChanged(
                                playbackState: Int
                            ) {
                                when (playbackState) {

                                    Player.STATE_READY -> {
                                        statusText.text =
                                            "4K 120 FPS video oynatılıyor..."
                                    }

                                    Player.STATE_ENDED -> {
                                        finishBenchmark()
                                    }
                                }
                            }

                            override fun onPlayerError(
                                error: androidx.media3.common.PlaybackException
                            ) {
                                returnError(
                                    "Video oynatılamadı: ${error.message}"
                                )
                            }
                        }
                    )

                    val mediaItem =
                        MediaItem.fromUri(
                            "asset:///benchmark_4k120.mp4"
                        )

                    exoPlayer.setMediaItem(
                        mediaItem
                    )

                    exoPlayer.prepare()

                    exoPlayer.playWhenReady = true
                }

        } catch (e: Exception) {
            returnError(
                e.message ?: "Bilinmeyen benchmark hatası"
            )
        }
    }

    private fun finishBenchmark() {
        val currentPlayer = player
            ?: returnError("Player bulunamadı.")

        val durationMs =
            currentPlayer.duration

        val decoderCounters =
            currentPlayer.videoDecoderCounters

        if (decoderCounters != null) {
            renderedFrames =
                decoderCounters.renderedOutputBufferCount
        }

        val actualDurationMs =
            if (
                durationMs > 0 &&
                durationMs != androidx.media3.common.C.TIME_UNSET
            ) {
                durationMs
            } else if (
                firstFrameTimeMs > 0L &&
                lastFrameTimeMs > firstFrameTimeMs
            ) {
                lastFrameTimeMs -
                    firstFrameTimeMs
            } else {
                0L
            }

        if (renderedFrames <= 0) {
            returnError(
                "Video karesi ölçülemedi."
            )
            return
        }

        if (actualDurationMs <= 0L) {
            returnError(
                "Video süresi ölçülemedi."
            )
            return
        }

        val durationSeconds =
            actualDurationMs / 1000.0

        val averageFps =
            renderedFrames /
                durationSeconds

        val expectedFrames =
            if (videoFps > 0) {
                (durationSeconds * videoFps)
                    .toInt()
            } else {
                renderedFrames +
                    droppedFrames
            }

        val totalFrames =
            maxOf(
                expectedFrames,
                renderedFrames + droppedFrames
            )

        val stutterRate =
            if (totalFrames > 0) {
                droppedFrames.toDouble() /
                    totalFrames.toDouble() *
                    100.0
            } else {
                0.0
            }

        val frameTimeMs =
            if (averageFps > 0) {
                1000.0 / averageFps
            } else {
                0.0
            }

        val processingAverageMs =
            if (processingFrameCount > 0) {
                totalProcessingOffsetUs
                    .toDouble() /
                    processingFrameCount
                    .toDouble() /
                    1000.0
            } else {
                0.0
            }

        val minimumFps =
            if (minObservedFps != Double.MAX_VALUE) {
                minObservedFps
            } else {
                averageFps
            }

        val onePercentLow =
            if (averageFps > 0) {
                if (stutterRate <= 0.01) {
                    averageFps
                } else {
                    averageFps *
                        (1.0 - stutterRate / 100.0)
                }
            } else {
                0.0
            }

        val result =
            intent.apply {
                putExtra(
                    RESULT_AVERAGE_FPS,
                    averageFps
                )

                putExtra(
                    RESULT_MINIMUM_FPS,
                    minimumFps
                )

                putExtra(
                    RESULT_ONE_PERCENT_LOW,
                    onePercentLow
                )

                putExtra(
                    RESULT_DROPPED_FRAMES,
                    droppedFrames
                )

                putExtra(
                    RESULT_RENDERED_FRAMES,
                    renderedFrames
                )

                putExtra(
                    RESULT_FRAME_TIME_MS,
                    frameTimeMs
                )

                putExtra(
                    RESULT_STUTTER_RATE,
                    stutterRate
                )

                putExtra(
                    RESULT_VIDEO_WIDTH,
                    videoWidth
                )

                putExtra(
                    RESULT_VIDEO_HEIGHT,
                    videoHeight
                )

                putExtra(
                    RESULT_VIDEO_FPS,
                    videoFps
                )

                putExtra(
                    "processingAverageMs",
                    processingAverageMs
                )
            }

        setResult(
            RESULT_OK,
            result
        )

        player?.release()
        player = null

        finish()
    }

    private fun returnError(
        message: String
    ) {
        val result =
            intent.apply {
                putExtra(
                    RESULT_ERROR,
                    message
                )
            }

        setResult(
            RESULT_CANCELED,
            result
        )

        player?.release()
        player = null

        finish()
    }

    override fun onDestroy() {
        player?.release()
        player = null

        super.onDestroy()
    }
}
