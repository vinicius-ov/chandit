//
//  PostTableViewCell.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 05/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import SDWebImage

class PostTableViewCell: UITableViewCell {
    var postViewModel: PostViewModel!
    var selectedBoardId: String!
    
    @IBOutlet weak var postAuthorName: UILabel!
    @IBOutlet weak var postTimePublishing: UILabel!
    
    @IBOutlet weak var postImage: UIImageView! {
        didSet {
            postImage.sd_imageIndicator = SDWebImageActivityIndicator.whiteLarge
            postImage.sd_imageIndicator?.startAnimatingIndicator()
        }
    }
    
    @IBOutlet weak var postText: UITextView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    @IBOutlet weak var mediaExtension: UILabel!
    @IBOutlet weak var mediaSize: UILabel!
    
    weak var tapDelegate: CellTapInteractionDelegate?
    var tappedUrl: URL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        postText.delegate = self
    }
    
    func loadCell() {
        postAuthorName.text = postViewModel.postAuthorName
        
        if let title = postViewModel.title {
            postTitle.set(html: title)
        } else {
            postTitle.text = ""
        }
        
        postNumber.text = "No.\(postViewModel.number!)"
        postTimePublishing.text = postViewModel.timeFromPost
        
        if let comment = postViewModel.comment {
            postText.set(html: comment)
        } else {
            postText.text = ""
        }
        
        if postViewModel.isSpoiler {
            postImage.sd_setImage(with: postViewModel.spoilerUrl)
        } else {
            if let thumbUrl = postViewModel.thumbnailUrl(boardId: selectedBoardId) {
                postImage.sd_setImage(with: thumbUrl)
                //thumbSizeConstraint?.constant = 160
                postImage.isHidden = false
                postImage.addGestureRecognizer(
                UITapGestureRecognizer(target: self,
                                       action: #selector(viewImage(_:))))
            } else {
                postImage.gestureRecognizers?.removeAll()
                postImage.isHidden = true
                postImage.image = nil
            }
        }
        
        postText.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tappedLink(_:))))
        
        mediaSize.text = postViewModel.fileSize
        mediaExtension.text = postViewModel.mediaFullName
    }
    
    var thumbSizeConstraint: NSLayoutConstraint? {
        return postImage.constraint(withIdentifier: "thumbnail_size")
    }
    
    @objc func viewImage(_ sender: Any) {
        let ext = postViewModel.post.ext
        if ext == ".webm" {
            let viewController = PlaybackViewController(nibName: "PlaybackViewController", bundle: Bundle.main)
            viewController.mediaURL = postViewModel.imageUrl(boardId: selectedBoardId)
            tapDelegate?.imageTapped(viewController)
        } else {
            let viewController = ImageViewerViewController(nibName: "ImageViewerViewController", bundle: Bundle.main)
            viewController.boardId = selectedBoardId
            viewController.postViewModel = postViewModel
            tapDelegate?.imageTapped(viewController)
        }
    }
    
    @objc
    func tappedLink(_ sender: Any) {
        guard let tappedUrl = tappedUrl else { return }
        let quote = tappedUrl.absoluteString.split(separator: "/")
        if quote.first == "chandit:" {
            let postNumber = Int(quote.last!)
            tapDelegate?.linkTapped(postNumber: postNumber!, opNumber: postViewModel.resto!)
        } else {
            //see https://stackoverflow.com/questions/39949169/swift-open-url-in-a-specific-browser-tab for other browsers deeplinks
            let actionOk = UIAlertAction(title: "OK", style: .default) { (_) in
                UIApplication.shared.open(URL(string: "firefox://open-url?url=\(tappedUrl)")!)
            }
            let actionCancel = UIAlertAction(title: "Cancel", style: .default)
            tapDelegate?.presentAlertExitingApp([actionOk, actionCancel])
        }
    }
}

extension UILabel {
    func set(html: String?) {
        if let html = html, let htmlData = html.data(using: .unicode) {
            do {
                self.attributedText =
                    try NSAttributedString(data: htmlData,
                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                           documentAttributes: nil)
                self.font = UIFont.systemFont(ofSize: 14.0)
                self.textColor = UIColor.white
            } catch let error as NSError {
                print("Couldn't parse \(html): \(error.localizedDescription)")
            }
        } else {
            self.text = ""
        }
    }
}

extension UITextView {
    func set(html: String?) {
        if let html = html, let htmlData = html.data(using: .unicode) {
            do {
                self.attributedText =
                    try NSAttributedString(data: htmlData,
                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                           documentAttributes: nil)
                self.font = UIFont.systemFont(ofSize: 17.0)
                self.textColor = UIColor.white
            } catch let error as NSError {
                print("Couldn't parse \(html): \(error.localizedDescription)")
            }
        }else{
            self.text = ""
        }
    }
}

extension PostTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        tappedUrl = URL
        return false
    }
}

extension UIView {
    func constraint(withIdentifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter { $0.identifier == withIdentifier }.first
    }
}
