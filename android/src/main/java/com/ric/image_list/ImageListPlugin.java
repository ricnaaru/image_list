package com.ric.image_list;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** ImageListPlugin */
public class ImageListPlugin implements MethodCallHandler {
  private Context context;

  public static void registerWith(Registrar registrar) {
    if (registrar.activity() == null) {
      // When a background flutter view tries to register the plugin, the registrar has no activity.
      // We stop the registration process as this plugin is foreground only.
      return;
    }

    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "plugins.flutter.io/image_list", new ImageListFactory(registrar));
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "image_list");
    channel.setMethodCallHandler(new ImageListPlugin(registrar));
  }

  private ImageListPlugin(Registrar registrar) {
    this.context = registrar.context();
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
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
    }
  }
}
