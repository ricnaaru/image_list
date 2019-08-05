import Flutter
import UIKit

public class SwiftImageListPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let imageListViewFactory = ImageListViewFactory(with: registrar)
    registrar.register(imageListViewFactory, withId: "plugins.flutter.io/image_list")
  }
}
