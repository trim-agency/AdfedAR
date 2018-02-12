import UIKit

class WalkthroughViewController: UIPageViewController {

    private(set) lazy var walkthroughViewControllers: [UIViewController] = {
        return [
            self.getVC(1),
            self.getVC(2),
            self.getVC(3)
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        defineSize()
        defineLook()
        display()
    }
    
    private func defineSize() {
        let width = UIScreen.main.bounds.width * 0.8
        self.preferredContentSize = CGSize(width: width, height: width * 1.3)
    }
    
    private func defineLook() {
        view.layer.cornerRadius     = 5.0
        view.backgroundColor        = UIColor.white
        view.layer.borderColor      = UIColor.black.cgColor
        view.layer.borderWidth      = 2.0
    }
    
    private func getVC(_ number: Int) -> UIViewController {
        return UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "walkthrough\(number)")
    }
    
    private func display() {
        if let firstVC = walkthroughViewControllers.first {
            setViewControllers([firstVC],
                               direction: .forward,
                               animated: true, completion: nil)
        }
    }
}

extension WalkthroughViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = walkthroughViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = vcIndex - 1
        
        guard previousIndex >= 0 else { return nil }
        return walkthroughViewControllers[previousIndex]
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcIndex = walkthroughViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = vcIndex + 1
        
        guard nextIndex < walkthroughViewControllers.count else { return nil }
        return walkthroughViewControllers[nextIndex]
    }
    
    
}
