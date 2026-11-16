package app.goalschallenge.goals_challenge

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.io.File

/** Supplies the rotating photo pages of [PartnerWidgetProvider]. */
class PartnerWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        PhotoFactory(applicationContext)
}

private class PhotoFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    private var photos: List<WidgetPhoto> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        photos = PartnerWidgetSnapshot.load(context)?.photos
            ?.filter { File(it.path).isFile }
            ?: emptyList()
    }

    override fun onDestroy() {
        photos = emptyList()
    }

    override fun getCount(): Int = photos.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.partner_widget_item)
        val photo = photos.getOrNull(position) ?: return views
        decodeSampled(photo.path, MAX_SIDE_PX)?.let {
            views.setImageViewBitmap(R.id.item_photo, it)
        }
        views.setTextViewText(R.id.item_caption, photo.caption)
        views.setOnClickFillInIntent(R.id.item_root, Intent())
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long =
        photos.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true

    /**
     * Decodes a JPEG scaled down by a power of two so the long side stays
     * around [maxSide]: widget bitmaps travel between processes and must
     * stay small.
     */
    private fun decodeSampled(path: String, maxSide: Int): Bitmap? = try {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) {
            sample *= 2
        }
        BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.RGB_565
            },
        )
    } catch (e: Exception) {
        null
    }

    companion object {
        private const val MAX_SIDE_PX = 540
    }
}
