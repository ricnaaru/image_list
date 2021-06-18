package com.ric.image_list;

import android.net.Uri;
import android.util.Log;

import androidx.annotation.Nullable;

enum MediaType {
    VIDEO,
    IMAGE
}

class MediaData {
    private final MediaType type;
    private final Uri uri;
    private final String albumId;
    private final String assetId;

    public MediaData(MediaType type, Uri uri, String albumId, String assetId) {
        this.type = type;
        this.uri = uri;
        this.albumId = albumId;
        this.assetId = assetId;
    }

    public MediaType getType() {
        return type;
    }

    public Uri getUri() {
        return uri;
    }

    public String getAssetId() {
        return assetId;
    }

    public String getAlbumId() {
        return albumId;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
        if (!(obj instanceof MediaData)) return false;

        MediaData other = (MediaData) obj;
        return other.getAlbumId().equals(this.albumId) &&
                other.getAssetId().equals(this.assetId) &&
                other.getUri().equals(this.uri);
    }
}