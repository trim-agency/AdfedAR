import UIKit
import SceneKit
import ARKit
import Vision
import Alamofire
import SwiftyJSON
import XCDYouTubeKit
import AVKit

class HomeViewController: UIViewController {
   
    let planeHeight: CGFloat    = 1
    var planeIdentifiers        = [UUID]()
    var anchors                 = [ARAnchor]()
    let visionHandler           = VNSequenceRequestHandler()
    let scene                   = Scene()
    var animations              = [String: CAAnimation]()
    var animationNodes          = [String: [String:Any]]()
    var waitingOnPlane          = true
    var didTapReset             = false
    var isPlayingAnimation      = false

    @IBOutlet weak var darkeningLayer: UIView!
    @IBOutlet weak var aafLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var sceneView: MainARSCNView!
    @IBOutlet weak var userInstructionLabel: UserInstructionLabel!
    @IBOutlet weak var logoHintOverlay: LogoHintOverlay!
    @IBAction func didTapDebug(_ sender: Any) { reset() }

    var configuration: ARWorldTrackingConfiguration?
    var lastObservation: VNDetectedObjectObservation?
    var debugLayer: CAShapeLayer?
    var rootAnchor: ARAnchor?
    var detectedPage: Page?
    var videos: Videos?
    
    // MARK: - Protocol Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayLogoHintOverlay()
    }

    // MARK: - Setup, Layout & ARKIT Start
    private func setup() {
        defineSceneView()
        setupDebug()
        getVideoIds()
    }
    
    private func start() {
        configureAR()
        scene.loadAllAnimations()
        loadCoreMLService()
    }
    
    private func reset() {
        scene.removeAllNodes(completion: {
            self.startPageDetection()
            DispatchQueue.main.async {
                self.debugLabel.text = ""
            }
            self.didTapReset     = true
            self.detectedPage    = nil
        })
    }
    

    // MARK: - ARKit
    // MARK: Setup
    private func configureAR() {
        configuration                   = ARWorldTrackingConfiguration()
        configuration?.planeDetection   = .horizontal
        sceneView.session.run(configuration!)
    }
    
    private func defineSceneView() {
        sceneView.setup()
        sceneView.scene     = scene
        sceneView.delegate  = self
    }
    
    private func displayLogoHintOverlay() {
        logoHintOverlay.isHidden = false
        view.addSubview(logoHintOverlay)
        logoHintOverlay.snp.makeConstraints{ make -> Void in
            make.center.equalTo(self.view.snp.center)
            make.width.height.equalTo(self.view.snp.width).multipliedBy(0.7)
        }
    }
    
    // MARK: - RESET
    // MARK: Methods
    private func pageDetected() {
        userInstructionLabel.updateText(.none)
        scene.removeAllNodes {
            self.scene.removeAllAnimations()
            switch self.detectedPage! {
            case .judgesChoice:
                
                self.scene.loadAndPlayAnimation(key: "grandma")
            case .bestOfShow:
                self.scene.loadAndPlayAnimation(key: "bellyDancing")
            }
        }
    }
    
    // MARK: - Custom Animations
    
    
    // MARK: - Core ML
    private func loadCoreMLService() {
        if isPlayingAnimation { return } // to keep coreml from triggering when transitioning back from video view
        appendToDebugLabel("\n✅ CoreML Waiting for Init")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            CoreMLService.instance.delegate = self
            self.startPageDetection()
            self.userInstructionLabel.updateText(.lookingForSymbol)
        })
    }
    
    private func startPageDetection() {
        appendToDebugLabel("\n✅ Page Detection Started")
        DispatchQueue.global(qos: .userInitiated).async {
            if self.sceneView.session.currentFrame != nil {
                do {
                    try CoreMLService.instance.getPageType(self.sceneView.session.currentFrame!)
                } catch {
                    self.appendToDebugLabel("\n💥 Page Detection Error")
                }
            }
        }
    }
    
    // MARK: - Debug Methods
    private func setupDebug() {
        #if DEBUG
            debugLabel.sizeToFit()
            debugLabel.isHidden     = false
        #endif
    }
    
    // MARK: - Haptic Feedback
    private func provideHapticFeedback() {
        DispatchQueue.main.async {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        }
    }
    
    // MARK: - Vision Framework
    func loadRectangleDetection() {
        userInstructionLabel.updateText(.lookingForRectangle)
        DispatchQueue.global(qos: .background).async {
            let pixelBuffer         = self.sceneView.session.currentFrame?.capturedImage
            let ciImage             = CIImage(cvImageBuffer: pixelBuffer!)
            let handler             = VNImageRequestHandler(ciImage: ciImage)
            let rectService         = RectangleDetectionService.instance
            if !(self.didTapReset) { // keeps duplication from occurring after reset
                rectService.setup(sceneView: self.sceneView, rootAnchor: self.rootAnchor!)
                rectService.delegate    = self
            }
            let rectangleRequest    = VNDetectRectanglesRequest(completionHandler: rectService.handleRectangles)
            do {
                try handler.perform([rectangleRequest])
            } catch {
                log.error(error)
            }
        }
    }
}

// MARK: - ARKit Delegate
extension HomeViewController: ARSCNViewDelegate, ARSessionObserver {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        appendToDebugLabel("\n✅ Plane Detected")
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
            waitingOnPlane = false
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node                = SCNNode()
        rootAnchor              = anchor
        node.transform          = SCNMatrix4(anchor.transform)
        sceneView.scene.rootNode.worldPosition = node.worldPosition
        appendToDebugLabel("\n✅ Root Anchor Set")
        return node
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let _ = event else {
                log.error("Touch or Event nil")
                return
        }
        let touchPoint = touch.preciseLocation(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchPoint, options: nil)

        if let _ = hitTestResults.first?.node {
            scene.loadAndPlayAnimation(key: "grandma")
//            playVideo(videoIdentifier: videoId())
        }
    }
    
    // MARK: - Get Video Id's
    private func getVideoIds(){
        Alamofire.request(Secrets.AWS_URL)
            .responseJSON(completionHandler: { (response) in
                switch response.result{
                case .success(_):
                    do {
                        let jsonResponse = try JSON(data: response.data!)
                        
                        if let judgesChoice = jsonResponse["judgesChoice"].string,
                            let bestOfShow = jsonResponse["bestOfShow"].string {
                            self.videos = Videos(bestOfShow: bestOfShow,
                                                 judgesChoice: judgesChoice)
                        }
                    } catch {
                        log.error("json deserialization error")
                    }
                case .failure(let error):
                    log.debug(error)
                }
            })
    }
}

// MARK: - CoreMLService Delegate
extension HomeViewController: CoreMLServiceDelegate {
    func didRecognizePage(sender: CoreMLService, page: Page) {
        provideHapticFeedback()
        detectedPage = page
        logoHintOverlay.selectRune(detectedPage!)
        appendToDebugLabel("\n✅ " + (self.detectedPage?.rawValue)!)
        if rootAnchor != nil && didTapReset == false {
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
        } else if didTapReset == true {
            userInstructionLabel.updateText(.lookingForPlane)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                self.loadRectangleDetection()
                self.userInstructionLabel.updateText(.none)
            })
        } else {
            userInstructionLabel.updateText(.lookingForPlane)
            waitingOnPlane = true
        }
    }
    
    func didReceiveRecognitionError(sender: CoreMLService, error: CoreMLError) {
        switch error {
        case .lowConfidence:
            appendToDebugLabel("\n💥 Low Confidence Observation")
        case .observationError:
            appendToDebugLabel("\n💥 Observation Error")
        case .invalidObject:
            appendToDebugLabel("\n💥 Invalid Object")
        }
        startPageDetection()
    }
    
    private func appendToDebugLabel(_ string: String) {
        #if DEBUG
            DispatchQueue.main.async {
                self.debugLabel.text?.append(string)
            }
        #endif
        log.debug(string)
    }
}

// MARK: - Rectangle Detection Delegate
extension HomeViewController: RectangleDetectionServiceDelegate {
    func didDetectRectangle(sender: RectangleDetectionService, corners: [CGPoint]) {
        Animator.fade(view: darkeningLayer, to: 0.0, for: 2.0, completion: nil)
        appendToDebugLabel("\n✅ Rectangle Detected")
        pageDetected()
    }
    
    func rectangleDetectionError(sender: RectangleDetectionService) {
        appendToDebugLabel("\n💥 Rectangle Detection Error")
        loadRectangleDetection()
    }
}

// MARK: - Video Player
extension HomeViewController {
   
    private func playVideo(videoIdentifier: String?) {
        let playerViewController = AVPlayerViewController()
        self.present(playerViewController, animated: true, completion: nil)
        
        XCDYouTubeClient.default().getVideoWithIdentifier(videoIdentifier) { [weak playerViewController] (video: XCDYouTubeVideo?, error: Error?) in
            if let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) {
                playerViewController?.player = AVPlayer(url: streamURL)
                playerViewController?.player?.play()
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func videoId() -> String {
        if detectedPage == Page.judgesChoice {
            return (videos?.judgesChoice)!
        }  else {
            return (videos?.bestOfShow)!
        }
    }
}


