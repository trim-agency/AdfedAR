import UIKit
import XCDYouTubeKit
import Alamofire
import AVKit

class VideoViewController: UIViewController {
    var page: Page?
    var videos: Videos?
    
    @IBOutlet weak var testLabel: UIButton!
    @IBAction func didTapTestButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVideo(videoIdentifier: videoId())
    }

    func playVideo(videoIdentifier: String?) {
        let playerViewController = AVPlayerViewController()
        self.present(playerViewController, animated: true, completion: nil)
    
        XCDYouTubeClient.default().getVideoWithIdentifier(videoIdentifier) { [weak playerViewController] (video: XCDYouTubeVideo?, error: Error?) in
            if let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) {
                playerViewController?.player = AVPlayer(url: streamURL)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    

    
    
    private func setButtonText(){
        let labelText = page == Page.judgesChoice ? "Judges Choice" : "Best of Show"
        testLabel.setTitle(labelText, for: .normal)
    }
    
    private func videoId() -> String {
        if page == Page.judgesChoice {
            return (videos?.judgesChoice)!
        }  else {
            return (videos?.bestOfShow)!
        }
    }
}

