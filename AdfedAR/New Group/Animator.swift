import UIKit

class Animator {
    
//    static func fadeIn<T: UIView>(view: T, to alpha: CGFloat = 1.0, for duration: Double = 1.0) {
//        DispatchQueue.main.async {
//            UIView.animate(withDuration: duration) {
//                view.alpha = alpha
//            }
//        }
//    }
//
//     func fadeOut<T: UIView>(view: T, to alpha: CGFloat = 0.0, for duration: Double = 1.0) {
//        UIView.animate(withDuration: duration) {
//            view.alpha = alpha
//        }
//    }
    
    static func fade<T: UIView>(view: T, to alpha: CGFloat = 0.0, for duration: Double = 1.0, completion: (()->())?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, animations: {
                view.alpha = alpha
            }) { (finished) in
                completion?()
            }
        }
    }
    
//    static func pulse<T: UIView>(view: T, for length: Double, to alpha: CGFloat ) {
//        UIView.animate(withDuration: length, animations: {
//            self.fade(view: view, to: alpha, for: length, completion: nil)
//        }) { (finished) in
//            if !CoreMLService.instance.hasFoundPage {
//                self.pulse(view: view, for: length, to: )
//                self.pulse(view: view, for: length, minAlpha: minAlpha, maxAlpha: maxAlpha)
//            } else {
//                self.fade(view: view, to: 0.0, for: 1.5, completion: nil)
//            }
//        }
//    }
    
    static func pulse<T: UIView>(view: T, for length: Double, to alpha: CGFloat ) {
        UIView.animate(withDuration: length, delay: 0, options: [.repeat, .autoreverse], animations: {
            view.alpha = alpha
        }, completion: nil)
    }
}
