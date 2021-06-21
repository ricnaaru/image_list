package com.ric.image_list;

import android.net.Uri;
import android.util.Log;
import android.widget.ImageView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;

public class GlideAdapter implements ImageAdapter {
    @Override
    public void loadImage(ImageView target, Uri loadUrl) {
        RequestOptions options = new RequestOptions().centerCrop();
        Log.d("ricric", "loadImage " + loadUrl);
        Glide
                .with(target.getContext())
                .load(loadUrl)
                .apply(options)
                .into(target);
    }

    @Override
    public void loadDetailImage(ImageView target, Uri loadUrl) {
        RequestOptions options = new RequestOptions().centerInside();
        Glide
                .with(target.getContext())
                .load(loadUrl)
                .apply(options)
                .into(target);
    }
}
