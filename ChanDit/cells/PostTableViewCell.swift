//
//  PostTableViewCell.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 05/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit
import Kingfisher

class PostTableViewCell: UITableViewCell {
    
    var postViewModel: PostViewModel! {
        didSet {
            if postViewModel.thumbnailUrl(boardId: selectedBoardId) != nil {
                postImageSize.constant = 120
            } else {
                postImageSize.constant = 0
            }
        }
    }
    var selectedBoardId: String!
    @IBOutlet weak var postAuthorName: UILabel!
    @IBOutlet weak var postTimePublishing: UILabel!
    
    @IBOutlet weak var postImage: UIImageView! {
        didSet {
            postImage.clipsToBounds = true
            postImage.kf.indicatorType = .activity
        }
    }
    
    @IBOutlet weak var postCommentSize: NSLayoutConstraint!
    @IBOutlet weak var titleSize: NSLayoutConstraint!
    @IBOutlet weak var postText: UITextView!
    @IBOutlet weak var postImageSize: NSLayoutConstraint!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    @IBOutlet weak var mediaExtension: UILabel!
    @IBOutlet weak var mediaSize: UILabel!
    
    
    weak var tapDelegate: CellTapInteractionDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        postText.delegate = self
    }
    
    func loadCell() {
        postAuthorName.text = postViewModel.postAuthorName
        
        if let title = postViewModel.title, !title.isEmpty {
            titleSize.constant = 30.0
            postTitle.set(html: title)
            postTitle.text = "\(postTitle.text!)"
        } else {
            titleSize.constant = 0.0
        }
        
        postNumber.text = "No.\(postViewModel.number!)"
        postTimePublishing.text = postViewModel.timeFromPost
        
        //not good, needs to calculate size
        if let comment = postViewModel.comment, !comment.isEmpty {
            postText.set(html: postViewModel.comment)
            postCommentSize.constant = 81.0
        } else {
            postCommentSize.constant = 0.0
        }
        
        if !postViewModel.isSpoiler, let thumbUrl = postViewModel.thumbnailUrl(boardId: selectedBoardId) {
            postImage.kf.setImage(with: thumbUrl)
        } else {
            postImage.kf.setImage(with: URL(string: "https://s.4cdn.org/image/spoiler.png")!)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action:
            #selector(viewImage(tapGesture:)))
        postImage.addGestureRecognizer(tapGesture)
        postImage.isUserInteractionEnabled = true
        
        mediaSize.text = postViewModel.fileSize
        mediaExtension.text = postViewModel.mediaFullName
        
    }
    
    @objc func viewImage(tapGesture: UITapGestureRecognizer) {
        let ext = postViewModel.post.ext
        if ext == ".webm" {
            let viewController = PlaybackViewController(nibName: "PlaybackViewController", bundle: Bundle.main)
            viewController.mediaURL = postViewModel.imageUrl(boardId: selectedBoardId)
            tapDelegate?.imageTapped(viewController)
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
            viewController.boardId = selectedBoardId
            viewController.postViewModel = postViewModel
            tapDelegate?.imageTapped(viewController)
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
            } catch let e as NSError {
                print("Couldn't parse \(html): \(e.localizedDescription)")
            }
        }else{
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
            } catch let e as NSError {
                print("Couldn't parse \(html): \(e.localizedDescription)")
            }
        }else{
            self.text = ""
        }
    }
}

extension PostTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(URL.absoluteString)
        let quote = URL.absoluteString.split(separator: "/")
        if quote.first == "chandit:" {
            let postNumber = Int(quote.last!)
            tapDelegate?.linkTapped(postNumber: postNumber!, opNumber: postViewModel.resto!)
//            if parentViewController is BoardPagesViewController {
//                navigateToMessage(postNumber)
//                //jumpToPost(postNumber)
//            } else {
//                jumpToPost(postNumber)
//            }
        } else {
            //see https://stackoverflow.com/questions/39949169/swift-open-url-in-a-specific-browser-tab for other browsers deeplinks
            let actionOk = UIAlertAction(title: "OK", style: .default) { (action) in
                UIApplication.shared.open(URL)
            }
            let actionCancel = UIAlertAction(title: "Cancel", style: .default)
            tapDelegate?.presentAlertExitingApp([actionOk,actionCancel])
            
        }
        return false
    }
    
}


