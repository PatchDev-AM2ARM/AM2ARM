package com.community.am2r.patcher;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.view.View;

/** The original title starfield pans down to reveal the planet. */
final class TitleBackdrop extends View {
    private final Bitmap artwork;
    private final Paint paint = new Paint();
    private float pan = 1, fade = 1;

    TitleBackdrop(Context context) {
        super(context);
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inScaled = false;
        artwork = BitmapFactory.decodeResource(getResources(), R.drawable.title_background, options);
        paint.setFilterBitmap(false);
        setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);
    }

    void setIntroProgress(float progress, float alpha) {
        pan = progress;
        fade = alpha;
        invalidate();
    }

    @Override protected void onDraw(Canvas canvas) {
        int width = getWidth(), height = getHeight();
        float scale = height/240f;
        int drawnWidth = Math.round(artwork.getWidth()*scale);
        int drawnHeight = Math.round(artwork.getHeight()*scale);
        int x = (width-drawnWidth)/2, y = Math.round((height-drawnHeight)*pan);
        canvas.drawColor(0xff000000);
        paint.setAlpha(Math.round(255*fade*.5f));
        canvas.drawBitmap(artwork, null, new Rect(x, y, x+drawnWidth, y+drawnHeight), paint);
    }
}
