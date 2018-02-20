import UIKit
import SnapKit

class LogoHintOverlay: UIView {
    @IBOutlet weak var bestOfShow           = UIImageView()
    @IBOutlet weak var judgesChoice         = UIImageView()
    @IBOutlet weak var winnerView: UIImageView!
    var isPageDetected = false
   
    override func awakeFromNib() {
        super.awakeFromNib()
        bestOfShow?.tintColor   = UIColor.white
        judgesChoice?.tintColor = UIColor.white
       
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.animateRune(startAlpha: 0.80, to: 0, for: 1.25)
        }
    }

    private func setInitialAlpha(){
        bestOfShow?.alpha   = 1.0
        judgesChoice?.alpha = 0.1
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

    func restartPulsing() {
        isPageDetected = false
        Animator.fade(view: bestOfShow!, to: 1.0, for: 1.0, options: [.curveEaseOut], completion: nil)
        Animator.fade(view: judgesChoice!, to: 0.1, for: 1.0, options: [.curveEaseOut]) {
            self.animateRune(startAlpha: 1.0, to: 0.1, for: 1.25)
        }
    }
    
    func pulse<T: UIView>(view: T, for length: Double, startAlpha: CGFloat, endAlpha: CGFloat) {
        if !isPageDetected {
            Animator.fade(view: view, to: startAlpha, for: length, options: [.curveEaseOut], completion: {
                Animator.fade(view: view, to: endAlpha, for: length, options: [.curveEaseOut], completion: {
                    self.pulse(view: view, for: length, startAlpha: startAlpha, endAlpha: endAlpha )
                })
            })
        } else {
            Animator.fade(view: view, to: 0, for: 1.0, options: [.curveEaseInOut], completion: nil)
        }
    }
    
    private func glowSymbol(page: Page) {
        DispatchQueue.main.async {
            let image                   = page == .judgesChoice ? #imageLiteral(resourceName: "judges-choice-rune") : #imageLiteral(resourceName: "best-of-show-rune")
            self.winnerView.image       = image
            self.winnerView.tintColor   = UIColor(red:0.75, green:0.65, blue:0.30, alpha:1.0)
            self.winnerView.isHidden    = false
            Animator.fade(view: self.winnerView, to: 0.0, for: 3, options: [UIViewAnimationOptions.curveEaseIn], completion: nil)
        }
    }

    // MARK: - Rune
    func animateRune(startAlpha: CGFloat, to endAlpha: CGFloat, for length: Double) {
        isHidden = false
        pulse(view: bestOfShow!, for: length, startAlpha: startAlpha, endAlpha: endAlpha)
        pulse(view: judgesChoice!, for: length, startAlpha: endAlpha, endAlpha: startAlpha)
    }
}













