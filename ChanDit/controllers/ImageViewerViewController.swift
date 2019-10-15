//
//  ImageViewerViewController.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 27/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import Photos
import Kingfisher

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
        imageView.kf.setImage(with: postViewModel.imageUrl(boardId: boardId))
        { result in
            switch result {
            case .success(let image):
                //self.updateMinZoomScaleForSize(self.view.bounds.size)
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveImage))
            case .failure(let failure):
                break
            }
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @objc func saveImage() {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        guard let img = self.imageView.image else { return }
        PHPhotoLibrary.requestAuthorization( { (PHAuthorizationStatus) in
            //empty
        })
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            let url = self.postViewModel.imageUrl(boardId: self.boardId)!
            let data = try? Data(contentsOf:  url)
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data!, options: nil)
            }) { (success, error) in
                if success {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.showSuccessToast()
                }
            }
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.showToast(message: "Not authorized to save images in Camera Roll. Go to Settings to fix this.", textColor: nil, backgroundColor: nil)
        }
    }
    
    func showSuccessToast() {
        DispatchQueue.main.async {
            self.showToast(message: "Photo was saved to the camera roll.", textColor: UIColor.black, backgroundColor: UIColor(named: "lightGreenSuccess"))
        }
    }
    
    fileprivate func updateMinZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
        print("---")
        print(imageView.bounds)
        print("\(widthScale) - \(heightScale) - \(minScale)")
        print("---")
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
        label.numberOfLines = 0
        label.sizeToFit()
        view.addSubview(label)
        UIView.animate(withDuration: 2.0, delay: 1.0, animations: {
            label.alpha = 0
        }) { finished in
            label.removeFromSuperview()
        }
    }
}
