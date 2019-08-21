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
    
    var postViewModel: PostViewModel? = nil
    @IBOutlet weak var postAuthorName: UILabel!
    @IBOutlet weak var postTimePublishing: UILabel!
    
    @IBOutlet weak var postImageSize: NSLayoutConstraint!
    
    @IBOutlet weak var postImage: UIImageView! {
        didSet {
            postImage.clipsToBounds = true
            postImage.kf.indicatorType = .activity
        }
    }
    
    @IBOutlet weak var postText: UITextView!
    //@IBOutlet weak var postText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        postText.delegate = self
    }
    
    func loadCell() {
        postAuthorName.text = postViewModel?.postAuthorName
        postTimePublishing.text = postViewModel?.timeFromPost
        postText.set(html: postViewModel?.comment)
        guard let thumbUrl = postViewModel?.thumbnailUrl else {
            self.postImageSize.constant = 0
            return
        }
        postImage.kf.setImage(with: thumbUrl) { result in
            self.postImageSize.constant = 120
        }
    }
    
//    override func prepareForReuse() {
//        postImage.image = nil
//    }
}


extension UITextView {
    func set(html: String?) {
        if let html = html, let htmlData = html.data(using: .unicode) {
            do {
                self.attributedText = try NSAttributedString(data: htmlData,
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
        //UIApplication.shared.open(URL)
        return false
    }
}


