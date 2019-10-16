
import UIKit

protocol ThreadFooterViewDelegate: class {
    func threadFooterView(_ footer: ThreadFooterView, didTapButtonInSection section: Int)
}

class ThreadFooterView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ThreadFooterView"

    weak var delegate: ThreadFooterViewDelegate?

    @IBOutlet weak var postsCount: UILabel!
    @IBOutlet weak var imagesCount: UILabel!

    var threadToNavigate: Int!
        
    @IBAction func didTapButton(_ sender: AnyObject) {
        //delegate?.customHeader(self, didTapButtonInSection: section)
    }
}
