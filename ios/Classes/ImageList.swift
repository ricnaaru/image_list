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
    var f:PHFetchResult<PHAsset> = PHFetchResult()
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
    var maxImage: Int?
    
    init(_ frame: CGRect, viewId: Int64, args: Any?, with registrar: FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId
        
        let x = GridCollectionViewLayout()
        x.itemsPerRow = 3
        
        if let dict = args as? [String: Any] {
            self.selections = dict["selections"] as? [[String: String]] ?? []
            self.albumId = (dict["albumId"] as? String)!
            self.maxImage = dict["maxImage"] as? Int
        }
        
        assetStore = AssetStore(assets: [Asset?](repeating: nil, count: selections.count))
        
        self.uiCollectionView = UICollectionView(frame: frame, collectionViewLayout: x)
        _channel = FlutterMethodChannel(name: "plugins.flutter.io/image_list/\(viewId)", binaryMessenger: registrar.messenger())
        
        super.init()
        handle()
    }
    
    private func handle() {
        self.uiCollectionView.allowsMultipleSelection = true
        self.uiCollectionView.dataSource = self
        self.uiCollectionView.delegate = self
        self.registerCellIdentifiersForCollectionView(self.uiCollectionView)
        self.uiCollectionView.alwaysBounceVertical = true
        self.uiCollectionView.backgroundColor = .white
        
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
                self.loadImage()
                
                result(nil)
            } else if call.method == "reloadAlbum" {
                if let dict = call.arguments as? [String: Any] {
                    self.albumId = (dict["albumId"] as? String)!
                } else {
                    self.albumId = ""
                }
                self.loadImage()
                
                result(nil)
            } else if call.method == "getSelectedImages" {
                var selectedImages: [[String: String]] = []
                
                if self.assetStore.assets.count == 0 {
                    result(nil)
                } else {
                    for i in 0...self.assetStore.assets.count - 1 {
                        var dict: [String: String] = [String:String]()
                        
                        dict["albumId"] = self.assetStore.assets[i]?.albumId
                        dict["assetId"] = self.assetStore.assets[i]?.asset.localIdentifier
                        selectedImages.append(dict)
                    }

                    result(selectedImages)
                }
            }
        }
        
        loadImage()
    }
    
    private func loadImage() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", self.albumId)
        self.f = PHFetchResult()
        let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
    
        let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
    
        var allAlbums: Array<PHFetchResult<PHAssetCollection>> = []
        
        if smartAlbums.count > 0 {
            allAlbums.append(smartAlbums)
        }
        
        if albums.count > 0 {
            allAlbums.append(albums)
        }
    
        let fetchOptionsAssets = PHFetchOptions()
    
        if let album = allAlbums.first?.firstObject {
            self.f = PHAsset.fetchAssets(in: album, options: fetchOptionsAssets)
        }
        
        if self.f.count > 0 {
            for i in 0...self.f.count - 1 {
                if self.selections.count > 0 {
                    for j in 0...self.selections.count - 1 {
                        var x = self.selections[j]
                        
                        if x["assetId"] == f[i].localIdentifier {
                            assetStore.insert(f[i], self.albumId, at: j)
                        }
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
        return self.f.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        UIView.setAnimationsEnabled(false)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.cellIdentifier, for: indexPath) as! PhotoCell
        cell.accessibilityIdentifier = "photo_cell_\(indexPath.item)"
        cell.isAccessibilityElement = true

        // Cancel any pending image requests
        if cell.tag != 0 {
            photosManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let asset = self.f[indexPath.row]
        
        cell.asset = asset
        
        if let collectionViewFlowLayout = self.uiCollectionView.collectionViewLayout as? GridCollectionViewLayout {
            self.imageSize = collectionViewFlowLayout.itemSize
        }
        
        let option = PHImageRequestOptions()
        
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

// MARK: UICollectionViewDelegate
extension ImageListView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell else { return false }
        
        let asset = f.object(at: indexPath.row)
        
        if maxImage == 1 {
            assetStore.removeAll()
            assetStore.append(asset, self.albumId)
            cell.singlePhotoSelected()
            _channel.invokeMethod("onImageTapped", arguments: ["count": assetStore.count])
        } else {
            if assetStore.contains(asset) { // Deselect
                print("deselect")
                // Deselect asset
                assetStore.remove(asset)
                
                // Get indexPaths of selected items
                let selectedIndexPaths = assetStore.assets.compactMap({ (asset) -> IndexPath? in
                    if asset == nil {
                        return nil
                    }
                    
                    let index = f.index(of: asset!.asset)
                    
                    guard index != NSNotFound else { return nil }
                    
                    return IndexPath(item: index, section: 0)
                })
                
                // Reload selected cells to update their selection number
                UIView.setAnimationsEnabled(false)
                collectionView.reloadItems(at: selectedIndexPaths)
                UIView.setAnimationsEnabled(true)
                
                cell.photoSelected = false
                _channel.invokeMethod("onImageTapped", arguments: ["count": assetStore.count])
            } else if maxImage == nil || assetStore.count < maxImage! { // Select
                // Select asset if not already selected
                assetStore.append(asset, self.albumId)
                
                if maxImage != 1 {
                    // Set selection number
                    cell.selectionString = String(assetStore.count)
                    
                    cell.photoSelected = true
                }
                _channel.invokeMethod("onImageTapped", arguments: ["count": assetStore.count])
            }
        }

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

//// MARK: UIImagePickerControllerDelegate
//extension ImageListView: UIImagePickerControllerDelegate {
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//            picker.dismiss(animated: true, completion: nil)
//            return
//        }
//
//        var placeholder: PHObjectPlaceholder?
//        PHPhotoLibrary.shared().performChanges({
//            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
//            placeholder = request.placeholderForCreatedAsset
//        }, completionHandler: { success, error in
//            guard let placeholder = placeholder, let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject, success == true else {
//                picker.dismiss(animated: true, completion: nil)
//                return
//            }
//
//            DispatchQueue.main.async {
//                // TODO: move to a function. this is duplicated in didSelect
//                self.assetStore.append(asset)
//                self.updateDoneButton()
//
//                // Call selection closure
//                self.selectionClosure?(asset)
//
//                picker.dismiss(animated: true, completion: nil)
//            }
//        })
//    }
//
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true, completion: nil)
//    }
//}

//// MARK: PHPhotoLibraryChangeOb server
//extension ImageListView: PHPhotoLibraryChangeObserver {
//    public func photoLibraryDidChange(_ changeInstance: PHChange) {
//        guard let collectionView = uiCollectionView else {
//            return
//        }
//
//        DispatchQueue.main.async(execute: { () -> Void in
//            if let photosChanges = changeInstance.changeDetails(for: self.f as! PHFetchResult<PHObject>) {
//                // Update collection view
//                // Alright...we get spammed with change notifications, even when there are none. So guard against it
//                let removedCount = photosChanges.removedIndexes?.count ?? 0
//                let insertedCount = photosChanges.insertedIndexes?.count ?? 0
//                let changedCount = photosChanges.changedIndexes?.count ?? 0
//                if photosChanges.hasIncrementalChanges && (removedCount > 0 || insertedCount > 0 || changedCount > 0) {
//                    // Update fetch result
//                    self.f = photosChanges.fetchResultAfterChanges as! PHFetchResult<PHAsset>
//
//                    collectionView.performBatchUpdates({
//                        if let removed = photosChanges.removedIndexes {
//                            collectionView.deleteItems(at: removed.bs_indexPathsForSection(1))
//                        }
//
//                        if let inserted = photosChanges.insertedIndexes {
//                            collectionView.insertItems(at: inserted.bs_indexPathsForSection(1))
//                        }
//
//                        if let changed = photosChanges.changedIndexes {
//                            collectionView.reloadItems(at: changed.bs_indexPathsForSection(1))
//                        }
//                    })
//
////                     Changes is causing issues right now...fix me later
////                     Example of issue:
////                     1. Take a new photo
////                     2. We will get a change telling to insert that asset
////                     3. While it's being inserted we get a bunch of change request for that same asset
////                     4. It flickers when reloading it while being inserted
////                     TODO: FIX
//                                        if let changed = photosChanges.changedIndexes {
//                                            print("changed")
//                                            collectionView.reloadItems(at: changed.bs_indexPathsForSection(1))
//                                        }
//                } else if photosChanges.hasIncrementalChanges == false {
//                    // Update fetch result
//                    self.f = photosChanges.fetchResultAfterChanges as! PHFetchResult<PHAsset>
//
//                    // Reload view
//                    collectionView.reloadData()
//                }
//            }
//        })
//
//
//        // TODO: Changes in albums
//    }
//}
//
//extension IndexSet {
//    /**
//     - parameter section: The section for the created NSIndexPaths
//     - return: An array with NSIndexPaths
//     */
//    func bs_indexPathsForSection(_ section: Int) -> [IndexPath] {
//        var indexPaths: [IndexPath] = []
//
//        for value in self {
//            indexPaths.append(IndexPath(item: value, section: section))
//        }
//
//        return indexPaths
//    }
//}
