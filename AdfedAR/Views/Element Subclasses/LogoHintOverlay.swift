import UIKit
import SnapKit

class LogoHintOverlay: UIView {
    @IBOutlet weak var bestOfShow   = UIImageView()
    @IBOutlet weak var judgesChoice = UIImageView()

    
    convenience init() {
        self.init()
        defineVisualAttributes()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        Animator.fade(view: self, to: 1.0, for: 2.0, completion: {
            self.animateRune(alpha: 0.05, length: 3)
        })
    }
    

    // MARK: - Layout
    private func defineVisualAttributes() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    

    // MARK: - Rune
    private func animateRune(alpha: CGFloat, length: Double) {
        Animator.pulse(view: bestOfShow!, for: length, to: alpha)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            Animator.pulse(view: self.judgesChoice!, for: length, to: alpha)
        }
    }
}
