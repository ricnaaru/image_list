package com.ric.image_list;

import android.net.Uri;

import androidx.annotation.Nullable;

class ImageData extends MediaData {
    public ImageData(Uri uri, String albumId, String assetId) {
        super(MediaType.IMAGE, uri, albumId,assetId);
    }
}