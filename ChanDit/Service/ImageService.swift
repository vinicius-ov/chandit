//
//  ImageService.swift
//  ChanDit
//
//  Created by Bemacash on 11/12/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import Photos

struct ImageService {

    var mediaFullName = "image"

    private func fetchAlbum(_ boardName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", boardName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }

    private func createTempPicFile(_ imageData: Data) -> URL? {
        let documentDirectory = try? FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask,
        appropriateFor: nil, create: false)
        let path = documentDirectory!.appendingPathComponent(mediaFullName, isDirectory: false)
        if FileManager.default.createFile(atPath: path.path, contents: imageData, attributes: nil) {
            return path
        } else {
            return nil
        }
    }

    func saveToCameraRoll(_ imageData: Data, albumName: String, completionHandler: @escaping ((Bool, Error?) -> Void)) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            guard let path = createTempPicFile(imageData) else {
                completionHandler(false, Errors.imageTemporaryDirectoryCreationError)
                return }
            let albumName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
            var albumInsertRequest: PHAssetCollectionChangeRequest!
            PHPhotoLibrary.shared().performChanges({
                guard let album = self.fetchAlbum(albumName) else {
                    albumInsertRequest = PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(withTitle: albumName)
                    return
                }
                albumInsertRequest = PHAssetCollectionChangeRequest(for: album)
                let assetChangeRequest = PHAssetChangeRequest
                    .creationRequestForAssetFromImage(atFileURL: path)!
                albumInsertRequest?.addAssets(
                    [assetChangeRequest.placeholderForCreatedAsset!] as NSArray)
            }, completionHandler: { (success, error) in
                try? FileManager.default.removeItem(at: path)
                completionHandler(success, error)
            })
        }
    }
}
