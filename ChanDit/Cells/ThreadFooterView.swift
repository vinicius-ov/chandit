import UIKit

protocol ThreadFooterViewDelegate: class {
    func threadFooterView(_ footer: ThreadFooterView, threadToNavigate number: Int)
}

class ThreadFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ThreadFooterView"

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
        delegate?.threadFooterView(self, threadToNavigate: threadToNavigate)
    }
}
