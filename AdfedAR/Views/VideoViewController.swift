import UIKit

class VideoViewController: UIViewController {
    var page: Page?
    @IBOutlet weak var testLabel: UIButton!
    @IBAction func didTapTestButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        setButtonText()
    }
    
    private func setButtonText(){
        let labelText = page == Page.judgesChoice ? "Judges Choice" : "Best of Show"
        testLabel.setTitle(labelText, for: .normal)
    }
}
