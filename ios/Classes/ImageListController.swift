//
//  ImageListController.swift
//  image_list
//
//  Created by Richardo GVT on 18/07/19.
//

import UIKit

final class ImageListViewController {
    
}

//final class PhotoCollectionViewDataSource : NSObject, UICollectionViewDataSource {
//    var fetchResult: PHFetchResult<PHAsset>
//
//    private let photosManager = PHCachingImageManager.default()
//    private let imageContentMode: PHImageContentMode = .aspectFill
//    private let assetStore: AssetStore
//
//    let settings: BSImagePickerSettings?
//    var imageSize: CGSize = CGSize.zero {
//        didSet {
//            let scale = UIScreen.main.scale
//            imageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
//        }
//    }
//
//    init(fetchResult: PHFetchResult<PHAsset>, assetStore: AssetStore, settings: BSImagePickerSettings?) {
//        self.fetchResult = fetchResult
//        self.settings = settings
//        self.assetStore = assetStore
//
//        super.init()
//    }
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return fetchResult.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        UIView.setAnimationsEnabled(false)
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.cellIdentifier, for: indexPath) as! PhotoCell
//        cell.accessibilityIdentifier = "photo_cell_\(indexPath.item)"
//        cell.isAccessibilityElement = true
//        if let settings = settings {
//            cell.settings = settings
//        }
//
//        // Cancel any pending image requests
//        if cell.tag != 0 {
//            photosManager.cancelImageRequest(PHImageRequestID(cell.tag))
//        }
//
//        let asset = fetchResult[indexPath.row]
//        cell.asset = asset
//
//        // Request image
//        cell.tag = Int(photosManager.requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: nil) { (result, _) in
//            cell.imageView.image = result
//        })
//
//        // Set selection number
//        if let index = assetStore.assets.firstIndex(of: asset) {
//            if let character = settings?.selectionCharacter {
//                cell.selectionString = String(character)
//            } else {
//                cell.selectionString = String(index+1)
//            }
//
//            cell.photoSelected = true
//        } else {
//            cell.photoSelected = false
//        }
//
//        cell.isAccessibilityElement = true
//        cell.accessibilityTraits = UIAccessibilityTraits.button
//
//        UIView.setAnimationsEnabled(true)
//
//        return cell
//    }
//
//    func registerCellIdentifiersForCollectionView(_ collectionView: UICollectionView?) {
//        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.cellIdentifier)
//    }
//}
//
