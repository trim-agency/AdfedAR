import UIKit

class FakeLaunchScreen: UIViewController {
    @IBOutlet weak var image: UIImageView!

    override func viewDidLoad() {
        waitAndSegue()
    }
    
    private func waitAndSegue() {
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(500), execute: {
            self.performSegue(withIdentifier: "segueToHome", sender: self)
        })
    }
}
