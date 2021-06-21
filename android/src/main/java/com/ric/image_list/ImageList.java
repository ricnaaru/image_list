package com.ric.image_list;

import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.loader.content.CursorLoader;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutionException;

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
    private String albumId;
    private Integer maxImage;
    private Integer maxSize;
    private String fileNamePrefix;
    private boolean disposed = false;
    private List<String> types = new ArrayList<>();
    private View view;
    private ArrayList<MediaData> selectedImages = new ArrayList<>();
    private int imageListColor;
    private int itemColor;

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
            String typesRaw = params.get("types") == null ? "VIDEO-IMAGE" : params.get("types").toString();
            types = Arrays.asList(typesRaw.split("-"));
            albumId = params.get("albumId").toString();
            maxImage = params.get("maxImage") == null ? null : Integer.valueOf(params.get("maxImage").toString());
            maxSize = params.get("maxSize") == null ? null : Integer.valueOf(params.get("maxSize").toString());
            fileNamePrefix = params.get("fileNamePrefix").toString();
            String imageListColorString = params.get("imageListColor").toString();
            imageListColor = Color.parseColor("#" + imageListColorString);
            String itemColorString = params.get("itemColor").toString();
            itemColor = Color.parseColor("#" + itemColorString);

            if (params.get("selections") != null) {
                List selections = (ArrayList) params.get("selections");

                for (int i = 0; i < selections.size(); i++) {
                    Map<String, Object> selection = (Map<String, Object>) selections.get(i);
                    String albumId = selection.get("albumId") == null ? "" : selection.get("albumId").toString();
                    String assetId = selection.get("assetId") == null ? "" : selection.get("assetId").toString();
                    String uri = selection.get("uri") == null ? "" : selection.get("uri").toString();
                    String type = selection.get("type") == null ? "" : selection.get("type").toString();
                    long duration = selection.get("duration") == null ? 0 : Long.valueOf(selection.get("duration").toString());
                    MediaData mediaData;

                    if (type.equals("IMAGE")) {
                        mediaData = new ImageData(Uri.parse(uri), albumId, assetId);
                    } else {
                        mediaData = new VideoData(Uri.parse(uri), albumId, assetId, duration);
                    }

                    selectedImages.add(mediaData);
                }
            }
        }

        recyclerView.setBackgroundColor(imageListColor);

        if (checkPermission()) {
            long bucketId = 0;

            try {
                bucketId = Long.parseLong(albumId);
            } catch (Exception ignored) {

            }

            new DisplayImage(context, this, bucketId, true, types).execute();
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

                    if (params.get("types") != null) {
                        String typesRaw = params.get("types").toString();
                        types = Arrays.asList(typesRaw.split("-"));
                    }
                }

                if (checkPermission()) {
                    long bucketId = 0;

                    try {
                        bucketId = Long.parseLong(albumId);
                    } catch (Exception ignored) {

                    }

                    this.setAdapter(new MediaData[]{});
                    try {
                        new DisplayImage(context, this, bucketId, true, types).execute().get();
                    } catch (ExecutionException e) {
                        e.printStackTrace();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }

                result.success(true);
                break;
            case "getSelectedMedia":
                List<Map<String, String>> imageIdList = new ArrayList<>();

                for (int i = 0; i < adapter.selectedImages.size(); i++) {
                    MediaData data = adapter.selectedImages.get(i);

                    //this will be implemented later
//                    String newPath = copyAndResizeFile(data.getAssetId());

                    Map<String, String> map = new HashMap<>();
                    map.put("type", data.getType().toString());
                    map.put("albumId", data.getAlbumId());
                    map.put("assetId", data.getAssetId());
                    map.put("uri", data.getUri().toString());

                    if (data instanceof VideoData) {
                        map.put("duration", String.valueOf(((VideoData) data).duration));
                    }


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

        Bitmap rawBitmap = BitmapFactory.decodeFile(srcUrl);
        ExifInterface exif = null;
        try {
            exif = new ExifInterface(srcUrl);
        } catch (IOException e) {
            e.printStackTrace();
        }
        int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_UNDEFINED);
        Bitmap bitmap = rotateBitmap(rawBitmap, orientation);
        if (maxSize != null) {
            double initialWidth = bitmap.getWidth();
            double initialHeight = bitmap.getHeight();
            int width = initialHeight < initialWidth ? maxSize : (int) (initialWidth / initialHeight * maxSize);
            int height = initialWidth <= initialHeight ? maxSize : (int) (initialHeight / initialWidth * maxSize);

            bitmap = Bitmap.createScaledBitmap(bitmap, width,
                    height, true);
        }

        String baseName = fileNamePrefix + "_" + dateFormat.format(currentTime);
        File destination = new File(folder.getAbsolutePath(), baseName + ".jpg");

        int counter = 0;

        while (destination.exists()) {
            counter++;
            destination = new File(folder.getAbsolutePath(), baseName + "_" + counter + ".jpg");
        }

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

    public static Bitmap rotateBitmap(Bitmap bitmap, int orientation) {
        Matrix matrix = new Matrix();
        switch (orientation) {
            case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
                matrix.setScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_ROTATE_180:
                matrix.setRotate(180);
                break;
            case ExifInterface.ORIENTATION_FLIP_VERTICAL:
                matrix.setRotate(180);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_TRANSPOSE:
                matrix.setRotate(90);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_ROTATE_90:
                matrix.setRotate(90);
                break;
            case ExifInterface.ORIENTATION_TRANSVERSE:
                matrix.setRotate(-90);
                matrix.postScale(-1, 1);
                break;
            case ExifInterface.ORIENTATION_ROTATE_270:
                matrix.setRotate(-90);
                break;
            default:
                return bitmap;
        }
        try {
            Bitmap bmRotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
            bitmap.recycle();
            return bmRotated;
        } catch (OutOfMemoryError e) {
            e.printStackTrace();
            return null;
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

    void setAdapter(MediaData[] result) {
        adapter = new ImageListAdapter(result, itemColor, selectedImages, maxImage, methodChannel);
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
                MediaData image = (MediaData) view.getTag();
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
                            long bucketId = 0;

                            try {
                                bucketId = Long.parseLong(albumId);
                            } catch (Exception ignored) {

                            }

                            new DisplayImage(context, ImageList.this, bucketId, true, types).execute();
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
                            long bucketId = 0;

                            try {
                                bucketId = Long.parseLong(albumId);
                            } catch (Exception ignored) {

                            }

                            new DisplayImage(context, ImageList.this, bucketId, true, types).execute();
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

class DisplayImage extends AsyncTask<Void, Void, MediaData[]> {
    private ImageList imageList;
    private Long bucketId;
    private Boolean exceptGif;
    private ContentResolver resolver;
    private List<String> types;
    private long first;

    DisplayImage(Context context, ImageList imageList, Long bucketId,
                 Boolean exceptGif, List<String> types) {
        this.imageList = imageList;
        this.bucketId = bucketId;
        this.exceptGif = exceptGif;
        this.resolver = context.getContentResolver();
        this.types = types;
        first = System.currentTimeMillis();
    }

    @Override
    protected MediaData[] doInBackground(Void... params) {
        return getAllMediaThumbnailsPath(bucketId, exceptGif);
    }

    @Override
    protected void onPostExecute(MediaData[] result) {
        super.onPostExecute(result);
        
        imageList.setAdapter(result);
    }


    @NonNull
    private MediaData[] getAllMediaThumbnailsPath(long id, Boolean exceptGif) {
        String selection = "( "
                + " ( " + MediaStore.Files.FileColumns.MEDIA_TYPE + "=" + MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                + " AND 1 = " + (types.contains("IMAGE") ? "1" : "0") + " ) "
                + " OR "
                + " ( " + MediaStore.Files.FileColumns.MEDIA_TYPE + "=" + MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                + " AND 1 = " + (types.contains("VIDEO") ? "1" : "0") + " ) ) AND " +
                MediaStore.Images.Media.BUCKET_ID + " = ?";
        String bucketId = String.valueOf(id);
        String sort = MediaStore.Files.FileColumns.DATE_ADDED + " DESC";
        String[] selectionArgs = {bucketId};

        Uri queryUri = MediaStore.Files.getContentUri("external");
        Cursor c;

        if (!bucketId.equals("0")) {
            c = resolver.query(queryUri, null, selection, selectionArgs, sort);
        } else {
            return new MediaData[0];
        }

        MediaData[] imageUris = new MediaData[c == null ? 0 : c.getCount()];

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
                        Uri path = Uri.withAppendedPath(queryUri, "" + imgId);
                        String mimeType = resolver.getType(path);
                        String assetId = c.getString(c.getColumnIndex(MediaStore.MediaColumns.DATA));
                        if (mimeType != null) {
                            if (mimeType.startsWith("image")) {
                                imageUris[++position] = new ImageData(path, bucketId, assetId);
                            } else if (mimeType.startsWith("video")) {
                                long duration = c.getLong(c.getColumnIndex(MediaStore.Video.VideoColumns.DURATION));
                                imageUris[++position] = new VideoData(path, bucketId, assetId, duration);
                            }
                        }
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