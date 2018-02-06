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
    var animationNodes          = [String: [String:Any]]()
    var animationScene          = SCNScene(named: "3dAssets.scnassets/IdleFormatted.dae")!
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
        removeAllNodes()
        logoHintOverlay.fadeIn()
        startPageDetection()
        debugLabel.text = ""
        didTapReset     = true
        detectedPage    = nil
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
    
    
    
    // MARK: - RESET
    private func removeAllNodes() {
        for node in sceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
    }
    
    // MARK: Methods
    private func pageDetected() {
        userInstructionLabel.updateText(.none)
//        sceneView.scene.rootNode.addChildNode(animationNode!)
        switch detectedPage! {
        case .judgesChoice:
            playAnimation(key: "grandma")
        case .bestOfShow:
            playAnimation(key: "bellyDancing")
        }
    }
    
    // MARK: - Custom Animations
    private func loadAllAnimations() {
//        let scene       = animationScene
//        animationNode   = SCNNode()
//
//        for child in scene.rootNode.childNodes {
//            animationNode?.addChildNode(child)
//        }

//        animationNode?.scale = SCNVector3(0.0008, 0.0008, 0.0008)

        loadAnimationFile(key: "grandma", for: "3dAssets.scnassets/hipHopFormatted", animationID:  "hipHopFormatted-1")
        loadAnimationFile(key: "bellyDancing", for: "3dAssets.scnassets/BellydancingFormatted", animationID: "BellydancingFormatted-1")

    }
    
    private func loadAnimationFile(key: String, for filePath: String, animationID: String) {
        let node = SCNNode()
        let scene = SCNScene(named: filePath + ".dae")
        let nodeArray = scene!.rootNode.childNodes
        
        for childNode in nodeArray {
            node.addChildNode(childNode as SCNNode)
        }
        let animation: CAAnimation = loadAnimation(withKey: key, sceneName: filePath, animationIdentifier: animationID)!
        let animationDetails = [
            "scene": scene,
            "node": node,
            "animation": animation
        ]
        
        animationNodes[key] = animationDetails
    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) -> CAAnimation? {
        let sceneURL    = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        guard let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) else {
            log.error("animation nil")
            return nil
        }
       
        animationObject.fadeInDuration = CGFloat(1)
        animationObject.fadeOutDuration = CGFloat(0.5)
        
        return animationObject
    }
    
    func playAnimation(key: String) {
        animationScene = animationNodes[key]!["scene"] as! SCNScene
        animationNode = animationNodes[key]!["node"] as! SCNNode
        for child in scene.rootNode.childNodes {
            animationNode?.addChildNode(child)
        }
        
//        animationNode?.scale = SCNVector3(0.0008, 0.0008, 0.0008)
        sceneView.scene.rootNode.addChildNode(animationNode!)
        sceneView.scene.rootNode.addAnimation(animationNodes[key]!["animation"] as! CAAnimation, forKey: key)
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
                    try self.coreMLService.getPageType(self.sceneView.session.currentFrame!)
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
//        if waitingOnPlane {
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
            waitingOnPlane = false
//        }
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
        appendToDebugLabel("\n✅ Rectangle Detected")
        pageDetected()
    }
    
    func rectangleDetectionError(sender: RectangleDetectionService) {
        appendToDebugLabel("\n💥 Rectangle Detection Error")
        loadRectangleDetection()
    }
}







