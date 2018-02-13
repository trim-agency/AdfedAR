import UIKit
import XCDYouTubeKit


class VideoViewController: UIViewController {
    var page: Page?
    @IBOutlet weak var testLabel: UIButton!
    @IBAction func didTapTestButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        setupVideo()
//        setButtonText()
    }
    
    private func setupVideo() {
        let playerView = XCDYouTubeVideoPlayerViewController.init(videoIdentifier: "YE7VzlLtp-4")
        playerView.present(in: self.view)
        playerView.moviePlayer.controlStyle = .fullscreen
        playerView.moviePlayer.play()
    }
    
    private func setButtonText(){
        let labelText = page == Page.judgesChoice ? "Judges Choice" : "Best of Show"
        testLabel.setTitle(labelText, for: .normal)
    }
}

