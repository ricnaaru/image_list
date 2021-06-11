package com.ric.image_list;

import android.net.Uri;

class VideoData extends MediaData {
    public VideoData(Uri uri, String albumId, String assetId) {
        super(MediaType.VIDEO, uri, albumId,assetId);
    }
}