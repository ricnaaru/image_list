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
            getAlbums(call, result: result)
            break;
        case "checkPermission":
            checkPermission(result: result)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getAlbums(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        let types = (args?["types"] as? String) ?? "VIDEO-IMAGE"
        
        var imagePredicate: NSPredicate?
        var videoPredicate: NSPredicate?
        
        if types.contains("IMAGE") {
            imagePredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        }
        
        if types.contains("VIDEO") {
            videoPredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        }
        
        let finalPredicate = imagePredicate != nil && videoPredicate != nil ? NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.or, subpredicates: [imagePredicate!, videoPredicate!]) : imagePredicate != nil ? imagePredicate! :  videoPredicate != nil ? videoPredicate! : nil
        
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
                
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = finalPredicate
                let assetCount = PHAsset.fetchAssets(in: asset, options: fetchOptions).count
                
                if assetCount > 0 {
                    let item = ["name": asset.localizedTitle!, "identifier": asset.localIdentifier, "count": assetCount] as [String : Any]
                    arr.append(item)
                }
            }
        }
        
        result(arr)
    }
    
    private func checkPermission(result: @escaping FlutterResult) {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos != .authorized {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized {
                    result(true)
                } else {
                    result(false)
                }
            })
        } else if photos == .authorized {
            result(true)
        }
    }
}
