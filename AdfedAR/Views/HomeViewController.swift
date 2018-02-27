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
    var hasDetectedPlane        = true
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
        CoreMLService.instance.currentFrame = nil
        toggleUI()
        logoHintOverlay.restartPulsing()
        userInstructionLabel.updateText(.lookingForRune)
        scene.removeAllNodes(completion: {
            self.startPageDetection()
        })
    }
    
    
    //MARK: - State
    private func setState(condition: State, then: State) {
        if AppState.instance.current == condition { AppState.instance.current = then }
    }
    
    private func isState(_ state: State) -> Bool {
        return AppState.instance.current == state ? true : false
    }
    
    func currentState() -> State {
        return AppState.instance.current
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
        if !isState(.rectangleDetected) { return }
        setState(condition: .rectangleDetected, then: .loadingAnimation)
        scene.removeAllAnimations()
        guard let detectedPage = self.detectedPage else { return }
        switch detectedPage {
        case .judgesChoice:
            scene.loadAndPlayAnimation(key: "judgesChoice")
        case .bestOfShow:
            scene.loadAndPlayAnimation(key: "bestOfShow")
        }
        logoHintOverlay.hideRectangleGuide()
        toggleUI()
        setState(condition: .loadingAnimation, then: .playingAnimation)
    }
   
    
    // MARK: - Core ML
    private func loadCoreMLService() {
        if !isState(.appLoading) && !isState(.reset) { return }
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
        log.debug("UI Toggled")
        DispatchQueue.main.async {
            self.resetButton.isHidden       = !self.resetButton.isHidden
            self.aafLabel.isHidden          = !self.aafLabel.isHidden
            self.rightAwardsLabel.isHidden  = !self.rightAwardsLabel.isHidden
            self.locationLabel.isHidden     = !self.locationLabel.isHidden
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
        if !isState(.runeDetected) { return }
        setState(condition: .runeDetected, then: .detectingRectangle)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            self.userInstructionLabel.updateText(.lookingForRectangle)
            DispatchQueue.global(qos: .background).async {
                let pixelBuffer         = self.sceneView.session.currentFrame?.capturedImage
                let ciImage             = CIImage(cvImageBuffer: pixelBuffer!)
                let handler             = VNImageRequestHandler(ciImage: ciImage)
                let rectService         = RectangleDetectionService.instance
                if !AppState.instance.hasReset {
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
        if !isState(.detectingRune) { return }
        guard let exposure = frame.lightEstimate?.ambientIntensity else { return }
        DispatchQueue.global().async {
            CoreMLService.instance.currentFrame = ArFrameData(image: frame.capturedImage, exposure: exposure)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if isState(.waitingOnPlane) {
            setState(condition: .waitingOnPlane, then: .runeDetected)
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
        if isState(.playingAnimation) { return }
        guard let touch = touches.first,
            let _ = event else {
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
        if !isState(.detectingRune) { return }
        setState(condition: .detectingRune, then: .runeDetected)
        CoreMLService.instance.currentFrame = nil
        provideHapticFeedback()
        detectedPage = page
        logoHintOverlay.selectRune(detectedPage!)
        if rootAnchor != nil && !isState(.reset) {
            userInstructionLabel.updateText(.none)
            loadRectangleDetection()
        } else if AppState.instance.hasReset {
            userInstructionLabel.updateText(.lookingForPlane)
            rootAnchor = nil
            loadRectangleDetection()
            userInstructionLabel.updateText(.none)
        } else {
            setState(condition: .runeDetected, then: .waitingOnPlane)
        }
    }
    
    func didReceiveRuneRecognitionError(sender: CoreMLService, error: CoreMLError) {
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
        if !isState(.detectingRune) { return }
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
        setState(condition: .detectingRectangle, then: .rectangleDetected)
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








