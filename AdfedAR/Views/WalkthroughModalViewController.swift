import UIKit

class WalkthroughModalViewController: UIViewController {

    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var walkthroughContainerView: UIView!
    @IBAction func didTapDismiss(_ sender: Any) {
        (self.presentingViewController as! HomeViewController).didDismissWalkthrough()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    'm}
}
