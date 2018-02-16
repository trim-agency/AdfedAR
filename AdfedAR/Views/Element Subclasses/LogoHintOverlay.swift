import UIKit
import SnapKit

class LogoHintOverlay: UIView {
    @IBOutlet weak var bestOfShow   = UIImageView()
    @IBOutlet weak var judgesChoice = UIImageView()
    @IBOutlet weak var winnerView: UIImageView!
    var isPageDetected = false
   
    override func awakeFromNib() {
        super.awakeFromNib()
        bestOfShow?.tintColor   = UIColor.white
        judgesChoice?.tintColor = UIColor.white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bestOfShow?.alpha = 0.0
        judgesChoice?.alpha = 0.0
        self.alpha = 0
        Animator.fade(view: self, to: 1.0, for: 2.0, completion: {
            self.animateRune(alpha: 1.0, length: 1.5)
        })
    }
    
    func selectRune(_ page: Page) {
        isPageDetected = true
        removeAnimations()
        page == .bestOfShow ? glowSymbol(bestOfShow!, page: page) : glowSymbol(judgesChoice!, page: page)
    }
    
    private func removeAnimations() {
        DispatchQueue.main.async {
            self.judgesChoice?.layer.removeAllAnimations()
            self.bestOfShow?.layer.removeAllAnimations()
        }
    }

    func pulse<T: UIView>(view: T, for length: Double, to alpha: CGFloat ) {
        if !isPageDetected {
            UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseOut], animations: {
                view.alpha = 1.0
            }) { (finished) in
                UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseOut], animations: {
                    view.alpha = 0.2
                }, completion: {(finished) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
                        self.pulse(view: view, for: length, to: 1.0)
                    })
                })
            }
        }
    }

    private func glowSymbol(_ imageView: UIImageView, page: Page) {
        DispatchQueue.main.async {
            let image                   = page == .judgesChoice ? #imageLiteral(resourceName: "judges-choice-rune") : #imageLiteral(resourceName: "best-of-show-rune")
            self.winnerView.image       = image
            self.winnerView.tintColor   = UIColor(red:0.75, green:0.65, blue:0.30, alpha:1.0)
            self.winnerView.isHidden    = false
            Animator.fade(view: self.winnerView, to: 0.0, for: 5, options: [UIViewAnimationOptions.curveEaseIn], completion: nil)
        }
    }

    // MARK: - Rune
    private func animateRune(alpha: CGFloat, length: Double) {
        pulse(view: bestOfShow!, for: length, to: alpha)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
            self.pulse(view: self.judgesChoice!, for: length, to: alpha)
        }
    }
}
