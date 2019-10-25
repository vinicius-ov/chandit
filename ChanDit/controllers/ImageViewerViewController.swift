//
//  ImageViewerViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 27/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import Photos
import SDWebImage

class ImageViewerViewController: UIViewController, CompleteBoardNameProtocol {
    
    var completeBoardName: String = "I am Error"

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView! {
        didSet {
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.startAnimating()
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    var postViewModel: PostViewModel!
    var boardId: String!
    var tapGesture: UITapGestureRecognizer!
    
    let imageCache = SDImageCache.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(willDismiss))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        imageViewWidth.constant =  postViewModel.imageWidth ?? 0.0
        imageViewHeight.constant = postViewModel.imageHeight ?? 0.0
        imageView.bounds.size.width = postViewModel.imageWidth ?? 0.0
        imageView.bounds.size.height = postViewModel.imageHeight ?? 0.0
    }
    
    @objc
    func willDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "tray.and.arrow.down.fill"),
                style: .plain,
                target: self,
                action: #selector(self.saveImage))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                            target: self, action: #selector(self.saveImage))
        }
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        guard let url = postViewModel.imageUrl(boardId: boardId) else { return }
        download(url)
    }
    
    fileprivate func storeDownloadedCacheToData(_ image: UIImage?, _ data: Data?, _ url: URL) {
        imageCache.store(image, imageData: data, forKey: url.absoluteString, toDisk: true, completion: nil)
    }
    
    func download(_ url: URL) {
        imageCache.queryCacheOperation(forKey: url.absoluteString) { (image, data, _) in
            if let image = image {
                self.setImageToImageView(image)
                self.updateInterfaceImageLoaded()
                print("SDWEB: buscando da cache")
                self.loadingIndicator.stopAnimating()
            } else {
                let downloader = SDWebImageDownloader.shared
                downloader.downloadImage(with: url) { [weak self] (image, data, error, finished) in
                    if let image = image, finished {
                        print("SDWEB: buscando da net")
                        self?.setImageToImageView(image)
                        self?.storeDownloadedCacheToData(image, data, url)
                        self?.updateInterfaceImageLoaded()
                    } else if error != nil {
                        print("SDWEB: ERRO buscando da net")
                    }
                    self?.loadingIndicator.stopAnimating()
                }
            }
        }
    }
    
    func setImageToImageView(_ image: UIImage) {
        self.imageView.image = image
    }
    
    func updateInterfaceImageLoaded() {
        DispatchQueue.main.async {
            self.updateConstraintsForSize(self.view.bounds.size)
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    private func showFailToast() {
        showToast(
            message: "Not authorized to save images in Camera Roll. Go to Settings to fix this.",
            textColor: nil,
            backgroundColor: nil)
    }
    
    @objc func saveImage() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        PHPhotoLibrary.requestAuthorization({ [weak self] (status) in
            if status == .authorized {
                guard let url = self?.postViewModel.imageUrl(boardId: (self?.boardId)!) else { return }
                if let data = self?.imageCache.diskImageData(forKey: url.absoluteString) {
                        self?.saveToCameraRoll(data)
                    } else {
                        DispatchQueue.main.async {
                            self?.navigationItem.rightBarButtonItem?.isEnabled = true
                            self?.showToast(
                                message: "Failed to fetch data from cache. Try again later.",
                                            textColor: .red, backgroundColor: .white)
                        }
                    }
            } else {
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.showFailToast()
                }
            }
        })
    }
    
    private func fetchAlbum(_ boardName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", boardName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    
    private func createTempPicFile(_ data: Data) -> URL? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let path = documentsDirectory.appendingPathComponent(postViewModel.mediaFullName!, isDirectory: false)
        if FileManager.default.createFile(atPath: path.path, contents: data, attributes: nil) {
            return path
        } else {
            return nil
        }
    }

    private func saveToCameraRoll(_ data: Data) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            
            guard let path = createTempPicFile(data) else { return }
            let albumName = self.completeBoardName.trimmingCharacters(in: .whitespacesAndNewlines)
            let album = fetchAlbum(albumName)
            
            PHPhotoLibrary.shared().performChanges({
                var albumInsertRequest: PHAssetCollectionChangeRequest? = nil
                if album == nil {
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                } else {
                    albumInsertRequest = PHAssetCollectionChangeRequest(for: album!)
                }
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: path)!
                albumInsertRequest?.addAssets([assetChangeRequest.placeholderForCreatedAsset!] as NSArray)

            }) { (success, error) in
                if success {
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        self.showSuccessToast()
                    }
                } else {
                    print(error?.localizedDescription)
                    self.showFailToast()
                }
            }
        }
    }

    func showSuccessToast() {
            self.showToast(message: "Photo was saved to the camera roll.",
                           textColor: UIColor.black,
                           backgroundColor: UIColor(named: "lightGreenSuccess"))
    }
    
    fileprivate func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateMinZoomScaleForSize(view.bounds.size)
    }

    fileprivate func updateConstraintsForSize(_ size: CGSize?) {
        guard let size = size else { return }

        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    
}

extension ImageViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
}

extension UIViewController {
    func showToast(message:String,
                   textColor: UIColor?,
                   backgroundColor: UIColor?) {
        let label = UILabel(frame:
            CGRect(x: view.frame.origin.x,
                   y: view.frame.height*0.9,
                   width: view.frame.width, height: 30))
        label.backgroundColor = backgroundColor ?? .red
        label.clipsToBounds = true
        label.textAlignment = .center
        label.text = message
        label.textColor = textColor ?? .white
        label.numberOfLines = 0
        view.addSubview(label)
        UIView.animate(withDuration: 2.0, delay: 1.0, animations: {
            label.alpha = 0
        }) { finished in
            label.removeFromSuperview()
        }
    }
}

extension UserDefaults {
    static var dataCache: UserDefaults {
        return UserDefaults(suiteName: "chanditDataCache")!
    }
}
