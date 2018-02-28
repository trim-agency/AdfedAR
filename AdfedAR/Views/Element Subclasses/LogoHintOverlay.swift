import UIKit
import SnapKit

class LogoHintOverlay: UIView {
    @IBOutlet weak var bestOfShow           = UIImageView()
    @IBOutlet weak var judgesChoice         = UIImageView()
    @IBOutlet weak var rectangleGuide       = UIImageView()
    @IBOutlet weak var winnerView: UIImageView!
    var homeViewController: HomeViewController!
    var isPageDetected = false
   
    // MARK: - Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        bestOfShow?.tintColor   = UIColor.white
        judgesChoice?.tintColor = UIColor.white
       
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setInitialAlpha()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.animateRune(startAlpha: 0.80, to: 0, for: 1.25)
        }
    }

    // MARK: - Rune Animations
    func selectRune(_ page: Page) {
        hideRunes()
        isPageDetected = true
        removeAnimations()
        page == .bestOfShow ? glowSymbol(page: page) : glowSymbol(page: page)
    }
    
    private func removeAnimations() {
        DispatchQueue.main.async {
            self.judgesChoice?.layer.removeAllAnimations()
            self.bestOfShow?.layer.removeAllAnimations()
        }
    }

    func restartPulsing() {
        isPageDetected      = false
        winnerView.isHidden = true
        Animator.fade(view: bestOfShow!,
                      to: 1.0,
                      for: 1.0,
                      options: [.curveEaseOut],
                      completion: nil)
        Animator.fade(view: judgesChoice!,
                      to: 0.1,
                      for: 1.0, 
                      options: [.curveEaseOut]) {
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
            Animator.fade(view: view, to: 0, for: 0.5, options: [.curveEaseInOut], completion: nil)
        }
    }
    
    private func glowSymbol(page: Page) {
        DispatchQueue.main.async {
            self.winnerView.image       = page == .judgesChoice ? #imageLiteral(resourceName: "judges-choice-rune") : #imageLiteral(resourceName: "best-of-show-rune")
            self.winnerView.tintColor   = UIColor(red:0.75, green:0.65, blue:0.30, alpha:1.0)
            self.winnerView.alpha       = 1.0
            self.winnerView.isHidden    = false
            Animator.fade(view: self.winnerView,
                          to: 0.0,
                          for: 2.5,
                          options: [.curveEaseInOut],
                          completion: {
                            self.winnerView.isHidden = true
            })
        }
    }

    // MARK: - Rune
    func animateRune(startAlpha: CGFloat, to endAlpha: CGFloat, for length: Double) {
        isHidden = false
        pulse(view: bestOfShow!, for: length, startAlpha: startAlpha, endAlpha: endAlpha)
        pulse(view: judgesChoice!, for: length, startAlpha: endAlpha, endAlpha: startAlpha)
    }

    private func setInitialAlpha(){
        bestOfShow?.alpha   = 1.0
        judgesChoice?.alpha = 0.1
    }
    
    private func hideRunes() {
        Animator.fade(view: bestOfShow!, to: 0, for: 0.25, options: [.curveEaseInOut], completion: nil)
        Animator.fade(view: judgesChoice!, to: 0, for: 0.25, options: [.curveEaseInOut], completion: nil)
    }
    
    // MARK: - Rectangle Guide
    func showRectangleGuide() {
        self.rectangleGuide?.tintColor   = UIColor.white
        self.rectangleGuide?.alpha       = 0
        self.rectangleGuide?.isHidden    = false
        Animator.fade(view: self.rectangleGuide!, to: 1.0, for: 0.25, options: [.curveEaseInOut], completion: nil)
    }
    
    func hideRectangleGuide() {
        Animator.fade(view: rectangleGuide!, to: 0.0, for: 0.25, options: [.curveEaseInOut], completion: {
            self.rectangleGuide?.isHidden = true
        })
    }
}













