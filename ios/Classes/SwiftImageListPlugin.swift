import Flutter
import UIKit
import Photos
import AVFoundation

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
        case "getThumbnail":
            getThumbnail(call, result: result)
            break;
        case "getAlbumThumbnail":
            getAlbumThumbnail(call, result: result)
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
        
        var finalPredicate: NSPredicate?
            
        if (imagePredicate != nil && videoPredicate != nil) {
            finalPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.or, subpredicates: [imagePredicate!, videoPredicate!])
        } else {
            if imagePredicate != nil {
                finalPredicate = imagePredicate!
            } else if videoPredicate != nil {
                finalPredicate = videoPredicate!
            } else {
                finalPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [NSPredicate(format: "mediaType != %d", PHAssetMediaType.video.rawValue), NSPredicate(format: "mediaType != %d", PHAssetMediaType.image.rawValue)])
            }
        }
        
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
                fetchOptions.predicate = finalPredicate!
                let assetCount = PHAsset.fetchAssets(in: asset, options: fetchOptions).count
                
                if assetCount > 0 {
                    let item = ["name": asset.localizedTitle!, "identifier": asset.localIdentifier, "count": assetCount] as [String : Any]
                    arr.append(item)
                }
            }
        }
        
        result(arr)
    }
    
    private func getThumbnail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        let uri = (args?["uri"] as? String)
        var width = (args?["width"] as? CGFloat)
        var height = (args?["height"] as? CGFloat)
        let size = (args?["size"] as? CGFloat)
        let quality = (args?["quality"] as? CGFloat) ?? 100
        
        if uri == nil {
            result(nil)
            return
        }
        
        let url = URL(fileURLWithPath: uri!)
        let imgData = try? Data(contentsOf: url)
        
        if imgData == nil {
            result(nil)
            return
        }
        
        var format: String = "unknown"
        
        switch imgData![0] {
        case 0x89:
            format = "png"
        case 0xFF:
            format = "jpg"
        case 0x47:
            format = "gif"
        case 0x49, 0x4D:
            format = "tiff"
        case 0x52 where imgData!.count >= 12:
            let subdata = imgData![0...11]

            if let dataString = String(data: subdata, encoding: .ascii),
                dataString.hasPrefix("RIFF"),
                dataString.hasSuffix("WEBP") {
                format = "webp"
            }

        case 0x00 where imgData!.count >= 12 :
            let subdata = imgData![8...11]

            if let dataString = String(data: subdata, encoding: .ascii),
                Set(["heic", "heix", "hevc", "hevx"]).contains(dataString) {
                format = "heic"
            }
        default:
            format = "unknown"
        }
        
        let rawImage = format == "unknown" ? getVideoThumbnail(forUrl: url) : UIImage(data: imgData!)
        
        if rawImage == nil {
            result(nil)
            return
        }
        
        var image: UIImage? = rawImage
        
        if size != nil || (width != nil && height != nil) {
            if (width == nil || height == nil) {
                width = size
                height = size
            }

            image = resizeImage(image: image!, newWidth: width!, newHeight: height!)
        }
        
        
        result(image?.jpegData(compressionQuality: quality))
    }
    
    private func getAlbumThumbnail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        let albumUri = (args?["albumUri"] as? String)
        var width = (args?["width"] as? CGFloat)
        var height = (args?["height"] as? CGFloat)
        let size = (args?["size"] as? CGFloat)
        let quality = (args?["quality"] as? CGFloat) ?? 100
        
        if albumUri == nil {
            result(nil)
            return
        }
        
        getFirstImageOfAlbum(albumUri: albumUri!, completionHandler: { url in
            let finalUrl = url ?? URL(fileURLWithPath: "")
            let imgData = try? Data(contentsOf: finalUrl)
            
            if imgData == nil {
                result(nil)
                return
            }
            
            var format: String = "unknown"
            
            switch imgData![0] {
            case 0x89:
                format = "png"
            case 0xFF:
                format = "jpg"
            case 0x47:
                format = "gif"
            case 0x49, 0x4D:
                format = "tiff"
            case 0x52 where imgData!.count >= 12:
                let subdata = imgData![0...11]

                if let dataString = String(data: subdata, encoding: .ascii),
                    dataString.hasPrefix("RIFF"),
                    dataString.hasSuffix("WEBP") {
                    format = "webp"
                }

            case 0x00 where imgData!.count >= 12 :
                let subdata = imgData![8...11]

                if let dataString = String(data: subdata, encoding: .ascii),
                    Set(["heic", "heix", "hevc", "hevx"]).contains(dataString) {
                    format = "heic"
                }
            default:
                format = "unknown"
            }
            
            let rawImage = format == "unknown" ? self.getVideoThumbnail(forUrl: finalUrl) : UIImage(data: imgData!)
            
            if rawImage == nil {
                result(nil)
                return
            }
            
            var image: UIImage? = rawImage
            
            if size != nil || (width != nil && height != nil) {
                if (width == nil || height == nil) {
                    width = size
                    height = size
                }

                image = self.resizeImage(image: image!, newWidth: width!, newHeight: height!)
            }
            
            
            result(image?.jpegData(compressionQuality: quality))
        })
    }
    
    private func getFirstImageOfAlbum(albumUri: String, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", albumUri)
        let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)

        let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        var allAlbums: Array<PHFetchResult<PHAssetCollection>> = []

        if smartAlbums.count > 0 {
            allAlbums.append(smartAlbums)
        }

        if albums.count > 0 {
            allAlbums.append(albums)
        }
        
        
        let imagePredicate: NSPredicate? = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let videoPredicate: NSPredicate? = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let finalPredicate: NSPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.or, subpredicates: [imagePredicate!, videoPredicate!])
        
        let fetchOptionsAssets = PHFetchOptions()
        
        fetchOptionsAssets.predicate = finalPredicate
        
        var fetchedImages: PHFetchResult<PHAsset> = PHFetchResult()
        if let album = allAlbums.first?.firstObject {
            fetchedImages = PHAsset.fetchAssets(in: album, options: fetchOptionsAssets)
        }

        if fetchedImages.count > 0 {
            fetchedImages[0].getURL(completionHandler: completionHandler)
        } else {
            completionHandler(nil)
        }
    }
    
    func getVideoThumbnail(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }

        return nil
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat, newHeight: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
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

extension UIImage {
    func pixelData() -> [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return pixelData
    }
 }


struct ImageHeaderData{
    static var PNG: [UInt8] = [0x89]
    static var JPEG: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47]
    static var TIFF_01: [UInt8] = [0x49]
    static var TIFF_02: [UInt8] = [0x4D]
}
