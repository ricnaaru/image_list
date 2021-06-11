package com.ric.image_list;

import android.net.Uri;

class VideoData extends MediaData {
    final long duration;

    public VideoData(Uri uri, String albumId, String assetId, long duration) {
        super(MediaType.VIDEO, uri, albumId,assetId);
        this.duration = duration;
    }
}