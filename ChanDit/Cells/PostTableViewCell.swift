//
//  PostTableViewCell.swift
//  ChanDit
//
//  Created by Vinicius Valvassori on 05/08/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//  swiftlint:disable trailing_whitespace

import UIKit
import SDWebImage

//TODO: remember to edit both postCell xibs when modifing stuff
class PostTableViewCell: UITableViewCell {
    var postViewModel: PostViewModel!
    var selectedBoardId: String!
    var boardName = "Im Error"
    var isNsfw = true

    var viewForReset: UIView!
    
    @IBOutlet weak var postAuthorName: UILabel!
    @IBOutlet weak var postTimePublishing: UILabel!
    @IBOutlet weak var imageSizeConstraint: NSLayoutConstraint?
    //@IBOutlet weak var titleSizeConstraint: NSLayoutConstraint?
    @IBOutlet weak var quotedByHeight: NSLayoutConstraint?

    @IBOutlet weak var postImage: UIImageView? {
        didSet {
            postImage?.sd_imageIndicator = SDWebImageActivityIndicator.whiteLarge
            postImage?.sd_imageIndicator?.startAnimatingIndicator()
        }
    }
    
    @IBOutlet weak var flagIcon: UIImageView!
    @IBOutlet weak var postText: UITextView!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postNumber: UILabel!
    @IBOutlet weak var mediaExtension: UILabel?
    @IBOutlet weak var mediaSize: UILabel?
    @IBOutlet weak var quotedBys: UITextView?
    
    
    @IBOutlet weak var stickyIcon: UIImageView! {
        didSet {
            stickyIcon.sd_setImage(with: URL(string: "https://s.4cdn.org/image/sticky.gif")!)
        }
    }
    
    weak var tapDelegate: CellTapInteractionDelegate?
    weak var toastDelegate: ToastDelegate?
    weak var hideDelegate: HideDelegate?

    func setupPostHeader() {
        postAuthorName.text = postViewModel.postAuthorName
        postNumber.text = "No.\(postViewModel.number!)"
        postTimePublishing.text = postViewModel.timeFromPost
        let flag = postViewModel.flagCountryCode
        if let flagUrl = URL(string: "https://s.4cdn.org/image/country/\(flag).gif") {
            flagIcon.sd_setImage(with: flagUrl)
        }
        flagIcon.addGestureRecognizer(
        UITapGestureRecognizer(target: self,
                               action: #selector(showFlagHint(_:))))

        stickyIcon.isHidden = !postViewModel.isPinned
    }

    func loadCell() {
        if let title = postViewModel.title {
            postTitle.attributedText = title.toPlainText(fontSize: 14)
            //titleSizeConstraint?.constant = 17
        } else {
            postTitle.text = ""
            //titleSizeConstraint?.constant = 0
        }

        setupPostHeader()

        if let comment = postViewModel.comment {
            postText.attributedText = comment.toPlainText(postViewModel: postViewModel)
        } else {
            postText.attributedText = NSAttributedString(string: "")
        }

        if postViewModel.quoted.isEmpty {
            quotedBys?.frame.size = CGSize(width: 0, height: 0)
            print(quotedBys?.frame.size)

        } else {
            quotedBys?.attributedText = postViewModel.quotedAsHtml.toPlainText(fontSize: 12,
                                                                               postViewModel: nil)

        }

        if postViewModel.isSpoiler {
            postImage?.sd_setImage(with: postViewModel.spoilerUrl)
            mediaExtension?.text = "Spoiler Image"
        } else {
            if let thumbUrl = postViewModel.thumbnailUrl(boardId: selectedBoardId) {
                postImage?.sd_setImage(with: thumbUrl,
                                      completed: { (_, error, _, _) in
                                        if error != nil {
                                            self.postImage?.sd_setImage(with:
                                                URL(string: "https://s.4cdn.org/image/filedeleted-res.gif")!)
                                        }
                    })
                //postImage?.isHidden = false
                imageSizeConstraint?.constant = 160
                mediaExtension?.text = postViewModel.mediaFullName
            } else {
                //postImage?.isHidden = true
                imageSizeConstraint?.constant = 0
                postImage?.image = nil
            }
        }

        mediaSize?.text = postViewModel.fileSize

        setupGestureRecognizers()

        let copyDoubleTap = UITapGestureRecognizer(target: self,
        action: #selector(copyToClipBoard(_:)))
        copyDoubleTap.numberOfTapsRequired = 2
        postText.addGestureRecognizer(copyDoubleTap)
    }

    private func setupGestureRecognizers() {
        postImage?.addGestureRecognizer(
        UITapGestureRecognizer(target: self,
                               action: #selector(viewImage(_:))))

        postText.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tappedLink(_:))))

        quotedBys?.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tappedLink(_:))))
    }

    @objc
    func copyToClipBoard(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let comment = postViewModel.comment else { return }
        UIPasteboard.general.string = comment.toPlainText().string
        toastDelegate?.showToastForCopy(text: "Pasta added to clipboard")
    }

    @objc
    func viewImage(_ sender: Any) {
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
        toastDelegate?.showToast(flagHint: postViewModel.countryName)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {

        print(URL.absoluteString)
        //UIApplication.shared.open(URL)
        return false
    }
    
    @objc
    func tappedLink(_ tapGesture: UITapGestureRecognizer) {

        guard let textView: UITextView = tapGesture.view as? UITextView else { return }
        let tapLocation = tapGesture.location(in: tapGesture.view)

        guard var linkString = getTappedLink(from: textView, in: tapLocation) else { return }

        if linkString.contains("applewebdata") {
            let comps = linkString.components(separatedBy: "chandit")
            linkString = "chandit" + (comps.last ?? "")
        }

        if !linkString.isEmpty {
            let quote = linkString.split(separator: "/")

            if quote.first == "chandit:" {

                guard let postNumber = Int(quote.last ?? ""),
                    let resto = postViewModel.resto,
                    let number = postViewModel.number else { return }

                tapDelegate?.linkTapped(postNumber: postNumber,
                                        opNumber: resto,
                                        originNumber: number)
            } else {
                let actionOk = UIAlertAction(title: "OK", style: .default) { (_) in
                    if UIApplication.shared.canOpenURL(URL(string: "firefox://open-url?url=\(linkString)")!) {
                        UIApplication.shared.open(URL(string: "firefox://open-url?url=\(linkString)")!)
                    } else {
                        UIApplication.shared.open(URL(string: linkString)!)
                    }

                }
                let actionCancel = UIAlertAction(title: "Cancel", style: .default)
                tapDelegate?.presentAlertExitingApp([actionOk, actionCancel])
            }
        }
    }

    private func getTappedLink(from textView: UITextView, in tapLocation: CGPoint) -> String? {
        var textPosition1 = textView.closestPosition(to: tapLocation)
        var textPosition2: UITextPosition?

        if nil != textPosition1 {
            textPosition2 = textView.position(from: textPosition1!, offset: 1)

            if nil != textPosition2 {
                textPosition1 = textView.position(from: textPosition1!, offset: -1)
                textPosition2 = textView.position(from: textPosition1!, offset: 1)
            } else {
                return nil
            }
        }

        let range = textView.textRange(from: textPosition1!, to: textPosition2!)
        let startOffset = textView.offset(from: textView.beginningOfDocument,
                                          to: range!.start)

        let endOffset = textView.offset(from: textView.beginningOfDocument,
                                        to: range!.end)

        let offsetRange = NSRange(location: startOffset,
                                  length: endOffset - startOffset)

        if offsetRange.location == NSNotFound || offsetRange.length == 0 {
            return nil
        }

        if NSMaxRange(offsetRange) > textView.attributedText.length {
            return nil
        }

        let attributedSubstring = textView.attributedText.attributedSubstring(from: offsetRange)
        let link = attributedSubstring.attribute(NSAttributedString.Key.link, at: 0, effectiveRange: nil)

        return "\(link ?? "")"
    }

    @IBAction func togglePostVisibility() {
        if postViewModel.isOp {
            hideDelegate?.hideThread(number: postViewModel.number ?? 0)
        } else {
            hideDelegate?.hidePost(number: postViewModel.number ?? 0)
        }
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
