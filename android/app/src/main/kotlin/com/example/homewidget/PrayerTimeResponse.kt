package com.example.homewidget
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query

// Data class for API response
data class PrayerTimesResponse(
    val time1: String,
    val time2: String,
    val time3: String,
    val time4: String,
    val time5: String,
    val time6: String,
    val time7: String,
    val date_string: String
)

// Retrofit API Service
interface PrayerTimesApi {
    @GET("solahtimes/api/")
    suspend fun getPrayerTimes(
        @Query("json") json: String = "",
        @Query("lati") latitude: Double,
        @Query("longti") longitude: Double,
        @Query("time-z") timeZone: Int
    ): PrayerTimesResponse
}

// Retrofit Instance
object RetrofitInstance {
    val api: PrayerTimesApi by lazy {
        Retrofit.Builder()
            .baseUrl("https://whiteplus.whitechannel.tv/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(PrayerTimesApi::class.java)
    }
}