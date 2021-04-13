package com.ric.image_list;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URI;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.platform.PlatformView;

public class ImageList implements MethodChannel.MethodCallHandler,
        PlatformView, ActivityAware {
    private final MethodChannel methodChannel;
    private BinaryMessenger messenger;
    private final Context context;
    private RecyclerView recyclerView;
    private GridLayoutManager layoutManager;
    private Long bucketId = 0L;
    private String albumId;
    private Integer maxImage;
    private Integer maxSize;
    private String fileNamePrefix;
    private boolean disposed = false;
    private View view;
    private ArrayList<ImageData> selectedImages = new ArrayList<>();

    ImageList(
            int id,
            final Context context,
            BinaryMessenger messenger,
             Object args) {
        this.context = context;
        this.messenger = messenger;
        methodChannel =
                new MethodChannel(messenger, "plugins.flutter.io/image_list/" + id);
        methodChannel.setMethodCallHandler(this);
        view = LayoutInflater.from(context).inflate(R.layout.image_list, null);

        recyclerView = view.findViewById(R.id.rv_image_list);//new RecyclerView(context);
        layoutManager = new GridLayoutManager(context, 3, RecyclerView.VERTICAL, false);
        recyclerView.setLayoutManager(layoutManager);
        recyclerView.requestDisallowInterceptTouchEvent(true);

        if (args instanceof HashMap) {
            Map<String, Object> params = (Map<String, Object>) args;
            albumId = params.get("albumId").toString();
            maxImage = params.get("maxImage") == null ? null : Integer.valueOf(params.get("maxImage").toString());
            maxSize = params.get("maxSize") == null ? null : Integer.valueOf(params.get("maxSize").toString());
            fileNamePrefix = params.get("fileNamePrefix").toString();

            if (params.get("selections") != null) {
                List selections = (ArrayList) params.get("selections");

                for (int i = 0; i < selections.size(); i++) {
                    Map<String, Object> selection = (Map<String, Object>) selections.get(i);
                    String albumId = selection.get("albumId") == null ? "" : selection.get("albumId").toString();
                    String assetId = selection.get("assetId") == null ? "" : selection.get("assetId").toString();
                    String uri = selection.get("uri") == null ? "" : selection.get("uri").toString();

                    selectedImages.add(new ImageData(Uri.parse(uri), albumId, assetId));
                }
            }

            getAlbums();
        }

        if (checkPermission()) {
            new DisplayImage(context, this, bucketId, true).execute();
        }
    }

    private boolean checkPermission() {
        PermissionCheck permissionCheck = new PermissionCheck(context);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return permissionCheck.CheckStoragePermission();
        } else {
            return true;
        }
    }

    private void getAlbums() {
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
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {
        switch (methodCall.method) {
            case "waitForList":
                result.success(null);
                break;
            case "setMaxImage":
                if (methodCall.arguments instanceof HashMap) {
                    Map<String, Object> params = (Map<String, Object>) methodCall.arguments;
                    maxImage = params.get("maxImage") == null ? null : Integer.valueOf(params.get("maxImage").toString());
                    adapter.setMaxSelected(maxImage);
                    adapter.notifyDataSetChanged();
                }

                result.success(true);
                break;
            case "reloadAlbum":
                if (methodCall.arguments instanceof HashMap) {
                    Map<String, Object> params = (Map<String, Object>) methodCall.arguments;
                    albumId = params.get("albumId").toString();
                    getAlbums();
                }

                if (checkPermission()) {
                    new DisplayImage(context, this, bucketId, true).execute();
                }

                result.success(true);
                break;
            case "getSelectedImages":
                List<Map<String, String>> imageIdList = new ArrayList<>();

                for (int i = 0; i < adapter.selectedImages.size(); i++) {
                    ImageData data = adapter.selectedImages.get(i);

                    Log.d("ricric", "albumId => " + data.getAlbumId() + ", assetId => " + data.getAssetId() + ", uri => " + data.getUri().toString());

                    String newPath = copyAndResizeFile(data.getAssetId());

                    Map<String, String> map = new HashMap<>();
                    map.put("albumId", null);
                    map.put("assetId", newPath);
                    map.put("uri", data.getUri().toString());
                    imageIdList.add(map);
                }

                result.success(imageIdList);
                break;
        }
    }

    public String copyAndResizeFile(String srcUrl) {
        Date currentTime = Calendar.getInstance().getTime();
        DateFormat dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault());
        File folder = new File(Environment.getExternalStorageDirectory() + "/images");
        if (!folder.exists()) {
            folder.mkdirs();
        }

        Bitmap bitmap = BitmapFactory.decodeFile(srcUrl);
        if (maxSize != null) {
            double initialWidth = bitmap.getWidth();
            double initialHeight = bitmap.getHeight();
            int width = initialHeight < initialWidth ? maxSize : (int) (initialWidth / initialHeight * maxSize);
            int height = initialWidth <= initialHeight ? maxSize : (int) (initialHeight / initialWidth * maxSize);

            bitmap = Bitmap.createScaledBitmap(bitmap, width,
                    height, true);
        }

        File destination = new File(folder.getAbsolutePath(), fileNamePrefix + "_" + dateFormat.format(currentTime) + ".jpg");

        getSavePhotoLocal(bitmap, destination);

        return destination.getAbsolutePath();
    }

    private void getSavePhotoLocal(Bitmap bitmap, File destination) {
        try {
            OutputStream output;
            try {
                output = new FileOutputStream(destination);
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, output);
                output.flush();
                output.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        } catch (Exception e) {
            e.printStackTrace();
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
        adapter = new ImageListAdapter(result, selectedImages, maxImage, methodChannel);
        adapter.setActionListener(new ImageListAdapter.OnPhotoActionListener() {
            @Override
            public void onDeselect() {
                refreshThumb();
            }
        });

        recyclerView.setAdapter(adapter);
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
                ImageData image = (ImageData) view.getTag();
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

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        binding.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
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

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        binding.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
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

    @Override
    public void onDetachedFromActivity() {

    }
}

class ImageData {
    private Uri uri;
    private String albumId;
    private String assetId;

    public ImageData(Uri uri, String albumId, String assetId) {
        this.uri = uri;
        this.albumId = albumId;
        this.assetId = assetId;
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
        if (!(obj instanceof ImageData)) return false;

        ImageData other = (ImageData) obj;
        return other.getAlbumId().equals(this.albumId) &&
                other.getAssetId().equals(this.assetId) &&
                other.getUri().equals(this.uri);
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
                        imageUris[++position] = new ImageData(path, bucketId, assetId);
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