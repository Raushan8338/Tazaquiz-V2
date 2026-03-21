package com.tazaquiz.quiz

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val CHANNEL_GENERAL   = "tazaquiz_general"
        private const val CHANNEL_QUIZ_LIVE = "tazaquiz_quiz_live"
        private const val CHANNEL_PROMO     = "tazaquiz_promo"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        if (remoteMessage.data.isNotEmpty()) {
            val data             = remoteMessage.data
            val title            = data["title"]             ?: "TazaQuiz 🎯"
            val body             = data["body"]              ?: "You have a new notification"
            val quizId           = data["quiz_id"]           ?: ""
            val imageUrl         = data["image"]
            val type             = data["type"]              ?: "home"
            val notificationType = data["notification_type"] ?: "only_content"
            val subText          = data["sub_text"]          ?: ""
            val ctaLabel         = data["cta_label"]         ?: "Open"
            val meta             = data["meta"]              ?: ""
            val jsonString       = JSONObject(data as Map<*, *>).toString()

            showNotification(
                title, body, quizId, imageUrl,
                type, notificationType, subText, ctaLabel, meta, jsonString
            )
        }
    }

    private fun showNotification(
        title: String,
        message: String,
        quizId: String,
        imageUrl: String?,
        type: String,
        notificationType: String,
        subText: String,
        ctaLabel: String,
        meta: String,
        allData: String
    ) {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        createChannels(manager)

        val channelId = when (type) {
            "quiz", "start_quiz" -> CHANNEL_QUIZ_LIVE
            "promo"              -> CHANNEL_PROMO
            else                 -> CHANNEL_GENERAL
        }

        val page = when (type) {
            "quiz", "start_quiz" -> "quiz"
            "result"             -> "result"
            "course"             -> "course"
            "web"                -> "web"
            else                 -> "home"
        }

        // ── Main tap intent ───────────────────────────────────────────────
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("from_notification", true)
            putExtra("page", page)
            putExtra("type", type)
            putExtra("title", title)
            putExtra("body", message)
            putExtra("quiz_id", quizId)
            putExtra("image", imageUrl ?: "")
            putExtra("notification_type", notificationType)
            putExtra("meta", meta)
            putExtra("data", allData)
        }

        val mainPending = PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── CTA button intent ─────────────────────────────────────────────
        val ctaIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("from_notification", true)
            putExtra("page", page)
            putExtra("type", type)
            putExtra("title", title)
            putExtra("body", message)
            putExtra("quiz_id", quizId)
            putExtra("image", imageUrl ?: "")
            putExtra("notification_type", notificationType)
            putExtra("meta", meta)
            putExtra("action", "start_quiz")
            putExtra("data", allData)
        }

        val ctaPending = PendingIntent.getActivity(
            this,
            (System.currentTimeMillis() + 1).toInt(),
            ctaIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── Image download ────────────────────────────────────────────────
        val bitmap: Bitmap? = if (!imageUrl.isNullOrEmpty()) getBitmapFromURL(imageUrl) else null

        // ── Build notification ────────────────────────────────────────────
        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setContentIntent(mainPending)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(getAccentColor(type))
            .setColorized(false)
            .setLights(getAccentColor(type), 500, 500)
            .setVibrate(longArrayOf(0, 200, 100, 200))

        if (subText.isNotEmpty()) builder.setSubText(subText)
        if (bitmap != null) builder.setLargeIcon(bitmap)

        // ── Notification style ────────────────────────────────────────────
        when (notificationType) {
            "only_banner" -> {
                if (bitmap != null) {
                    builder.setStyle(
                        NotificationCompat.BigPictureStyle()
                            .bigPicture(bitmap)
                            .bigLargeIcon(null as Bitmap?)
                    )
                }
            }
            "banner_with_content" -> {
                if (bitmap != null) {
                    builder.setStyle(
                        NotificationCompat.BigPictureStyle()
                            .bigPicture(bitmap)
                            .bigLargeIcon(null as Bitmap?)
                            .setBigContentTitle(title)
                            .setSummaryText(message)
                    )
                } else {
                    builder.setStyle(
                        NotificationCompat.BigTextStyle()
                            .bigText(message)
                            .setBigContentTitle(title)
                    )
                }
            }
            "only_content" -> {
                builder.setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText(message)
                        .setBigContentTitle(title)
                        .setSummaryText(getChannelLabel(type))
                )
            }
            "inbox" -> {
                val inboxStyle = NotificationCompat.InboxStyle()
                    .setBigContentTitle(title)
                    .setSummaryText(getChannelLabel(type))
                message.split("\n").take(5).forEach { inboxStyle.addLine(it) }
                builder.setStyle(inboxStyle)
            }
        }

        // ── Action Buttons ────────────────────────────────────────────────
        when (type) {
            "quiz", "start_quiz" -> {
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "🚀  ${ctaLabel.ifEmpty { "Start Quiz Now" }}", ctaPending
                    ).build()
                )
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "🔔  Remind Me Later", mainPending
                    ).build()
                )
            }
            "result" -> {
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "📊  View My Results", mainPending
                    ).build()
                )
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "🏠  Go to Home", mainPending
                    ).build()
                )
            }
            "course" -> {
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "📚  Explore Course", mainPending
                    ).build()
                )
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "⭐  Save for Later", mainPending
                    ).build()
                )
            }
            "promo" -> {
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "🎁  Claim Offer", ctaPending
                    ).build()
                )
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "❌  Not Interested", mainPending
                    ).build()
                )
            }
            else -> {
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0, "👀  Open Now", mainPending
                    ).build()
                )
            }
        }

        android.util.Log.d("FCM", "🔔 Notification fired | type=$type | page=$page | title=$title")
        manager.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    // ── Channel setup ─────────────────────────────────────────────────────
    private fun createChannels(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        listOf(
            Triple(CHANNEL_GENERAL,   "General Notifications", NotificationManager.IMPORTANCE_DEFAULT),
            Triple(CHANNEL_QUIZ_LIVE, "🔴 Live Quiz Alerts",   NotificationManager.IMPORTANCE_HIGH),
            Triple(CHANNEL_PROMO,     "Offers & Promotions",   NotificationManager.IMPORTANCE_LOW),
        ).forEach { (id, name, importance) ->
            if (manager.getNotificationChannel(id) == null) {
                val ch = NotificationChannel(id, name, importance).apply {
                    enableLights(true)
                    lightColor       = Color.parseColor("#0D6E6E")
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 200, 100, 200)
                    setShowBadge(true)
                }
                manager.createNotificationChannel(ch)
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    private fun getAccentColor(type: String): Int = when (type) {
        "quiz", "start_quiz" -> Color.parseColor("#E53935")
        "result"             -> Color.parseColor("#0D6E6E")
        "course"             -> Color.parseColor("#F59E0B")
        "promo"              -> Color.parseColor("#7C3AED")
        else                 -> Color.parseColor("#0D6E6E")
    }

    private fun getChannelLabel(type: String): String = when (type) {
        "quiz", "start_quiz" -> "⚡ Live Quiz Alert"
        "result"             -> "📊 Your Results"
        "course"             -> "📚 New Course"
        "promo"              -> "🎁 Special Offer"
        else                 -> "TazaQuiz"
    }

    private fun getBitmapFromURL(src: String): Bitmap? = try {
        val connection = (URL(src).openConnection() as HttpURLConnection).apply {
            doInput        = true
            connectTimeout = 5000
            readTimeout    = 5000
            connect()
        }
        BitmapFactory.decodeStream(connection.inputStream)
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}