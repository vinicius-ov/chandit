//
//  ImageViewerViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 27/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import Photos

class ImageViewerViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(willDismiss))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        imageViewWidth.constant = postViewModel.imageWidth ?? 0.0
        imageViewHeight.constant = postViewModel.imageWidth ?? 0.0
        
        imageView.kf.setImage(with: postViewModel.imageUrl(boardId: boardId)) { result in
            switch result {
            case .success(let image):
                self.imageView.image = image.image
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveImage))
            case .failure(let failure):
                break
            }
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @objc
    func willDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveImage() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        guard let img = self.imageView.image else { return }
        //UIImageWriteToSavedPhotosAlbum(img, self, #selector(showSuccessToast(_:error:contextInfo:)),nil)
        if PHPhotoLibrary.authorizationStatus() == .authorized {
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAsset(from: img)
//            }, completionHandler: {
//                success, error in
//                print(success)
//            })
            let url = self.postViewModel.imageUrl(boardId: self.boardId)!
//            PHPhotoLibrary.shared().performChanges({
//                let request = PHAssetCreationRequest.forAsset()
//                request.addResource(with: .photo, fileURL: url, options: nil)
//            }) { (success, error) in
//                print(success)
//            }
            let data = try? Data(contentsOf:  url)
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data!, options: nil)
            })
        } else {
            //show alert to prompt user to go to settings and change authorization status
        }
        }
    
    @objc func showSuccessToast(_ image:UIImage, error:Error?, contextInfo: UnsafeMutableRawPointer?) {
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.showToast(message: "Photo was saved to the camera roll.", textColor: nil, backgroundColor: nil)
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

    fileprivate func updateConstraintsForSize(_ size: CGSize) {
        
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
    func showToast(message:String, textColor: UIColor?, backgroundColor: UIColor?) {
        let label = UILabel(frame: CGRect(x: 0, y: view.frame.height*0.9, width: view.frame.width, height: 25))
        label.backgroundColor = backgroundColor ?? .red
        label.textAlignment = .center
        label.text = message
        label.textColor = textColor ?? .white
        view.addSubview(label)
        UIView.animate(withDuration: 2.0, delay: 1.0, animations: {
            label.alpha = 0
        }) { finished in
            label.removeFromSuperview()
        }
    }
}
