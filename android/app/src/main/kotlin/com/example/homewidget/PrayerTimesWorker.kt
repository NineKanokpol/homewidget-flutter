package com.example.homewidget
import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.homewidget.glance.HomeWidgetGlanceAppWidget

class PrayerTimesWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val response = RetrofitInstance.api.getPrayerTimes(
                latitude = 22.385005100402285,
                longitude = 71.745261,
                timeZone = 7
            )

            val prefs = applicationContext.getSharedPreferences("prayer_prefs", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("fajrTime", response.time1)
                .putString("sunriseTime", response.time2)
                .putString("dhuhrTime", response.time3)
                .putString("asrTime", response.time4)
                .putString("maghribTime", response.time5)
                .putString("ishaTime", response.time6)
                .putString("dateString", response.date_string)
                .apply()

            // Update the widget
            HomeWidgetGlanceAppWidget().updateAll(applicationContext)

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure()
        }
    }
}