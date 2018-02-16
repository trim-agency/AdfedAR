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
        Animator.fade(view: self, to: 1.0, for: 2.0, completion: {
            self.animateRune(alpha: 1.0, length: 3)
        })
    }
    
    func selectRune(_ page: Page) {
        isPageDetected = true
        removeAnimations()
//        Animator.stopAnimations(views: [bestOfShow!, judgesChoice!])
        if page == .bestOfShow {
            glowSymbol(bestOfShow!, page: page)
            Animator.fade(view: bestOfShow!, to: 1.0, for: 2.0, options: [UIViewAnimationOptions.curveEaseInOut], completion: nil)
        } else {
            glowSymbol(judgesChoice!, page: page)
            Animator.fade(view: judgesChoice!, to: 1.0, for: 2.0, options: [UIViewAnimationOptions.curveEaseInOut], completion: nil)
        }
    }
    
    private func removeAnimations() {
        DispatchQueue.main.async {
            self.judgesChoice?.layer.removeAllAnimations()
            self.bestOfShow?.layer.removeAllAnimations()
        }
    }

    func pulse<T: UIView>(view: T, for length: Double, to alpha: CGFloat ) {
        UIView.animate(withDuration: length, delay: 0, options: [.autoreverse, .curveEaseInOut, .repeat], animations: {
            view.alpha = alpha
        }, completion: { (finished) in
            Animator.fade(view: view, to: 0.0, for: 2.0, completion: nil)
        })
    }
    
    private func glowSymbol(_ imageView: UIImageView, page: Page) {
        DispatchQueue.main.async {
            let image                   = page == .judgesChoice ? #imageLiteral(resourceName: "judges-choice-rune") : #imageLiteral(resourceName: "best-of-show-rune")
            self.winnerView.image       = image
            self.winnerView.tintColor   = UIColor(red:0.75, green:0.65, blue:0.30, alpha:1.0)
            self.winnerView.isHidden    = false
            Animator.fade(view: self.winnerView, to: 0.0, for: 10, options: [UIViewAnimationOptions.curveEaseIn], completion: nil)
        }
    }

    // MARK: - Rune
    private func animateRune(alpha: CGFloat, length: Double) {
        pulse(view: bestOfShow!, for: length, to: alpha)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            self.pulse(view: self.judgesChoice!, for: length, to: alpha)
        }
    }
}
