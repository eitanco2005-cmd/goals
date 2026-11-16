package app.goalschallenge.goals_challenge

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/** One photo of the partner, stored on the device by the Flutter app. */
data class WidgetPhoto(val id: String, val path: String, val caption: String)

/**
 * What the widget shows. Written as JSON by the Flutter side
 * (lib/features/widget/widget_snapshot.dart); all texts are already
 * localized there.
 */
data class PartnerWidgetSnapshot(
    val title: String,
    val status: String,
    val emptyText: String,
    val rtl: Boolean,
    val photos: List<WidgetPhoto>,
    val updatedAt: Long,
) {
    companion object {
        /** SharedPreferences key; must match `widgetSnapshotKey` in Dart. */
        const val KEY = "partner_snapshot"

        fun load(context: Context): PartnerWidgetSnapshot? =
            parse(HomeWidgetPlugin.getData(context).getString(KEY, null))

        fun parse(json: String?): PartnerWidgetSnapshot? {
            if (json.isNullOrEmpty()) return null
            return try {
                val o = JSONObject(json)
                val arr = o.optJSONArray("photos")
                val photos = buildList {
                    if (arr != null) {
                        for (i in 0 until arr.length()) {
                            val p = arr.getJSONObject(i)
                            add(
                                WidgetPhoto(
                                    id = p.optString("id"),
                                    path = p.optString("path"),
                                    caption = p.optString("caption"),
                                )
                            )
                        }
                    }
                }
                PartnerWidgetSnapshot(
                    title = o.optString("title"),
                    status = o.optString("status"),
                    emptyText = o.optString("emptyText"),
                    rtl = o.optBoolean("rtl"),
                    photos = photos,
                    updatedAt = o.optLong("updatedAt"),
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}
