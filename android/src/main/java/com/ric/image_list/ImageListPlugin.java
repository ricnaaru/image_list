package com.ric.image_list;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Log;
import android.util.Pair;

import androidx.annotation.NonNull;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class ImageListPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private Context context;
    private Activity activity;

    @Override
    public void onMethodCall(MethodCall call, @NonNull final Result result) {
        if (call.method.equals("getAlbums")) {
            ArrayList<HashMap<String, Object>> finalResult = new ArrayList<>();

            if (call.arguments instanceof HashMap) {
                Map<String, Object> params = (Map<String, Object>) call.arguments;
                String typesRaw = params.get("types") == null ? "VIDEO-IMAGE" : params.get("types").toString();
                List<String> types = Arrays.asList(typesRaw.split("-"));
                HashMap<String, Pair<String, Integer>> albums = new HashMap<>();

                if (types.contains("IMAGE")) {
                    getImageAlbumNames(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, albums);
                    getImageAlbumNames(MediaStore.Images.Media.INTERNAL_CONTENT_URI, albums);
                }
                if (types.contains("VIDEO")) {
                    getVideoAlbumNames(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, albums);
                    getVideoAlbumNames(MediaStore.Video.Media.INTERNAL_CONTENT_URI, albums);
                }

                for (Map.Entry<String, Pair<String, Integer>> entry : albums.entrySet()) {
                    HashMap<String, Object> map = new HashMap<>();

                    map.put("name", entry.getKey());
                    map.put("identifier", entry.getValue().first);
                    map.put("count", entry.getValue().second);

                    finalResult.add(map);
                }
            }

            result.success(finalResult);
        } else if (call.method.equals("checkPermission")) {
            Dexter.withActivity(this.activity)
                    .withPermissions(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE)
                    .withListener(new MultiplePermissionsListener() {
                        @Override
                        public void onPermissionsChecked(MultiplePermissionsReport report) {
                            result.success(report.areAllPermissionsGranted());
                        }

                        @Override
                        public void onPermissionRationaleShouldBeShown(List<PermissionRequest> permissions, PermissionToken token) {
                            token.continuePermissionRequest();
                        }
                    })
                    .check();
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        binding
                .getPlatformViewRegistry()
                .registerViewFactory(
                        "plugins.flutter.io/image_list", new ImageListFactory(binding.getBinaryMessenger(), null));

        final MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "image_list");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        context = binding.getActivity();
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        context = null;
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        context = binding.getActivity();
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        context = null;
        activity = null;
    }

    private void getImageAlbumNames(Uri uri, HashMap<String, Pair<String, Integer>> albums) {
        String[] projection = {MediaStore.Images.Media.BUCKET_ID,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME};

        final String orderBy = MediaStore.Images.Media.BUCKET_DISPLAY_NAME;
        final Cursor cursor = context.getContentResolver().query(uri, projection, null, null, orderBy + " DESC");

        HashMap<String, Pair<String, Integer>> tempAlbums = new HashMap<>();

        if (cursor != null && (cursor.moveToFirst())) {
            int columnIdKey = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID);
            int columnNameKey = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);

            do {
                final String bucketId = cursor.getString(columnIdKey);
                final String bucketName = cursor.getString(columnNameKey);

                if (!tempAlbums.containsKey(bucketName)) {
                    final int count = getImageAlbumCount(uri, bucketId);
                    tempAlbums.put(bucketName, new Pair<>(bucketId, count));
                }
            } while (cursor.moveToNext());

            for (Map.Entry<String, Pair<String, Integer>> tempAlbum : tempAlbums.entrySet()) {
                String columnId = tempAlbum.getValue().first;
                String columnName = tempAlbum.getKey();
                Integer count = tempAlbum.getValue().second;

                if (albums.containsKey(columnName)) {
                    Pair<String, Integer> pair = albums.get(columnName);
                    Pair<String, Integer> newPair = new Pair<>(pair.first, pair.second + count);
                    albums.remove(columnName);
                    albums.put(columnName, newPair);
                } else {
                    albums.put(columnName, new Pair<>(columnId, count));
                }
            }

            cursor.close();
        }
    }

    private int getImageAlbumCount(@NonNull final Uri contentUri, @NonNull final String bucketId) {
        final Cursor cursor = context.getContentResolver().query(contentUri,
                null, MediaStore.Images.Media.BUCKET_ID + "=?", new String[] {bucketId}, null);

        return ((cursor == null) || (!cursor.moveToFirst())) ? 0 : cursor.getCount();
    }

    private int getVideoAlbumCount(@NonNull final Uri contentUri, @NonNull final String bucketId) {
        final Cursor cursor = context.getContentResolver().query(contentUri,
                null, MediaStore.Video.Media.BUCKET_ID + "=?", new String[] {bucketId}, null);

        return ((cursor == null) || (!cursor.moveToFirst())) ? 0 : cursor.getCount();
    }

    private void getVideoAlbumNames(Uri uri, HashMap<String, Pair<String, Integer>> albums) {
        String[] projection = {MediaStore.Video.Media.BUCKET_ID,
                MediaStore.Video.Media.BUCKET_DISPLAY_NAME};

        final String orderBy = MediaStore.Video.Media.DISPLAY_NAME;
        final Cursor cursor = context.getContentResolver().query(uri, projection, null, null, orderBy + " DESC");

        HashMap<String, Pair<String, Integer>> tempAlbums = new HashMap<>();

        if (cursor != null && (cursor.moveToFirst())) {
            int columnIdKey = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_ID);
            int columnNameKey = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME);

            do {
                final String bucketId = cursor.getString(columnIdKey);
                final String bucketName = cursor.getString(columnNameKey);

                if (!tempAlbums.containsKey(bucketName)) {
                    final int count = getVideoAlbumCount(uri, bucketId);
                    tempAlbums.put(bucketName, new Pair<>(bucketId, count));
                }
            } while (cursor.moveToNext());

            for (Map.Entry<String, Pair<String, Integer>> tempAlbum : tempAlbums.entrySet()) {
                String columnId = tempAlbum.getValue().first;
                String columnName = tempAlbum.getKey();
                Integer count = tempAlbum.getValue().second;

                if (albums.containsKey(columnName)) {
                    Pair<String, Integer> pair = albums.get(columnName);
                    Pair<String, Integer> newPair = new Pair<>(pair.first, pair.second + count);
                    albums.remove(columnName);
                    albums.put(columnName, newPair);
                } else {
                    albums.put(columnName, new Pair<>(columnId, count));
                }
            }

            cursor.close();
        }
    }
}
