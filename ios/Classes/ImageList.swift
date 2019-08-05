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
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    var cancelClosure: ((_ assets: [PHAsset]) -> Void)?
    var finishClosure: ((_ assets: [PHAsset]) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    let frame: CGRect
    let viewId: Int64
    var uiCollectionView: UICollectionView
    var data: [Int] = Array(0..<10)
    var f:PHFetchResult<PHAsset> = PHFetchResult()
    var selections: [PHAsset] = []
    var imageSize: CGSize = CGSize.zero {
        didSet {
            let scale = UIScreen.main.scale
            imageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        }
    }
    var _channel: FlutterMethodChannel
    
    private let photosManager = PHCachingImageManager.default()
    private let imageContentMode: PHImageContentMode = .aspectFill
    
    let assetStore = AssetStore(assets: [])
    var settings: BSImagePickerSettings = Settings()
    var albumName: String
    
    init(_ frame: CGRect, viewId: Int64, args: Any?, with registrar: FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId
        
        let x = GridCollectionViewLayout()
        x.itemsPerRow = 3
//        x.itemsPerRow = 2
        
//        print("args => \(args?["albumName"])")
//        albumName = args?["albumName"]
//        albumName = args?["albumName"] as! String
//        do {
//            let parsedData = try JSONSerialization.jsonObject(with: args as! Data) as! [String:Any]
        if let dict = args as? [String: Any] {
            self.albumName = (dict["albumName"] as? String)!
        } else {
            self.albumName = "error"
        }
//            self.albumName = args["albumName"] as! String
//        } catch let error as NSError {
//            print(error)
//            self.albumName = "error"
//        }
        
        self.uiCollectionView = UICollectionView(frame: frame, collectionViewLayout: x)
        _channel = FlutterMethodChannel(name: "plugins.flutter.io/image_list/\(viewId)", binaryMessenger: registrar.messenger())
        _channel.setMethodCallHandler { call, result in
            result(nil)
        }
    }
    
    public func view() -> UIView {
//        collectionView?.backgroundColor = settings.backgroundColor
        self.uiCollectionView.allowsMultipleSelection = true
        self.uiCollectionView.dataSource = self
        self.uiCollectionView.delegate = self
        self.registerCellIdentifiersForCollectionView(self.uiCollectionView)
        self.uiCollectionView.alwaysBounceVertical = true
        self.uiCollectionView.backgroundColor = .white
        self.uiCollectionView.backgroundColor = UIColor.green
//        self.uiCollectionView.layoutMargins = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        
            let fetchOptions = PHFetchOptions()
            
            let smartAlbums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
            
            let albums: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            let allAlbums: Array<PHFetchResult<PHAssetCollection>> = [smartAlbums, albums]
            
            for i in 0 ..< allAlbums.count {
                let resultx: PHFetchResult = allAlbums[i]
                
                resultx.enumerateObjects { (asset, index, stop) -> Void in
                    if asset.localizedTitle == self.albumName {
                        self.f = PHAsset.fetchAssets(in: asset, options: fetchOptions)
                    }
                }
            }
        
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
        cell.settings = self.settings

        // Cancel any pending image requests
        if cell.tag != 0 {
            photosManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }

        let asset = self.f[indexPath.row]
        cell.asset = asset
//        print("lalala \(self.uiCollectionView.layoutMargins)")
        
        if let collectionViewFlowLayout = self.uiCollectionView.collectionViewLayout as? GridCollectionViewLayout {
            self.imageSize = collectionViewFlowLayout.itemSize
        }
        // Request image
        cell.tag = Int(photosManager.requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: nil) { (result, _) in
            cell.imageView.image = result
        })

        // Set selection number
        if let index = assetStore.assets.firstIndex(of: asset) {
            if let character = settings.selectionCharacter {
                cell.selectionString = String(character)
            } else {
                cell.selectionString = String(index+1)
            }

            cell.photoSelected = true
        } else {
            cell.photoSelected = false
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
        
        if assetStore.contains(asset) { // Deselect
            print("deselect")
            _channel.invokeMethod("deselect", arguments: nil)
            // Deselect asset
            assetStore.remove(asset)
            
            // Get indexPaths of selected items
            let selectedIndexPaths = assetStore.assets.compactMap({ (asset) -> IndexPath? in
                let index = f.index(of: asset)
                
                guard index != NSNotFound else { return nil }
                
                return IndexPath(item: index, section: 0)
            })
            
            // Reload selected cells to update their selection number
            UIView.setAnimationsEnabled(false)
            collectionView.reloadItems(at: selectedIndexPaths)
            UIView.setAnimationsEnabled(true)
            
            cell.photoSelected = false
            
            // Call deselection closure
            deselectionClosure?(asset)
        } else if assetStore.count < settings.maxNumberOfSelections { // Select
            print("Select")
            _channel.invokeMethod("select", arguments: nil)
            // Select asset if not already selected
            assetStore.append(asset)
            
            // Set selection number
            if let selectionCharacter = settings.selectionCharacter {
                cell.selectionString = String(selectionCharacter)
            } else {
                cell.selectionString = String(assetStore.count)
            }
            
            cell.photoSelected = true
            
            
            // Call selection closure
            selectionClosure?(asset)
        } else if assetStore.count >= settings.maxNumberOfSelections {
            print("lalala")
            selectLimitReachedClosure?(assetStore.count)
        } else {
            print("else")
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
