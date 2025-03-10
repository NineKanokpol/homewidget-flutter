package com.example.homewidget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import com.example.homewidget.MainActivity
import com.example.homewidget.R

class HomeWidgetExampleProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            // Inflate your widget layout (app_layout_4x2.xml)
            val views = RemoteViews(context.packageName, R.layout.app_layout_4x2).apply {
                // Update the top row texts: Hijri date and Location
                setTextViewText(
                    R.id.tvDateHijri,
                    widgetData.getString("hijriDate", "23 ชะอูบาน 1446")
                )
                setTextViewText(
                    R.id.tvLocation,
                    widgetData.getString("locationName", "กรุงเทพมหานคร")
                )

                // Update the countdown text (middle row)
                setTextViewText(
                    R.id.tvCountdown,
                    widgetData.getString("countdown", "อีก 00:46:05 จะถึงเวลา Sunrise")
                )

                // Update the prayer times for each cell.
                // Fajr:
                setTextViewText(
                    R.id.tvFajrTime,
                    widgetData.getString("fajrTime", "05:30")
                )
                // Sunrise:
                setTextViewText(
                    R.id.tvSunriseTime,
                    widgetData.getString("sunriseTime", "06:37")
                )
                // Dhuhr:
                setTextViewText(
                    R.id.tvDhuhrTime,
                    widgetData.getString("dhuhrTime", "12:36")
                )
                // Asr:
                setTextViewText(
                    R.id.tvAsrTime,
                    widgetData.getString("asrTime", "15:52")
                )
                // Maghrib:
                setTextViewText(
                    R.id.tvMaghribTime,
                    widgetData.getString("maghribTime", "19:32")
                )
                // Isha:
                setTextViewText(
                    R.id.tvIshaTime,
                    widgetData.getString("ishaTime", "00:31")
                )

                // (Optional) If you have any images to update dynamically, for example,
                // you could update an image by decoding a bitmap from a stored path.
                // String imagePath = widgetData.getString("dashIcon", null)
                // if (imagePath != null) {
                //     setImageViewBitmap(R.id.someImageView, BitmapFactory.decodeFile(imagePath))
                //     setViewVisibility(R.id.someImageView, View.VISIBLE)
                // } else {
                //     setViewVisibility(R.id.someImageView, View.GONE)
                // }

                // Set a pending intent on the entire widget so that clicking anywhere launches MainActivity.
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            }

            // Update the widget with the new RemoteViews
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}