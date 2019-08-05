package com.ric.image_list;

import android.net.Uri;
import android.widget.ImageView;

public interface ImageAdapter {
    void loadImage(ImageView target, Uri loadUrl);
    void loadDetailImage(ImageView target, Uri loadUrl);
}
