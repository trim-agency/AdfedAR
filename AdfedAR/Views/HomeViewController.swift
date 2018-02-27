import UIKit
import SceneKit
import ARKit
import Vision
import Alamofire
import SwiftyJSON
import XCDYouTubeKit
import AVKit
import SnapKit

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
    var isPlayingAnimation      = false   {
        didSet {
            setInstructionLabelForAnimation()
        }
    }
    var didRecognizeRune        = false
    var didDetectRectangle      = false
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var rightAwardsLabel: UILabel!
    @IBOutlet weak var darkeningLayer: UIView!
    @IBOutlet weak var aafLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var sceneView: MainARSCNView!
    @IBOutlet weak var userInstructionLabel: UserInstructionLabel!
    @IBOutlet weak var logoHintOverlay: LogoHintOverlay!
    @IBAction func didTapDebug(_ sender: Any) { reset() }
    
    var rectangleDetectionGuide: RectangleDetectionGuide?
    var configuration: ARWorldTrackingConfiguration?
    var lastObservation: VNDetectedObjectObservation?
    var debugLayer: CAShapeLayer?
    var rootAnchor: ARAnchor?
    var detectedPage: Page?
    var videos: Videos?
    
    // MARK: - Protocol Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        AppState.instance.current = State.appLoading
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
        AppState.instance.current = .reset
        isPlayingAnimation  = false
        didRecognizeRune    = false
        didDetectRectangle  = false
        CoreMLService.instance.currentFrame = nil
        toggleUI()
        logoHintOverlay.restartPulsing()
        userInstructionLabel.updateText(.lookingForRune)
        scene.removeAllNodes(completion: {
            self.startPageDetection()
            DispatchQueue.main.async {
                self.debugLabel.text = ""
            }
            self.didTapReset     = true
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
        logoHintOverlay.homeViewController = self
        logoHintOverlay.isHidden = false
        view.addSubview(logoHintOverlay)
        logoHintOverlay.snp.makeConstraints{ make -> Void in
            make.center.equalTo(self.view.snp.center)
            make.width.height.equalTo(self.view.snp.width)
        }
    }
    
    // MARK: - RESET
    private func pageDetected() {
        userInstructionLabel.updateText(.none)
        if didTapReset {
            displayAnimations()
        } else {
            scene.removeAllNodes {
                self.displayAnimations()
            }
        }
    }
    
    private func displayAnimations() {
        if AppState.instance.current == .rectangleDetected { AppState.instance.current = .loadingAnimation }
        if isPlayingAnimation { return }
        scene.removeAllAnimations()
        guard let detectedPage = self.detectedPage else { return }
        switch detectedPage {
        case .judgesChoice:
            appendToDebugLabel("judges choice triggered")
            scene.loadAndPlayAnimation(key: "judgesChoice")
        case .bestOfShow:
            appendToDebugLabel("best of show triggered")
            scene.loadAndPlayAnimation(key: "bestOfShow")
        }
        logoHintOverlay.hideRectangleGuide()
        toggleUI()
        isPlayingAnimation = true
        if AppState.instance.current == .loadingAnimation { AppState.instance.current = .playingAnimation }
    }
    
    // MARK: - Core ML
    private func loadCoreMLService() {
        if isPlayingAnimation { return } // to keep coreml from triggering when transitioning back from video view
        appendToDebugLabel("\n✅ CoreML Waiting for Init")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            CoreMLService.instance.delegate = self
            self.sceneView.session.delegate = self
            self.startPageDetection()
            self.userInstructionLabel.updateText(.lookingForRune)
        })
    }
    
    private func startPageDetection() {
        if AppState.instance.current == .appLoading ||
            AppState.instance.current == .reset { AppState.instance.current = .detectingRune }
        
        if self.sceneView.session.currentFrame != nil {
            do {
                try CoreMLService.instance.getRuneType()
            } catch {
                self.appendToDebugLabel("\n💥 Page Detection Error")
            }
        }
    }
    
    // MARK: - UI Elements
    private func toggleUI() {
        DispatchQueue.main.async {
            self.resetButton.isHidden       = !self.isPlayingAnimation
            self.aafLabel.isHidden          = self.isPlayingAnimation
            self.rightAwardsLabel.isHidden  = !self.isPlayingAnimation
            self.locationLabel.isHidden     = !self.isPlayingAnimation
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
        if AppState.instance.current == .runeDetected { AppState.instance.current = .detectingRectangle }
        if didDetectRectangle { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            if !self.didRecognizeRune { return }
            log.debug("RECT DETECT STARTED")
            self.userInstructionLabel.updateText(.lookingForRectangle)
            DispatchQueue.global(qos: .background).async {
                let pixelBuffer         = self.sceneView.session.currentFrame?.capturedImage
                let ciImage             = CIImage(cvImageBuffer: pixelBuffer!)
                let handler             = VNImageRequestHandler(ciImage: ciImage)
                let rectService         = RectangleDetectionService.instance
                if !(self.didTapReset) {
                    // keeps duplication from occurring after reset
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
        })
    }
    
    private func setInstructionLabelForAnimation() {
        if isPlayingAnimation {
            userInstructionLabel.updateText(.tapForVideo)
        } else {
            userInstructionLabel.updateText(.none)
        }
    }
}

// MARK: - ARKit Delegate
extension HomeViewController: ARSCNViewDelegate, ARSessionObserver, ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if didRecognizeRune { return }
        guard let exposure = frame.lightEstimate?.ambientIntensity else { return }
        DispatchQueue.global().async {
            CoreMLService.instance.currentFrame = ArFrameData(image: frame.capturedImage, exposure: exposure)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        waitingOnPlane = false
        if didRecognizeRune {
            loadRectangleDetection()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node                = SCNNode()
        rootAnchor              = anchor
        node.transform          = SCNMatrix4(anchor.transform)
        sceneView.scene.rootNode.worldPosition = node.worldPosition
        return node
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isPlayingAnimation { return }
        guard let touch = touches.first,
            let _ = event else {
                log.error("Touch or Event nil")
                return
        }
        let touchPoint = touch.preciseLocation(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchPoint, options: nil)
        
        if let _ = hitTestResults.first?.node {
            playVideo(videoIdentifier: videoId())
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
    func didRecognizeRune(sender: CoreMLService, page: Page) {
        if AppState.instance.current == .detectingRune { AppState.instance.current = .runeDetected }
        if didRecognizeRune { return } // keeps repeated triggering from delegate method from causing problems
        didRecognizeRune = true
        CoreMLService.instance.currentFrame = nil
        provideHapticFeedback()
        detectedPage = page
        logoHintOverlay.selectRune(detectedPage!)
        if rootAnchor != nil && !didTapReset {
            userInstructionLabel.updateText(.none)
            loadRectangleDetection()
        } else if didTapReset {
            userInstructionLabel.updateText(.lookingForPlane)
            rootAnchor = nil
            loadRectangleDetection()
            userInstructionLabel.updateText(.none)
        } else {
            userInstructionLabel.updateText(.lookingForPlane)
            waitingOnPlane = true
        }
    }
    
    func didReceiveRuneRecognitionError(sender: CoreMLService, error: CoreMLError) {
        if AppState.instance.current == .detectingRune { return }
        switch error {
        case .lowConfidence:
            appendToDebugLabel("\n💥 Low Confidence Observation")
        case .observationError:
            appendToDebugLabel("\n💥 Observation Error")
        case .invalidObject:
            appendToDebugLabel("\n💥 Invalid Object")
        case .missingARFrame:
            appendToDebugLabel("Missing AR frame")
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
        if AppState.instance.current == .detectingRectangle  { AppState.instance.current = .rectangleDetected }
        log.debug("Rect DETECTED")
        didDetectRectangle = true
        Animator.fade(view: darkeningLayer, to: 0.0, for: 2.0, completion: nil)
        logoHintOverlay.hideRectangleGuide()
        pageDetected()
    }
    
    func rectangleDetectionError(sender: RectangleDetectionService) {
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








