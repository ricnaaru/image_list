package com.ric.image_list;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class ImageListFactory extends PlatformViewFactory {
    //    private final PluginRegistry.Registrar mPluginRegistrar;
//
//    ImageListFactory(PluginRegistry.Registrar registrar) {
//        super(StandardMessageCodec.INSTANCE);
//        mPluginRegistrar = registrar;
//    }
//
//    @Override
//    public PlatformView create(Context context, int id, Object args) {
//        return new ImageList(id, context, mPluginRegistrar, args);
//    }
    private final BinaryMessenger messenger;
    private final View containerView;

    ImageListFactory(@NonNull BinaryMessenger messenger, View containerView) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.containerView = containerView;
    }

    @NonNull
    @Override
    public PlatformView create(@NonNull Context context, int id, @Nullable Object args) {
        return new ImageList(id, context, messenger, args);
    }
}
