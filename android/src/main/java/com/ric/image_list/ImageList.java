package com.ric.image_list;

import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;

public class ImageList implements MethodChannel.MethodCallHandler,
        PlatformView {
    private final MethodChannel methodChannel;
    private PluginRegistry.Registrar registrar;
    private final Context context;
    private RecyclerView recyclerView;
    private GridLayoutManager layoutManager;
    private Long bucketId = 0L;
    private String albumId;
    private Integer maxImage;
    private boolean disposed = false;
    private View view;

    ImageList(
            int id,
            final Context context,
            PluginRegistry.Registrar registrar, Object args) {
        this.context = context;
        this.registrar = registrar;
        methodChannel =
                new MethodChannel(registrar.messenger(), "plugins.flutter.io/image_list/" + id);
        methodChannel.setMethodCallHandler(this);
        view = registrar.activity().getLayoutInflater().inflate(R.layout.image_list, null);

        recyclerView = view.findViewById(R.id.rv_image_list);//new RecyclerView(context);
        layoutManager = new GridLayoutManager(registrar.activity(), 3, RecyclerView.VERTICAL, false);
        recyclerView.setLayoutManager(layoutManager);
        recyclerView.requestDisallowInterceptTouchEvent(true);

        if (args instanceof HashMap) {
            Map<String, Object> params = (Map<String, Object>) args;
            albumId = params.get("albumId").toString();
            maxImage = params.get("maxImage") == null ? null : Integer.valueOf(params.get("maxImage").toString());
            getAlbums();
        }

        if (checkPermission()) {
            new DisplayImage(context, this, bucketId, true).execute();
        }

        registrar.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
                if (requestCode == 28) {
                    if (grantResults.length > 0) {
                        if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                            // permission was granted, yay!
                            getAlbums();
                            new DisplayImage(context, ImageList.this, bucketId, true).execute();
                        } else {
                            new PermissionCheck(context).showPermissionDialog();
                        }
                    }
                }
                return false;
            }
        });
    }

    private boolean checkPermission() {
        PermissionCheck permissionCheck = new PermissionCheck(registrar.activity());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (permissionCheck.CheckStoragePermission()) {
                return true;
            }
        } else {
            return true;
        }

        return false;
    }

    private void getAlbums() {
        Log.d("Tag", "getAlbums => " + albumId);
        Uri uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

        String[] projection = {MediaStore.Images.Media.BUCKET_ID, MediaStore.Images.Media.BUCKET_DISPLAY_NAME};
        String selection = MediaStore.Images.Media.BUCKET_ID + " = ?";
        String[] selectionArgs = {albumId};
        String sort = MediaStore.Images.Media.BUCKET_ID + " DESC";
        Cursor cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, sort);

        if (cursor != null) {
            int columnId = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID);

            while (cursor.moveToNext()) {
                bucketId = Long.valueOf(cursor.getString(columnId));
            }

            cursor.close();
        }
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("waitForList")) {
            result.success(null);
        } else if (methodCall.method.equals("reloadAlbum")) {
            if (methodCall.arguments instanceof HashMap) {
                Map<String, Object> params = (Map<String, Object>) methodCall.arguments;
                albumId = params.get("albumId").toString();
                getAlbums();
            }

            if (checkPermission()) {
                new DisplayImage(context, this, bucketId, true).execute();
            }

            result.success(true);
        } else if (methodCall.method.equals("getSelectedImages")) {
            List<String> imageIdList = new ArrayList<>();

            for (int i = 0; i < adapter.selectedImages.size(); i++) {
                ImageData data = adapter.selectedImages.get(i);

                imageIdList.add(data.getAssetId());
            }

            result.success(imageIdList);
        }
    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        if (disposed) {
            return;
        }
        disposed = true;
        methodChannel.setMethodCallHandler(null);
    }

    private ImageListAdapter adapter;

    void setAdapter(ImageData[] result) {
        adapter = new ImageListAdapter(result, maxImage, methodChannel);
        adapter.setActionListener(new ImageListAdapter.OnPhotoActionListener() {
            @Override
            public void onDeselect() {
                refreshThumb();
            }
        });

        recyclerView.setAdapter(adapter);
        recyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                Log.d("tag", "onscroll => " + dx + ", " + dy);
            }
        });
    }

    private void refreshThumb() {
        int firstVisible = layoutManager.findFirstVisibleItemPosition();
        int lastVisible = layoutManager.findLastVisibleItemPosition();
        for (int i = firstVisible; i <= lastVisible; i++) {
            View view = layoutManager.findViewByPosition(i);
            if (view instanceof SquareFrameLayout) {
                SquareFrameLayout item = (SquareFrameLayout) view;
                RadioWithTextButton btnThumbCount = view.findViewById(R.id.btn_thumb_count);
                ImageView imgThumbImage = view.findViewById(R.id.img_thumb_image);
                View overlay = view.findViewById(R.id.overlay);
                Uri image = (Uri) view.getTag();
                if (image != null) {
                    int index = adapter.selectedImages.indexOf(image);
                    if (index != -1) {
                        adapter.updateRadioButton(imgThumbImage, overlay,
                                btnThumbCount,
                                String.valueOf(index + 1),
                                true);
                    } else {
                        adapter.updateRadioButton(imgThumbImage, overlay,
                                btnThumbCount,
                                "",
                                false);
                    }
                }

            }
        }
    }
}

class ImageData {
    private Uri uri;
    private String assetId;

    public ImageData(Uri uri, String assetId) {
        this.uri = uri;
        this.assetId = assetId;
    }

    public Uri getUri() {
        return uri;
    }

    public String getAssetId() {
        return assetId;
    }
}

class DisplayImage extends AsyncTask<Void, Void, ImageData[]> {
    private ImageList imageList;
    private Long bucketId;
    private Boolean exceptGif;
    private ContentResolver resolver;

    DisplayImage(Context context, ImageList imageList, Long bucketId,
                 Boolean exceptGif) {
        this.imageList = imageList;
        this.bucketId = bucketId;
        this.exceptGif = exceptGif;
        this.resolver = context.getContentResolver();
    }

    @Override
    protected ImageData[] doInBackground(Void... params) {
        return getAllMediaThumbnailsPath(bucketId, exceptGif);
    }

    @Override
    protected void onPostExecute(ImageData[] result) {
        super.onPostExecute(result);
        imageList.setAdapter(result);
    }


    @NonNull
    private ImageData[] getAllMediaThumbnailsPath(long id,
                                            Boolean exceptGif) {
        String selection = MediaStore.Images.Media.BUCKET_ID + " = ?";
        String bucketId = String.valueOf(id);
        String sort = MediaStore.Images.Media._ID + " DESC";
        String[] selectionArgs = {bucketId};

        Uri images = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        Cursor c;

        if (!bucketId.equals("0")) {
            c = resolver.query(images, null, selection, selectionArgs, sort);
        } else {
            c = resolver.query(images, null, null, null, sort);
        }

        ImageData[] imageUris = new ImageData[c == null ? 0 : c.getCount()];

        if (c != null) {
            try {
                if (c.moveToFirst()) {
                    int position = -1;
                    RegexUtil regexUtil = new RegexUtil();
                    do {
                        if (exceptGif &&
                                regexUtil.checkGif(c.getString(c.getColumnIndex(MediaStore.Images.Media.DATA))))
                            continue;
                        int imgId = c.getInt(c.getColumnIndex(MediaStore.MediaColumns._ID));
                        Uri path = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + imgId);
                        String assetId = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DATA));
                        imageUris[++position] = new ImageData(path, assetId);
                    } while (c.moveToNext());
                }
                c.close();
            } catch (Exception e) {
                if (!c.isClosed()) c.close();
            }
        }

        return imageUris;
    }
}