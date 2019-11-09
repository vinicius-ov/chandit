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
        var completeBoardName: String = "Im Error"

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
        
        let doubleTapZoom = UITapGestureRecognizer(target: self, action: #selector(willZoom))
        doubleTapZoom.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapZoom)
        
        let tapShowBar = UITapGestureRecognizer(target: self, action: #selector(toggleShowNavBar))
        tapShowBar.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapShowBar)
        
        imageViewWidth.constant =  postViewModel.imageWidth ?? 0.0
        imageViewHeight.constant = postViewModel.imageHeight ?? 0.0
        imageView.bounds.size.width = postViewModel.imageWidth ?? 0.0
        imageView.bounds.size.height = postViewModel.imageHeight ?? 0.0
        navigationController?.navigationBar.setTransparent()
    }
    
    @objc
    func willDismiss() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.alpha = 1.0
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }
    
    @objc
    func toggleShowNavBar() {
        fadeNavBar()
    }
    
    private func fadeNavBar() {
        guard let navCtrl = navigationController else { return }
        UIView.animate(withDuration: 0.25, animations: {
            var alpha: CGFloat = 0.0
            if navCtrl.navigationBar.alpha == 0.0 {
                alpha = 1.0
            }
            navCtrl.navigationBar.alpha = alpha
        })
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
    
    
    // MARK: save image functions
    
    fileprivate func storeDownloadedCacheToData(_ image: UIImage?, _ data: Data?, _ url: URL) {
        imageCache.store(image, imageData: data, forKey: url.absoluteString, toDisk: true, completion: nil)
    }
    
    func download(_ url: URL) {
        imageCache.queryCacheOperation(forKey: url.absoluteString) { (image, data, _) in
            if let image = image {
                self.setImageToImageView(image)
                self.updateInterfaceImageLoaded()
                print("SDWEB: buscando da cache")
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
            self.loadingIndicator.stopAnimating()
        }
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
        let documentDirectory = try? FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask,
        appropriateFor: nil, create: false)
        let path = documentDirectory!.appendingPathComponent(postViewModel.mediaFullName!, isDirectory: false)
        if FileManager.default.createFile(atPath: path.path, contents: data, attributes: nil) {
            return path
        } else {
            return nil
        }
    }

    private func saveToCameraRoll(_ data: Data) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            
            guard let path = createTempPicFile(data) else { return }
            let albumName = self.completeBoardName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let album = fetchAlbum(albumName)
            var albumInsertRequest: PHAssetCollectionChangeRequest!
            
            PHPhotoLibrary.shared().performChanges({
                if album == nil {
                    albumInsertRequest = PHAssetCollectionChangeRequest
                        .creationRequestForAssetCollection(withTitle: albumName)
                } else {
                    albumInsertRequest = PHAssetCollectionChangeRequest(for: album!)
                }
                let assetChangeRequest = PHAssetChangeRequest
                    .creationRequestForAssetFromImage(atFileURL: path)!
                albumInsertRequest?.addAssets(
                    [assetChangeRequest.placeholderForCreatedAsset!] as NSArray)

            }) { (success, error) in
                if success {
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        self.showSuccessToast()
                    }
                    try? FileManager.default.removeItem(at: path)
                } else {
                    print(error?.localizedDescription)
                    self.showFailToast()
                }
            }
        }
    }
    
    // MARK: alert builders
    
    private func showFailToast() {
        showToast(
            message: "Not authorized to save images in Camera Roll. Go to Settings to fix this.")
    }
    
    func showSuccessToast() {
            self.showToast(message: "Photo was saved to the camera roll.",
                           textColor: UIColor.black,
                           backgroundColor: UIColor(named: "lightGreenSuccess")!)
    }
    
    // MARK: zoom/pinch image functions

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

        let yOffset = max(0, (size.height - imageView.frame.height) / 2)   // half 2 center in screen
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
            
        view.layoutIfNeeded()
    }
    
    @objc
    func willZoom(gestureRecog: UITapGestureRecognizer) {
        if self.scrollView.zoomScale < 1.0 {
            self.scrollView.zoom(to:
                zoomRectForScale(scale: 2.0,
                                 center: gestureRecog.location(in: gestureRecog.view)),
                                 animated: true)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.updateMinZoomScaleForSize(self.view.bounds.size)
            }
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
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
    func showToast(message: String,
                   textColor: UIColor = UIColor.red,
                   backgroundColor: UIColor = UIColor.white) {
        let label = UILabel(frame:
            CGRect(x: view.frame.origin.x,
                   y: view.frame.height*0.9,
                   width: view.frame.width, height: 30))
        label.backgroundColor = backgroundColor
        label.clipsToBounds = true
        label.textAlignment = .center
        label.text = message
        label.textColor = textColor
        label.numberOfLines = 0
        view.addSubview(label)
        UIView.animate(withDuration: 2.0, delay: 1.0, animations: {
            label.alpha = 0
        }, completion: { _ in
            label.removeFromSuperview()
        })
    }
}

extension UINavigationBar {
    func setTransparent() {
        self.isTranslucent = true
        self.shadowImage = UIImage()
        self.backgroundColor = .clear
        let colors = [UIColor.black, UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0)]
        self.applyNavigationGradient(colors: colors)
    }
}

extension UINavigationBar {
    /// Applies a background gradient with the given colors
    func applyNavigationGradient( colors : [UIColor]) {
        var frameAndStatusBar: CGRect = self.bounds
        frameAndStatusBar.size.height += UIApplication.shared.statusBarFrame.height
        frameAndStatusBar.size.height += 120 // add 20 to account for the status bar
        
        setBackgroundImage(UINavigationBar.gradient(size: frameAndStatusBar.size, colors: colors), for: .default)
    }
    
    /// Creates a gradient image with the given settings
    static func gradient(size : CGSize, colors : [UIColor]) -> UIImage? {
        // Turn the colors into CGColors
        let cgcolors = colors.map { $0.cgColor }
        
        // Begin the graphics context
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        
        // If no context was retrieved, then it failed
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // From now on, the context gets ended if any return happens
        defer { UIGraphicsEndImageContext() }
        
        // Create the Coregraphics gradient
        var locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgcolors as NSArray as CFArray, locations: &locations) else { return nil }
        
        // Draw the gradient
        context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: [])
        
        // Generate the image (the defer takes care of closing the context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
