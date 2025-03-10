package com.example.homewidget.glance

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.RowScope
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.*
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.actionStartActivity
import com.example.homewidget.MainActivity
import com.example.homewidget.R

class HomeWidgetGlanceAppWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { GlanceContent(context, currentState()) }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        // Retrieve widget data (using default values if not set)
        val prefs = context.getSharedPreferences("prayer_prefs", Context.MODE_PRIVATE)

        val hijriDate = prefs.getString("dateString", "23 ชะอูบาน 1446") ?: "23 ชะอูบาน 1446"
        val fajrTime = prefs.getString("fajrTime", "05:30") ?: "05:30"
        val sunriseTime = prefs.getString("sunriseTime", "06:37") ?: "06:37"
        val dhuhrTime = prefs.getString("dhuhrTime", "12:36") ?: "12:36"
        val asrTime = prefs.getString("asrTime", "15:52") ?: "15:52"
        val maghribTime = prefs.getString("maghribTime", "19:32") ?: "19:32"
        val ishaTime = prefs.getString("ishaTime", "00:31") ?: "00:31"
        val countdownText = prefs.getString("countdown", "อีก 00:46:05 จะถึงเวลา Sunrise")
            ?: "อีก 00:46:05 จะถึงเวลา Sunrise"

        // Root container: vertical layout, black background, 8dp padding, clickable
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(R.drawable.rounded_widget_bg))
                .padding(8.dp)
                .clickable(onClick = actionStartActivity<MainActivity>(context))
        ) {
            // Top Row: Hijri date (left) and Location (right)
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Text(
                    text = hijriDate,
                    style = TextStyle(fontSize = 14.sp, color = ColorProvider(Color.White)),
                )
            }

            Spacer(modifier = GlanceModifier.height(4.dp))

            // Countdown text (green)
            Text(
                text = countdownText,
                style = TextStyle(fontSize = 14.sp, color = ColorProvider(Color(0xFF00FF00)))
            )

            Spacer(modifier = GlanceModifier.height(4.dp))

            // Divider line
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(ColorProvider(Color.DarkGray))
            ) { }

            Spacer(modifier = GlanceModifier.height(4.dp))

            // Row of 6 cells for prayer times
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Box(modifier = GlanceModifier.defaultWeight()) {
                    PrayerTimeCell("Fajr", fajrTime, R.drawable.sunny)
                }
                Box(modifier = GlanceModifier.defaultWeight()) {
                    PrayerTimeCell("Sunrise", sunriseTime, R.drawable.sunny)
                }
                Box(modifier = GlanceModifier.defaultWeight()) {
                    PrayerTimeCell("Dhuhr", dhuhrTime, R.drawable.sunny)
                }
                Box(modifier = GlanceModifier.defaultWeight()) {
                    PrayerTimeCell("Asr", asrTime, R.drawable.sunny)
                }
                Box(modifier = GlanceModifier.defaultWeight()) {
                    PrayerTimeCell("Maghrib", maghribTime, R.drawable.sunny)
                }
                Box(modifier = GlanceModifier.defaultWeight()) {
                    PrayerTimeCell("Isha", ishaTime, R.drawable.sunny)
                }
            }
        }
    }

    @Composable
    private fun PrayerTimeCell(prayerName: String, prayerTime: String, iconRes: Int) {
        Column(
            modifier = GlanceModifier
                .padding(horizontal = 4.dp) // Increase horizontal padding
                , // Expands to available space in Row
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Image(
                provider = ImageProvider(iconRes),
                contentDescription = prayerName,
                modifier = GlanceModifier
                    .width(28.dp)
                    .height(28.dp)
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = prayerName,
                style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.White))
            )
            Spacer(modifier = GlanceModifier.height(2.dp))
            Text(
                text = prayerTime,
                style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.White))
            )
        }
    }
}

class InteractiveAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters
    ) {
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context, Uri.parse("homeWidgetExample://titleClicked")
        )
        backgroundIntent.send()
    }
}