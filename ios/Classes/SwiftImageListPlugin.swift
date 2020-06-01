import Flutter
import UIKit
import Photos

public class SwiftImageListPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let imageListViewFactory = ImageListViewFactory(with: registrar)
        registrar.register(imageListViewFactory, withId: "plugins.flutter.io/image_list")

        let channel = FlutterMethodChannel(name: "image_list", binaryMessenger: registrar.messenger())
        
        let instance = SwiftImageListPlugin.init()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "getAlbums":
            checkPermissionAndLoad(result:result)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getAlbums(result: @escaping FlutterResult) {

        let fetchOptions = PHFetchOptions()

        let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)

        let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        var arr = [Any]();
        let allAlbums: Array<PHFetchResult<PHAssetCollection>> = [smartAlbums, albums]

        for i in 0 ..< allAlbums.count {
            let resultx: PHFetchResult = allAlbums[i]

            resultx.enumerateObjects { (asset, index, stop) -> Void in
                let opts = PHFetchOptions()

                if #available(iOS 9.0, *) {
                    opts.fetchLimit = 1
                }

                var assetCount = asset.estimatedAssetCount
                if assetCount == NSNotFound {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                    assetCount = PHAsset.fetchAssets(in: asset, options: fetchOptions).count
                }

                if assetCount > 0 {
                    let item = ["name": asset.localizedTitle!, "identifier": asset.localIdentifier] as [String : Any]
                    arr.append(item)
                }
            }
        }

        result(arr)
    }
    
    private func checkPermissionAndLoad(result: @escaping FlutterResult) {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                print("success")
                if status == .authorized{
                    self.getAlbums(result: result)
                }
            })
        } else if photos == .authorized {
            self.getAlbums(result: result)
        }
    }
}
