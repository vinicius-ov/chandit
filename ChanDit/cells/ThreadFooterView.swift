
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
    
    var threadToNavigate: Int!
        
    @IBAction func didTapButton(_ sender: AnyObject) {
        delegate?.threadFooterView(self, threadToNavigate: threadToNavigate)
    }
}
