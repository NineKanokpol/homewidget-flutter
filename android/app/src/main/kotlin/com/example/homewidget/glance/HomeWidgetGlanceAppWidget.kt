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
import androidx.glance.appwidget.updateAll
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
        val data = currentState.preferences
        val timerValue = currentState.preferences.getString("timer_value", "")

        val titleDate = data.getString("titleDate", "") ?: ""
        val fajrTime = data.getString("fajrTime", "") ?: ""
        val sunriseTime = data.getString("sunriseTime", "") ?: ""
        val dhuhrTime = data.getString("dhuhrTime", "") ?: ""
        val asrTime = data.getString("asrTime", "") ?: ""
        val maghribTime = data.getString("maghribTime", "") ?: ""
        val ishaTime = data.getString("ishaTime", "") ?: ""
        val location = data.getString("location", "") ?: ""
        val countdownText = data.getString("countdown", "") ?: ""

        // Root container: vertical layout, black background, 8dp padding, clickable
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(ImageProvider(R.drawable.rounded_widget_bg))
                .padding(8.dp)
        ) {
            // Top Row: Hijri date (left) and Location (right)
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically      // จัดให้ไอคอน Divider กึ่งกลาง
            ) {
                Image(
                    provider = ImageProvider(R.drawable.logo),
                    contentDescription = "Logo",
                    modifier = GlanceModifier.size(16.dp)
                )
                Spacer(GlanceModifier.width(8.dp))
                Text(
                    text = titleDate,
                    modifier = GlanceModifier.defaultWeight(),
                    style = TextStyle(fontSize = 18.sp, color = ColorProvider(Color.White))
                )
                Row(
                    modifier = GlanceModifier.wrapContentSize(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = location,
                        style = TextStyle(fontSize = 14.sp, color = ColorProvider(Color.White))
                    )
                    Spacer(GlanceModifier.width(4.dp))
                    Image(
                        provider = ImageProvider(R.drawable.refresh),  // ใส่ไอคอนรีเฟรชของคุณ
                        contentDescription = "Refresh",
                        modifier = GlanceModifier
                            .size(16.dp)
                            .clickable(onClick = actionRunCallback<RefreshAction>())
                    )
                }
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Countdown text (green)
//            Text(
//                text = "$timerValue",
//                style = TextStyle(fontSize = 16.sp, color = ColorProvider(Color(0xFF00FF00)))
//            )
//
//            Spacer(modifier = GlanceModifier.height(4.dp))

            // Divider line
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(2.dp)
                    .background(
                        ColorProvider(
                            Color(0xFF748825)
                        )
                    )
            ) { }

            Spacer(modifier = GlanceModifier.height(20.dp))

            // Row of 6 cells for prayer times
            //ศุบฮิ , ชุรูก  , ซุฮฺริ , อัศริ , มัฆริบ , อิชาอฺ
            val prayers = listOf(
                Triple("ศุบฮิ", fajrTime, R.drawable.sunny_up),
                Triple("ชุรูก", sunriseTime, R.drawable.sunny_up2),
                Triple("ซุฮฺริ", dhuhrTime, R.drawable.sunny_full),
                Triple("อัศริ", asrTime, R.drawable.sunny_clound),
                Triple("มัฆริบ", maghribTime, R.drawable.sunny_down),
                Triple("อิชาอฺ", ishaTime, R.drawable.moon)
            )

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                prayers.forEachIndexed { idx, (name, time, iconRes) ->
                    Box(
                        modifier = GlanceModifier.defaultWeight(),
                        contentAlignment = Alignment.Center
                    ) {
                        PrayerTimeCell(name, time, iconRes)
                    }
                }
            }
        }
    }

    @Composable
    private fun VerticalDivider() {
        Box(
            modifier = GlanceModifier
                .height(50.dp)
                .width(1.dp)
                .background(ColorProvider(Color.DarkGray))
        ) {}
    }

    @Composable
    private fun PrayerTimeCell(prayerName: String, prayerTime: String, iconRes: Int) {
        Column(
            modifier = GlanceModifier
                .wrapContentSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Image(
                provider = ImageProvider(iconRes),
                contentDescription = prayerName,
                modifier = GlanceModifier.size(24.dp)
            )
            Spacer(GlanceModifier.height(2.dp))
            Text(
                text = prayerName,
                style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color.White))
            )
            Spacer(GlanceModifier.height(2.dp))
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

class RefreshAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: androidx.glance.action.ActionParameters
    ) {
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("homeWidgetExample://actionRefresh")
        )
        backgroundIntent.send()

        HomeWidgetGlanceAppWidget().updateAll(context)
    }
}