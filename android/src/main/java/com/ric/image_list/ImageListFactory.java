package com.ric.image_list;

import android.content.Context;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class ImageListFactory extends PlatformViewFactory {
    private final PluginRegistry.Registrar mPluginRegistrar;

    ImageListFactory(PluginRegistry.Registrar registrar) {
        super(StandardMessageCodec.INSTANCE);
        mPluginRegistrar = registrar;
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {
        return new ImageList(id, context, mPluginRegistrar, args);
    }
}
