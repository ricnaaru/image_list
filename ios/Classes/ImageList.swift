//
//  ImageList.swift
//  image_list
//
//  Created by Richardo GVT on 18/07/19.
//

import UIKit
import Flutter
import Photos

public class ImageListView : NSObject, FlutterPlatformView {
    let frame: CGRect!
    let viewId: Int64!
    var uiCollectionView: UICollectionView!
    var fetchedImages: PHFetchResult<PHAsset> = PHFetchResult()
    var selections: [[String: String]] = []
    var imageSize: CGSize = CGSize.zero {
        didSet {
            let scale = UIScreen.main.scale
            imageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        }
    }
    var _channel: FlutterMethodChannel
    
    private let photosManager = PHCachingImageManager.default()
    private let imageContentMode: PHImageContentMode = .aspectFill
    
    let assetStore: AssetStore
    var albumId: String = ""
    var maxSize: Int?
    var maxImage: Int?
    var fileNamePrefix: String = ""
    var types: String = ""
    var imageListColor: String = ""
    var itemColor: String = ""

    init(_ frame: CGRect, viewId: Int64, args: Any?, with registrar: FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId

        let x = GridCollectionViewLayout()
        x.itemsPerRow = 3

        if let dict = args as? [String: Any] {
            self.selections = dict["selections"] as? [[String: String]] ?? []
            self.albumId = (dict["albumId"] as? String)!
            self.maxImage = dict["maxImage"] as? Int
            self.maxSize = dict["maxSize"] as? Int
            self.fileNamePrefix = (dict["fileNamePrefix"] as? String)!
            self.types = (dict["types"] as? String)!
            self.imageListColor = (dict["imageListColor"] as? String)!
            self.itemColor = (dict["itemColor"] as? String)!
        }

        assetStore = AssetStore(assets: [Asset?](repeating: nil, count: selections.count))

        self.uiCollectionView = UICollectionView(frame: frame, collectionViewLayout: x)
        _channel = FlutterMethodChannel(name: "plugins.flutter.io/image_list/\(viewId)", binaryMessenger: registrar.messenger())

        super.init()
        self.uiCollectionView.allowsMultipleSelection = true
        self.uiCollectionView.dataSource = self
        self.uiCollectionView.delegate = self
        self.registerCellIdentifiersForCollectionView(self.uiCollectionView)
        self.uiCollectionView.alwaysBounceVertical = true

        
        let backgroundColorRed = Int(imageListColor[2..<4], radix: 16) ?? 0xab
        let backgroundColorGreen = Int(imageListColor[4..<6], radix: 16) ?? 0xab
        let backgroundColorBlue = Int(imageListColor[6..<8], radix: 16) ?? 0xab
        let backgroundColorAlpha = Int(imageListColor[0..<2], radix: 16) ?? 0xff
        self.uiCollectionView.backgroundColor = UIColor.init(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue, a: backgroundColorAlpha)

        loadImage()

        setup()
    }
    
    private func setup() {
        _channel.setMethodCallHandler { call, result in
            if call.method == "waitForList" {
                result(nil)
            } else if call.method == "setMaxImage" {
                if let dict = call.arguments as? [String: Any] {
                    self.maxImage = (dict["maxImage"] as? Int)
                } else {
                    self.maxImage = 0
                }

                self.assetStore.removeAll()
                self.selections.removeAll()
                self.loadImage()

                result(nil)
            } else if call.method == "reloadAlbum" {
                if let dict = call.arguments as? [String: Any] {
                    self.albumId = (dict["albumId"] as? String)!
                    self.types = (dict["types"] as? String)!
                } else {
                    self.albumId = ""
                    self.types = ""
                }

                self.loadImage()

                result(nil)
            } else if call.method == "getSelectedMedia" {
                self.getSelectedImages(completionHandler: { images in
                    result(images)
                })
            }
        }
    }

//    private func secureCopyItem(at srcURL: URL) -> String? {
//
//        let pathWithoutExtension = srcURL.deletingPathExtension().path
//        let fileExtension = srcURL.path.replacingOccurrences(of: pathWithoutExtension, with: "")
//
//        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
//            return nil
//        }
//
//        let timestamp = NSDate().timeIntervalSince1970
//        let myTimeInterval = TimeInterval(timestamp)
//        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
//        let dateFormatterGet = DateFormatter()
//        dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss"
//
//        let fileURL = directory.appendingPathComponent("\(self.fileNamePrefix)_\(dateFormatterGet.string(from: time as Date))\(fileExtension)")
//
//        if let fileURL = fileURL {
//            do {
//                if FileManager.default.fileExists(atPath: fileURL.path) {
//                    try FileManager.default.removeItem(at: fileURL)
//                }
//
//                let image = UIImage(contentsOfFile: srcURL.path)
//
//                if let image = image {
//                    let resizedImage = resizeImage(image: image)!
//
//                    if fileExtension.lowercased() == ".png" {
//                        if let data = resizedImage.pngData() {
//                            try? data.write(to: fileURL)
//                        }
//                    } else if fileExtension.lowercased() == ".jpg" || fileExtension.lowercased() == ".jpeg" {
//                        if let data = resizedImage.jpegData(compressionQuality: 1) {
//                            try? data.write(to: fileURL)
//                        }
//                    } else {
//                        return nil
//                    }
//
//                    return fileURL.path
//                } else {
//                    return nil
//                }
//            } catch (let error) {
//                print("Cannot copy item at \(srcURL) to \(fileURL): \(error)")
//                return nil
//            }
//        } else {
//            print("Failed to initialize destination file name")
//            return nil
//        }
//    }

    func resizeImage(image: UIImage) -> UIImage! {
        if (self.maxSize == nil) {
            return image
        }
        let scale = CGFloat(self.maxSize!) / image.size.width
        let newWidth = image.size.width * scale
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    private func getSelectedImages(completionHandler : @escaping (([[String: String]]) -> Void)) {
        var selectedImages: [[String: String]] = []

        if self.assetStore.assets.count == 0 {
            completionHandler(selectedImages)
        } else {
            for i in 0...self.assetStore.assets.count - 1 {
                var dict: [String: String] = [String:String]()
                if let asset = self.assetStore.assets[i]?.asset {
                    let option = PHContentEditingInputRequestOptions()
                    option.isNetworkAccessAllowed = true
                    autoreleasepool {
                        let _ = asset.requestContentEditingInput(with: option) { (input, _) in
                            asset.getURL(completionHandler:  { responseUrl in
                                if let url = responseUrl {
                                    dict["albumId"] = self.albumId
                                    dict["type"] = asset.mediaType == .video ? "VIDEO" : "IMAGE"
                                    if asset.mediaType == .video {
                                        dict["duration"] = String.init(asset.duration * 1000)
                                    }
                                    dict["assetId"] = "\(url.path)"
                                    dict["uri"] = "\(url.path)"
                                    selectedImages.append(dict)

                                    if selectedImages.count == self.assetStore.assets.count {
                                        completionHandler(selectedImages)
                                    }
    //                                let newFile = self.secureCopyItem(at: url)
    //                                if let newFile = newFile {
    //                                    dict["assetId"] = "\(newFile)"
    //
    //                                    print("dict -> \(dict)")
    //                                    selectedImages.append(dict)
    //
    //                                    if selectedImages.count == self.assetStore.assets.count {
    //                                        flutterResult(selectedImages)
    //                                    }
    //                                }
                                }
                            })
                        }
                    }
                }
            }
        }
    }

    private func loadImage() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", self.albumId)
        self.fetchedImages = PHFetchResult()
        let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)

        let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        var allAlbums: Array<PHFetchResult<PHAssetCollection>> = []

        if smartAlbums.count > 0 {
            allAlbums.append(smartAlbums)
        }

        if albums.count > 0 {
            allAlbums.append(albums)
        }
        
        
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
        
        let fetchOptionsAssets = PHFetchOptions()
        
        fetchOptionsAssets.predicate = finalPredicate!
        let sortOrder = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptionsAssets.sortDescriptors = sortOrder

        if let album = allAlbums.first?.firstObject {
            self.fetchedImages = PHAsset.fetchAssets(in: album, options: fetchOptionsAssets)
        }

        if self.fetchedImages.count > 0 {
            for i in 0...self.fetchedImages.count - 1 {
                if self.selections.count > 0 {
                    for j in 0...self.selections.count - 1 {
                        let x = self.selections[j]

                        if x["assetId"] == fetchedImages[i].localIdentifier {
                            assetStore.insert(fetchedImages[i], self.albumId, at: j)
                        }
                    }
                }

                if i % 100 == 0 {
                    DispatchQueue.main.async {
                        self.uiCollectionView.reloadData()
                    }
                }
             }
        }

        DispatchQueue.main.async {
            self.uiCollectionView.reloadData()
        }
    }

    public func view() -> UIView {
        return self.uiCollectionView
    }
}

extension ImageListView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedImages.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        UIView.setAnimationsEnabled(false)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.cellIdentifier, for: indexPath) as! PhotoCell
        cell.accessibilityIdentifier = "photo_cell_\(indexPath.item)"
        cell.isAccessibilityElement = true
        cell.multipleMode = maxImage != 1

        // Cancel any pending image requests
        if cell.tag != 0 {
            photosManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }

        let asset = self.fetchedImages[indexPath.row]

        cell.asset = asset
        
        if asset.mediaType == .video {
            cell.textView.isHidden = false
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(asset.duration))
            
            var durationText: String = ""
            
            if h > 0 {
                durationText += "\(String(format: "%02d", h)):"
            }
            
            if m > 0 {
                durationText += "\(String(format: "%02d", m)):"
            } else {
                durationText += "0:"
            }
            
            durationText += "\(String(format: "%02d", s))"
            
            cell.textView.text = durationText
            cell.textView.textContainerInset = UIEdgeInsets(top: 2, left: 3,bottom: 2,right: 3)
            
            let fixedWidth = cell.textView.frame.size.width
            let newSize = cell.textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            cell.textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
            
            if #available(iOS 9.0, *) {
                NSLayoutConstraint.activate([
                    cell.textView.heightAnchor.constraint(equalToConstant: newSize.height),
                cell.textView.widthAnchor.constraint(equalToConstant: max(newSize.width, fixedWidth))
                ])
            }
        } else {
            cell.textView.text = ""
            cell.textView.isHidden = true
        }

        if let collectionViewFlowLayout = self.uiCollectionView.collectionViewLayout as? GridCollectionViewLayout {
            self.imageSize = collectionViewFlowLayout.itemSize
        }

        let option = PHImageRequestOptions()

        option.isNetworkAccessAllowed = true //(false by default)
        option.isSynchronous = false
        // Request image
        cell.tag = Int(PHCachingImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: option) { (result, e) in
            cell.imageView.image = result
        })
        
        // Set selection number
        if maxImage == 1 {
            cell.photoSelected = false
        } else {
            if let index = assetStore.assets.firstIndex(where: { $0 != nil && $0?.asset == asset }) {
                cell.selectionString = String(index+1)
                cell.photoSelected = true
            } else {
                cell.selectionString = ""
                cell.photoSelected = false
            }
        }
        
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = UIAccessibilityTraits.button
        
        UIView.setAnimationsEnabled(true)
        
        return cell
    }
    
    func registerCellIdentifiersForCollectionView(_ collectionView: UICollectionView?) {
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.cellIdentifier)
    }
}

func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
  return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

// MARK: UICollectionViewDelegate
extension ImageListView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell else { return false }
        cell.multipleMode = maxImage != 1
        
        let asset = fetchedImages.object(at: indexPath.row)
        
        if maxImage == 1 {
            assetStore.removeAll()
            assetStore.append(asset, self.albumId)
            cell.singlePhotoSelected()
        } else {
            if assetStore.contains(asset) { // Deselect
                // Deselect asset
                assetStore.remove(asset)
                
                // Get indexPaths of selected items
                let selectedIndexPaths = assetStore.assets.compactMap({ (asset) -> IndexPath? in
                    if asset == nil {
                        return nil
                    }
                    
                    let index = fetchedImages.index(of: asset!.asset)
                    
                    guard index != NSNotFound else { return nil }
                    
                    return IndexPath(item: index, section: 0)
                })
                
                let backgroundColorRed = Int(imageListColor[2..<4], radix: 16) ?? 0xab
                let backgroundColorGreen = Int(imageListColor[4..<6], radix: 16) ?? 0xab
                let backgroundColorBlue = Int(imageListColor[6..<8], radix: 16) ?? 0xab
                let backgroundColorAlpha = Int(imageListColor[0..<2], radix: 16) ?? 0xff
                cell.backgroundColor = UIColor.init(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue, a: backgroundColorAlpha)
                // Reload selected cells to update their selection number
                UIView.setAnimationsEnabled(false)
                collectionView.reloadItems(at: selectedIndexPaths)
                UIView.setAnimationsEnabled(true)

                cell.selectionString = ""
                cell.photoSelected = false
            } else if maxImage == nil || assetStore.count < maxImage! { // Select
                // Select asset if not already selected
                assetStore.append(asset, self.albumId)
                
                if maxImage != 1 {
                    // Set selection number
                    cell.selectionString = String(assetStore.count)
                    
                    cell.photoSelected = true
                }
            }
        }
        
        self.getSelectedImages(completionHandler: { images in
            self._channel.invokeMethod("onImageTapped", arguments: ["count": self.assetStore.count, "selectedImages": images])
        })
        
        return false
    }
}

public class ImageListViewFactory : NSObject, FlutterPlatformViewFactory {
    var _registrar: FlutterPluginRegistrar
    
    init(with registrar: FlutterPluginRegistrar) {
        _registrar = registrar
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return ImageListView(frame, viewId: viewId, args: args, with: _registrar)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

extension PHAsset {
    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
            return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
            completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: Int = 0xFF) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }

    convenience init(argb: Int) {
        self.init(
            red: (argb >> 16) & 0xFF,
            green: (argb >> 8) & 0xFF,
            blue: argb & 0xFF,
            a: (argb >> 24) & 0xFF
        )
    }
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
