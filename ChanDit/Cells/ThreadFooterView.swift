import UIKit

protocol ThreadFooterViewDelegate: class {
    func threadFooterView(_ footer: ThreadFooterView, threadToNavigate number: Int)
    func toggleVisibility(section: Int)
}

class ThreadFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ThreadFooterView"
    var threadIsVisible: Bool = true
    var section: Int = 0
    
    weak var delegate: ThreadFooterViewDelegate?

    @IBOutlet weak var postsCount: UILabel!
    @IBOutlet weak var imagesCount: UILabel!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var closedIcon: UIImageView! {
        didSet {
            closedIcon.sd_setImage(with: URL(string: "https://s.4cdn.org/image/closed.gif")!)
        }
    }

    var threadToNavigate: Int!
        
    @IBAction func didTapButton(_ sender: AnyObject) {
        if threadIsVisible{
            delegate?.toggleVisibility(section: section)
        } else {
            delegate?.threadFooterView(self, threadToNavigate: threadToNavigate)
        }
    }
}
