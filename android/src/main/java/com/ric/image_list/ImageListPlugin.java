package com.ric.image_list;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

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
            Uri uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

            String[] projection = {"COUNT(*) as count",
                    MediaStore.Images.Media.BUCKET_ID,
                    MediaStore.Images.Media.BUCKET_DISPLAY_NAME};

            final String orderBy = MediaStore.Images.Media.DISPLAY_NAME;
            Cursor cursor = context.getContentResolver().query(uri, projection, "1) GROUP BY (" + MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME, null, orderBy + " DESC");

            ArrayList<HashMap<String, Object>> finalResult = new ArrayList<>();

            if (cursor != null) {
                int columnId = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_ID);
                int columnName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);


                while (cursor.moveToNext()) {
                    HashMap<String, Object> albumItem = new HashMap<>();

                    albumItem.put("name", cursor.getString(columnName));
                    albumItem.put("identifier", cursor.getString(columnId));

                    finalResult.add(albumItem);
                }

                cursor.close();
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
}
