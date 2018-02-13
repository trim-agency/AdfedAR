import UIKit

class WalkthroughPageViewController: UIPageViewController {

    @IBOutlet weak var pageViewControls: UIPageControl!
    private(set) lazy var walkthroughViewControllers: [UIViewController] = {
        return [
            self.getVC(1),
            self.getVC(2),
            self.getVC(3)
        ]
    }()
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        dataSource = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        defineLook()
        display()
    }
   
    private func defineLook() {
        view.layer.backgroundColor  = UIColor.white.cgColor
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
                               animated: true,
                               completion: nil)
        }
    }
}

extension WalkthroughPageViewController: UIPageViewControllerDataSource {
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
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return walkthroughViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstVC = walkthroughViewControllers.first,
            let firstVCIndex = walkthroughViewControllers.index(of: firstVC) else {
                return 0
        }
        return firstVCIndex
    }
}

