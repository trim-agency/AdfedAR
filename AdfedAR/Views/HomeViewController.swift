import UIKit
import SceneKit
import ARKit
import Vision

class HomeViewController: UIViewController {
   
    let planeHeight: CGFloat    = 1
    var planeIdentifiers        = [UUID]()
    var anchors                 = [ARAnchor]()
    let visionHandler           = VNSequenceRequestHandler()
    let scene                   = SCNScene()
    var animations              = [String: CAAnimation]()
    let animationScene          = SCNScene(named: "3dAssets.scnassets/IdleFormatted.dae")!
    var waitingOnPlane          = true
    var didTapReset             = false

    @IBOutlet weak var logoHintOverlay: LogoHintOverlay!
    @IBOutlet weak var debugButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var sceneView: MainARSCNView!
    @IBOutlet weak var userInstructionLabel: UserInstructionLabel!
    @IBAction func didTapDebug(_ sender: Any) { reset() }
    
    var animationNode: SCNNode?
    var configuration: ARWorldTrackingConfiguration?
    var lastObservation: VNDetectedObjectObservation?
    var debugLayer: CAShapeLayer?
    var rootAnchor: ARAnchor?
    var detectedPage: Page?
    var coreMLService: CoreMLService!
    
    // MARK: - Protocol Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Setup, Layout & ARKIT Start
    private func setup() {
        defineSceneView()
        setupDebug()
    }
    
    private func start() {
        configureAR()
        loadAllAnimations()
        loadCoreMLService()
    }
    private func reset() {
//        sceneView.session.pause()
        didTapReset = true
        removeAllNodes()
        debugLabel.text = ""
        logoHintOverlay.fadeIn()
        startPageDetection()
    }
    

    // MARK: - ARKit
    // MARK: Setup
    private func configureAR() {
        configuration                   = ARWorldTrackingConfiguration()
        configuration?.planeDetection    = .horizontal
        sceneView.session.run(configuration!)
    }
    
    private func defineSceneView() {
        sceneView.setup()
        sceneView.scene     = scene
        sceneView.delegate  = self
    }
    
    
    
    // MARK: - RESET
    private func removeAllNodes() {
        for node in sceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
    }
    
    // MARK: Methods
    private func pageDetected() {
        userInstructionLabel.updateText(.none)
        sceneView.scene.rootNode.addChildNode(animationNode!)
        switch detectedPage! {
        case .judgesChoice:
            playAnimation(key: "punching")
        case .bestOfShow:
            playAnimation(key: "bellyDancing")
        }
    }
    
    // MARK: - Custom Animations
    private func loadAllAnimations() {
        let scene       = animationScene
        animationNode   = SCNNode()

        for child in scene.rootNode.childNodes {
            animationNode?.addChildNode(child)
        }

        animationNode?.scale = SCNVector3(0.0008, 0.0008, 0.0008)
        loadAnimation(withKey: "bellyDancing", sceneName: "3dAssets.scnassets/BellydancingFormatted", animationIdentifier: "BellydancingFormatted-1")
        loadAnimation(withKey: "punching", sceneName: "3dAssets.scnassets/PunchingFormatted", animationIdentifier: "PunchingFormatted-1")
    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) {
        let sceneURL    = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            animations[withKey] = animationObject
        }
    }
    
    func playAnimation(key: String) {
        sceneView.scene.rootNode.addAnimation(animations[key]!, forKey: key)
    }
    
    func stopAnimation(key: String) {
        sceneView.scene.rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    // MARK: - Core ML
    private func loadCoreMLService() {
        appendToDebugLabel("\n✅ CoreML Waiting for Init")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.coreMLService          = CoreMLService()
            self.coreMLService.delegate = self
            self.startPageDetection()
            self.userInstructionLabel.updateText(.lookingForSymbol)
        })
    }
    
    private func startPageDetection() {
        appendToDebugLabel("\n✅ Page Detection Started")
        DispatchQueue.global(qos: .userInitiated).async {
            if self.sceneView.session.currentFrame != nil {
                do {
                    try self.coreMLService.getPageType((self.sceneView.session.currentFrame?.capturedImage)!)
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
            let rectService         = RectangleDetectionService(sceneView: self.sceneView, rootAnchor: self.rootAnchor!)
            rectService.delegate    = self
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
        if waitingOnPlane {
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
            waitingOnPlane = false
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node                = SCNNode()
        rootAnchor              = anchor
        node.transform          = SCNMatrix4(anchor.transform)
        animationNode?.position = node.worldPosition
        appendToDebugLabel("\n✅ Root Anchor Set")
        return node
    }
}

// MARK: - CoreMLService Delegate
extension HomeViewController: CoreMLServiceDelegate {
    func didRecognizePage(sender: CoreMLService, page: Page) {
        logoHintOverlay.fadeOut()
        provideHapticFeedback()
        detectedPage = page
        appendToDebugLabel("\n✅ " + (self.detectedPage?.rawValue)!)
        if rootAnchor != nil  {
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
        } else {
            userInstructionLabel.updateText(.lookingForPlane)
            waitingOnPlane = true
        }
    }
    
    func didReceiveRecognitionError(sender: CoreMLService, error: CoreMLError) {
        switch error {
        case .lowConfidence:
            appendToDebugLabel("\n💥 Low Confidence Observation")
            startPageDetection()
        case .observationError:
            appendToDebugLabel("\n💥 Observation Error")
            startPageDetection()
        case .invalidObject:
            appendToDebugLabel("\n💥 Invalid Object")
        }
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
        appendToDebugLabel("\n✅ Rectangle Detected")
        pageDetected()
    }
    
    func rectangleDetectionError(sender: RectangleDetectionService) {
        appendToDebugLabel("\n💥 Rectangle Detection Error")
        loadRectangleDetection()
    }
}







