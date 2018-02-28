import UIKit

class FakeLaunchScreen: UIViewController {
    @IBOutlet weak var image: UIImageView!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        waitAndSegue()
    }
    
    private func waitAndSegue() {
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(500), execute: {
            self.performSegue(withIdentifier: "segueToWalkthrough", sender: self)
        })
    }
}
