import UIKit

class WalkthroughViewController: UIViewController {
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var letsGoButton: UIButton!
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var logoStack: UIStackView!
    @IBAction func didTapLetsGo(_ sender: Any) {
        performSegue(withIdentifier: "segueToHome", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instructionLabel.sizeToFit()
        mainStack.setCustomSpacing(60, after: logoStack)
        setupLetsGoButton()
        setupGradient()
    }
    
    private func setupLetsGoButton() {
        letsGoButton.imageView?.transform = CGAffineTransform(scaleX: -1, y: 1)
        let margin                      = CGFloat(5.0)
        letsGoButton.titleEdgeInsets    = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
        letsGoButton.imageEdgeInsets    = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        letsGoButton.contentEdgeInsets  = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: margin)
    }
    
    private func setupGradient() {
        let gradient    = CAGradientLayer()
        gradient.frame  = view.frame
        let topColor    = UIColor(red: 0.431, green: 0.773, blue: 0.765, alpha: 1.00).cgColor
        let bottomColor = UIColor(red: 0.420, green: 0.604, blue: 0.820, alpha: 1.00).cgColor
        gradient.colors = [topColor, bottomColor]
        view.layer.insertSublayer(gradient, at: 0)
    }
}
