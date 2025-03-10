package com.example.homewidget

import android.os.Bundle
import androidx.work.*
import io.flutter.embedding.android.FlutterActivity
import com.example.homewidget.PrayerTimesWorker
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        schedulePrayerTimesUpdate()
    }

    private fun schedulePrayerTimesUpdate() {
        val workRequest = PeriodicWorkRequestBuilder<PrayerTimesWorker>(6, TimeUnit.HOURS)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "prayer_times_update",
            ExistingPeriodicWorkPolicy.REPLACE,
            workRequest
        )
    }
}
