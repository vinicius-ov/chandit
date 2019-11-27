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
    var boardName = "Im Error"
    
    @IBOutlet weak var postAuthorName: UILabel!
    @IBOutlet weak var postTimePublishing: UILabel!
    @IBOutlet weak var savePastaButton: UIButton!
    
    @IBOutlet weak var postImage: UIImageView! {
        didSet {
            postImage.sd_imageIndicator = SDWebImageActivityIndicator.whiteLarge
            postImage.sd_imageIndicator?.startAnimatingIndicator()
        }
    }
    
    @IBOutlet weak var flagIcon: UIImageView!
    @IBOutlet weak var postText: UITextView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    @IBOutlet weak var mediaExtension: UILabel!
    @IBOutlet weak var mediaSize: UILabel!
    
    @IBOutlet weak var stickyIcon: UIImageView! {
        didSet {
            stickyIcon.sd_setImage(with: URL(string: "https://s.4cdn.org/image/sticky.gif")!)
        }
    }
    
    weak var tapDelegate: CellTapInteractionDelegate?
    weak var flagDelegate: ToastDelegate?
    weak var copyTextDelegate: SaveTextDelegate?
    weak var hideDelegate: HideDelegate?

    func loadCell() {
        postAuthorName.text = postViewModel.postAuthorName
        
        if let title = postViewModel.title {
            postTitle.attributedText = title.toPlainText(fontSize: 14)
        } else {
            postTitle.text = ""
        }
        
        postNumber.text = "No.\(postViewModel.number!)"
        postTimePublishing.text = postViewModel.timeFromPost
        
        if let comment = postViewModel.comment {
            postText.attributedText = comment.toPlainText()
        } else {
            postText.text = ""
        }
        
        let flag = postViewModel.flagCountryCode
        if let flagUrl = URL(string: "https://s.4cdn.org/image/country/\(flag).gif") {
            flagIcon.sd_setImage(with: flagUrl)
        }
        
        if postViewModel.isSpoiler {
            postImage.sd_setImage(with: postViewModel.spoilerUrl)
        } else {
            if let thumbUrl = postViewModel.thumbnailUrl(boardId: selectedBoardId) {
                postImage.sd_setImage(with: thumbUrl,
                                      completed: { (_, error, _, _) in
                                        if error != nil {
                                            self.postImage.sd_setImage(with:
                                                URL(string: "https://s.4cdn.org/image/filedeleted-res.gif")!)
                                        }
                    })
                postImage.isHidden = false
            } else {
                postImage.gestureRecognizers?.removeAll()
                postImage.isHidden = true
                postImage.image = nil
            }
        }
        
        postImage.addGestureRecognizer(
        UITapGestureRecognizer(target: self,
                               action: #selector(viewImage(_:))))
        postText.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tappedLink(_:))))
        flagIcon.addGestureRecognizer(
        UITapGestureRecognizer(target: self,
                               action: #selector(showFlagHint(_:))))
        
        mediaSize.text = postViewModel.fileSize
        mediaExtension.text = postViewModel.mediaFullName
        
        stickyIcon.isHidden = !postViewModel.isPinned
    }
    
    var thumbSizeConstraint: NSLayoutConstraint? {
        return postImage.constraint(withIdentifier: "thumbnail_size")
    }
    
    @objc func viewImage(_ sender: Any) {
        let ext = postViewModel.post.ext
        if ext == ".webm" {
            let viewController = PlaybackViewController(nibName: "PlaybackViewController", bundle: Bundle.main)
            viewController.mediaURL = postViewModel.imageUrl(boardId: selectedBoardId)
            viewController.postNumber = self.postViewModel.number ?? 0
            viewController.filename = postViewModel.mediaFullName ?? "im error"
            tapDelegate?.imageTapped(viewController)
        } else {
            let viewController = ImageViewerViewController(nibName: "ImageViewerViewController", bundle: Bundle.main)
            viewController.boardId = selectedBoardId
            viewController.postViewModel = postViewModel
            viewController.completeBoardName = boardName
            tapDelegate?.imageTapped(viewController)
        }
    }
    
    @objc
    func showFlagHint(_ sender: Any) {
        flagDelegate?.showToast(flagHint: postViewModel.countryName)
    }
    
    @objc
    func tappedLink(_ tapGesture: UITapGestureRecognizer) {

        guard let textView: UITextView = tapGesture.view as? UITextView else { return }
        let tapLocation = tapGesture.location(in: tapGesture.view)
        
        var textPosition1 = textView.closestPosition(to: tapLocation)
        var textPosition2: UITextPosition?
        if nil != textPosition1 {
            textPosition2 = textView.position(from: textPosition1!, offset: 1)
            if nil != textPosition2 {
                textPosition1 = textView.position(from: textPosition1!, offset: -1)
                textPosition2 = textView.position(from: textPosition1!, offset: 1)
            } else {
                return
            }
        }
        
        let range = textView.textRange(from: textPosition1!, to: textPosition2!)
        let startOffset = textView.offset(from: textView.beginningOfDocument,
                                          to: range!.start)
        let endOffset = textView.offset(from: textView.beginningOfDocument,
                                        to: range!.end)
        let offsetRange = NSRange(location: startOffset, length: endOffset - startOffset)
        if offsetRange.location == NSNotFound || offsetRange.length == 0 {
            return
        }
        
        if NSMaxRange(offsetRange) > textView.attributedText.length {
            return
        }
        
        let attributedSubstring = textView.attributedText .attributedSubstring(from: offsetRange)
        let link = attributedSubstring.attribute(NSAttributedString.Key.link, at: 0, effectiveRange: nil)

        let linkString = "\(link ?? "")"
        let quote = linkString.split(separator: "/")
        if quote.first == "chandit:" {
            let postNumber = Int(quote.last!)
            tapDelegate?.linkTapped(postNumber: postNumber!,
                                    opNumber: postViewModel.resto!,
                                    originNumber: postViewModel.number!)
        } else {
            //see https://stackoverflow.com/questions/39949169/swift-open-url-in-a-specific-browser-tab for other browsers deeplinks
            let actionOk = UIAlertAction(title: "OK", style: .default) { (_) in
                UIApplication.shared.open(URL(string: "firefox://open-url?url=\(linkString)")!)
            }
            let actionCancel = UIAlertAction(title: "Cancel", style: .default)
            tapDelegate?.presentAlertExitingApp([actionOk, actionCancel])
        }
    }

    @IBAction func togglePostVisibility() {
        if postViewModel.isOp {
            hideDelegate?.hideThread(number: postViewModel.number ?? 0)
        } else {
            hideDelegate?.hidePost(number: postViewModel.number ?? 0)
        }
    }
}

extension String {
    func toPlainText(fontSize: CGFloat? = 17) -> NSAttributedString {
        var attribText = NSMutableAttributedString(string: "")
        if let htmlData = self.data(using: .unicode) {
            do {
                attribText =
                    try NSMutableAttributedString(data: htmlData,
                                           options: [.documentType: NSAttributedString.DocumentType.html],
                                           documentAttributes: nil)
                attribText.addAttributes([.foregroundColor: UIColor.white,
                                          .font: UIFont.systemFont(ofSize: fontSize!)],
                                         range: NSRange(location: 0, length: attribText.mutableString.length))
            } catch let error as NSError {
                print("Couldn't parse \(self): \(error.localizedDescription)")
            }
        }
        return attribText
    }
}

extension UIView {
    func constraint(withIdentifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter { $0.identifier == withIdentifier }.first
    }
}

protocol CompleteBoardNameProtocol {
    var completeBoardName: String { get set }
}

extension PostTableViewCell {
    @IBAction func savePasta() {
//        let a = UIActivityViewController()
//        self.
    }
}
