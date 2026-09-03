package org.test.thislinux

import android.app.Activity
import android.content.Intent
import android.media.MediaFormat
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.mediacodec.DecoderReuseEvaluation
import androidx.media3.exoplayer.video.VideoFrameMetadataListener
import androidx.media3.ui.PlayerView

class BenchmarkActivity : Activity() {

    companion object {

        const val RESULT_AVERAGE_FPS =
            "averageFps"

        const val RESULT_MINIMUM_FPS =
            "minimumFps"

        const val RESULT_ONE_PERCENT_LOW =
            "onePercentLow"

        const val RESULT_DROPPED_FRAMES =
            "droppedFrames"

        const val RESULT_RENDERED_FRAMES =
            "renderedFrames"

        const val RESULT_FRAME_TIME_MS =
            "frameTimeMs"

        const val RESULT_STUTTER_RATE =
            "stutterRate"

        const val RESULT_VIDEO_WIDTH =
            "videoWidth"

        const val RESULT_VIDEO_HEIGHT =
            "videoHeight"

        const val RESULT_VIDEO_FPS =
            "videoFps"

        const val RESULT_ERROR =
            "error"

        const val RESULT_PROCESSING_AVERAGE_MS =
            "processingAverageMs"
    }

    private var player: ExoPlayer? = null

    private var droppedFrames = 0

    private var renderedFrames = 0

    private var videoWidth = 0

    private var videoHeight = 0

    private var videoFps = 0.0

    private var totalProcessingOffsetUs = 0L

    private var processingFrameCount = 0

    private val frameIntervalsMs =
        mutableListOf<Double>()

    private var lastReleaseTimeNs = 0L

    private var benchmarkFinished = false

    private lateinit var statusText: TextView

    private val benchmarkVideos =
        listOf(
            "assets/Bosphorus_3840x2160_120fps_420_8bit_HEVC_RAW.mp4",
            "assets/HoneyBee_3840x2160_120fps_420_8bit_HEVC_RAW.mp4",
            "assets/Jockey_3840x2160_120fps_420_8bit_HEVC_RAW.mp4"
        )

    override fun onCreate(
        savedInstanceState: Bundle?
    ) {
        super.onCreate(
            savedInstanceState
        )

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        window.decorView.systemUiVisibility =
            (
                View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )

        val root =
            FrameLayout(this)

        statusText =
            TextView(this).apply {

                text =
                    "4K 120 FPS benchmark hazırlanıyor..."

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

                setPadding(
                    32,
                    32,
                    32,
                    32
                )
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

    private fun startBenchmark(
        root: FrameLayout
    ) {
        try {

            val playerView =
                PlayerView(this).apply {

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

            val exoPlayer =
                ExoPlayer.Builder(this)
                    .build()

            player = exoPlayer

            playerView.player =
                exoPlayer

            exoPlayer.addAnalyticsListener(
                object : AnalyticsListener {

                    override fun onDroppedVideoFrames(
                        eventTime:
                            AnalyticsListener.EventTime,
                        droppedFrames: Int,
                        elapsedMs: Long
                    ) {
                        this@BenchmarkActivity
                            .droppedFrames +=
                            droppedFrames
                    }

                    override fun onVideoFrameProcessingOffset(
                        eventTime:
                            AnalyticsListener.EventTime,
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
                        eventTime:
                            AnalyticsListener.EventTime,
                        videoSize: VideoSize
                    ) {
                        if (videoSize.width > 0) {
                            videoWidth =
                                videoSize.width
                        }

                        if (videoSize.height > 0) {
                            videoHeight =
                                videoSize.height
                        }
                    }

                    override fun onVideoInputFormatChanged(
                        eventTime:
                            AnalyticsListener.EventTime,
                        format: Format,
                        decoderReuseEvaluation:
                            DecoderReuseEvaluation?
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

            exoPlayer.setVideoFrameMetadataListener(
                object :
                    VideoFrameMetadataListener {

                    override fun onVideoFrameAboutToBeRendered(
                        presentationTimeUs: Long,
                        releaseTimeNs: Long,
                        format: Format,
                        mediaFormat: MediaFormat?
                    ) {

                        if (releaseTimeNs <= 0L) {
                            return
                        }

                        if (lastReleaseTimeNs > 0L) {

                            val intervalMs =
                                (
                                    releaseTimeNs -
                                        lastReleaseTimeNs
                                ) / 1_000_000.0

                            if (
                                intervalMs > 0.1 &&
                                intervalMs < 1000.0
                            ) {
                                synchronized(
                                    frameIntervalsMs
                                ) {
                                    frameIntervalsMs.add(
                                        intervalMs
                                    )
                                }
                            }
                        }

                        lastReleaseTimeNs =
                            releaseTimeNs
                    }
                }
            )

            exoPlayer.addListener(
                object : Player.Listener {

                    override fun onMediaItemTransition(
                        mediaItem: MediaItem?,
                        reason: Int
                    ) {

                        /*
                         * Videolar arası geçiş süresini
                         * FPS/stutter ölçümüne dahil etmiyoruz.
                         */
                        lastReleaseTimeNs = 0L

                        val index =
                            exoPlayer.currentMediaItemIndex

                        val name =
                            when (index) {
                                0 -> "Bosphorus"
                                1 -> "HoneyBee"
                                2 -> "Jockey"
                                else -> "Video"
                            }

                        runOnUiThread {
                            statusText.text =
                                "4K 120 FPS test ediliyor...\n\n$name"
                        }
                    }

                    override fun onPlaybackStateChanged(
                        playbackState: Int
                    ) {

                        when (playbackState) {

                            Player.STATE_BUFFERING -> {
                                runOnUiThread {
                                    statusText.text =
                                        "4K 120 FPS video hazırlanıyor..."
                                }
                            }

                            Player.STATE_READY -> {
                                runOnUiThread {
                                    statusText.text =
                                        "4K 120 FPS benchmark çalışıyor..."
                                }
                            }

                            Player.STATE_ENDED -> {
                                if (!benchmarkFinished) {
                                    benchmarkFinished = true
                                    finishBenchmark()
                                }
                            }
                        }
                    }

                    override fun onPlayerError(
                        error:
                            androidx.media3.common.PlaybackException
                    ) {
                        if (!benchmarkFinished) {
                            benchmarkFinished = true

                            returnError(
                                "4K 120 FPS video oynatılamadı: " +
                                    (error.message
                                        ?: "Bilinmeyen Media3 hatası")
                            )
                        }
                    }
                }
            )

            val mediaItems =
                benchmarkVideos.map { path ->
                    MediaItem.fromUri(
                        "asset:///flutter_assets/$path"
                    )
                }

            exoPlayer.setMediaItems(
                mediaItems
            )

            exoPlayer.prepare()

            exoPlayer.playWhenReady =
                true

        } catch (e: Exception) {

            returnError(
                e.message
                    ?: "Bilinmeyen benchmark hatası"
            )
        }
    }

    private fun finishBenchmark() {

        val currentPlayer =
            player
                ?: run {
                    returnError(
                        "Player bulunamadı."
                    )
                    return
                }

        val durationMs =
            currentPlayer.duration

        val decoderCounters =
            currentPlayer.videoDecoderCounters

        if (decoderCounters != null) {
            renderedFrames =
                decoderCounters
                    .renderedOutputBufferCount
        }

        if (renderedFrames <= 0) {
            returnError(
                "Video karesi ölçülemedi."
            )
            return
        }

        if (
            durationMs <= 0L ||
            durationMs == C.TIME_UNSET
        ) {
            returnError(
                "Toplam video süresi ölçülemedi."
            )
            return
        }

        val durationSeconds =
            durationMs / 1000.0

        /*
         * 3 video × 5 saniye = yaklaşık 15 saniye.
         * 120 FPS × 15 saniye = yaklaşık 1800 kaynak karesi.
         */
        val averageFps =
            renderedFrames /
                durationSeconds

        val fpsSamples =
            synchronized(
                frameIntervalsMs
            ) {
                frameIntervalsMs
                    .filter {
                        it > 0.1 &&
                            it < 1000.0
                    }
                    .map {
                        1000.0 / it
                    }
                    .filter {
                        it > 0.0 &&
                            it <= 1000.0
                    }
            }

        val minimumFps =
            if (fpsSamples.isNotEmpty()) {
                fpsSamples.minOrNull()
                    ?: averageFps
            } else {
                averageFps
            }

        val sortedSamples =
            fpsSamples.sorted()

        val onePercentLow =
            if (sortedSamples.isNotEmpty()) {

                val sampleCount =
                    maxOf(
                        1,
                        (
                            sortedSamples.size *
                                0.01
                        ).toInt()
                    )

                sortedSamples
                    .take(sampleCount)
                    .average()

            } else {
                averageFps
            }

        val expectedFrames =
            if (videoFps >= 119.0) {

                (
                    durationSeconds *
                        videoFps
                ).roundToInt()

            } else {

                renderedFrames +
                    droppedFrames
            }

        val totalFrames =
            maxOf(
                expectedFrames,
                renderedFrames +
                    droppedFrames
            )

        val stutterRate =
            if (totalFrames > 0) {

                (
                    droppedFrames
                        .toDouble() /
                        totalFrames
                            .toDouble()
                ) * 100.0

            } else {
                0.0
            }

        val frameTimeMs =
            if (averageFps > 0.0) {
                1000.0 /
                    averageFps
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

        val result =
            Intent()

        result.putExtra(
            RESULT_AVERAGE_FPS,
            averageFps
        )

        result.putExtra(
            RESULT_MINIMUM_FPS,
            minimumFps
        )

        result.putExtra(
            RESULT_ONE_PERCENT_LOW,
            onePercentLow
        )

        result.putExtra(
            RESULT_DROPPED_FRAMES,
            droppedFrames
        )

        result.putExtra(
            RESULT_RENDERED_FRAMES,
            renderedFrames
        )

        result.putExtra(
            RESULT_FRAME_TIME_MS,
            frameTimeMs
        )

        result.putExtra(
            RESULT_STUTTER_RATE,
            stutterRate
        )

        result.putExtra(
            RESULT_VIDEO_WIDTH,
            videoWidth
        )

        result.putExtra(
            RESULT_VIDEO_HEIGHT,
            videoHeight
        )

        result.putExtra(
            RESULT_VIDEO_FPS,
            videoFps
        )

        result.putExtra(
            RESULT_PROCESSING_AVERAGE_MS,
            processingAverageMs
        )

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
            Intent()

        result.putExtra(
            RESULT_ERROR,
            message
        )

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
