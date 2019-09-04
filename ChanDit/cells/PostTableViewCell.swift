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
    
    @objc var imageViewSelector: ((UITapGestureRecognizer) -> Void)!
    var parentViewController: UIViewController!
    
    @IBOutlet weak var postText: UITextView!
    @IBOutlet weak var postImageSize: NSLayoutConstraint!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    
    var navigateToMessage: ((Int?) -> Void)!
    var jumpToPost: ((Int?) -> Void)!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        postText.delegate = self
    }
    
    func loadCell() {
        postAuthorName.text = postViewModel.postAuthorName
        
        postTitle.set(html: postViewModel.title)
        
        postNumber.text = "No.\(postViewModel.number!)"
        postTimePublishing.text = postViewModel.timeFromPost
        postText.set(html: postViewModel.comment)
        
        if !postViewModel.isSpoiler, let thumbUrl = postViewModel.thumbnailUrl(boardId: selectedBoardId) {
            postImage.kf.setImage(with: thumbUrl)
        } else {
            postImage.image = UIImage(named: "spoiler")
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action:
            #selector(viewImage(tapGesture:)))
        postImage.addGestureRecognizer(tapGesture)
        postImage.isUserInteractionEnabled = true
        
    }
    
    @objc func viewImage(tapGesture: UITapGestureRecognizer) {
        let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
        viewController.boardId = selectedBoardId
        viewController.postViewModel = postViewModel
        //viewController.modalPresentationStyle = .pageSheet
        parentViewController.navigationController?.pushViewController(viewController, animated: true)
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
//        print(URL.absoluteString)
        let quote = URL.absoluteString.split(separator: "/")
        let postNumber = Int(quote[2])
        if parentViewController is BoardPagesViewController {
            navigateToMessage(postNumber)
            //jumpToPost(postNumber)
        } else {
            jumpToPost(postNumber)
        }
        return false
    }
}


