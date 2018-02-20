import UIKit

class Animator {
    static func fade<T: UIView>(view: T, to alpha: CGFloat = 0.0, for duration: Double = 1.0, options: UIViewAnimationOptions = [],   completion: (()->())?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                view.alpha = alpha
            }) { (finished) in
                completion?()
            }
        }
    }
   
    static func stopAnimations<T: UIView>(views: [T]){
        DispatchQueue.main.async {
            views.forEach({ (view) in
                log.debug(view)
                view.layer.removeAllAnimations()
            })
        }
    }
}
