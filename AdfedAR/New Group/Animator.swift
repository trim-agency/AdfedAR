import UIKit

class Animator {
    static func fade<T: UIView>(view: T, to alpha: CGFloat = 0.0, for duration: Double = 1.0, completion: (()->())?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, animations: {
                view.alpha = alpha
            }) { (finished) in
                completion?()
            }
        }
    }
   
    static func pulse<T: UIView>(view: T, for length: Double, to alpha: CGFloat ) {
        UIView.animate(withDuration: length, delay: 0, options: [.repeat, .autoreverse], animations: {
            view.alpha = alpha
        }, completion: nil)
    }
}
