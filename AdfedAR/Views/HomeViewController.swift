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
    var hasFoundRectangle       = false
    let animationScene          = SCNScene(named: "3dAssets.scnassets/IdleFormatted.dae")!
    var waitingOnPlane          = false
    
    @IBAction func didTapDebug(_ sender: Any) {
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
//        sceneView.layer.sublayers?.removeAll()
        sceneView.session.run(configuration!, options: [.resetTracking, .removeExistingAnchors])
        loadAllAnimations()
    }
    @IBOutlet weak var debugButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet var sceneView: MainARSCNView!
    var animationNode: SCNNode?
    var configuration: ARWorldTrackingConfiguration?
    var lastObservation: VNDetectedObjectObservation?
    var debugLayer: CAShapeLayer?
    var rootAnchor: ARAnchor?
    var detectedPage: Page?
    
    // MARK: - Protocol Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        defineSceneView()
        setupDebug()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAR()
        loadAllAnimations()
        loadCoreMLService()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    func loadRectangleDetection() {
        DispatchQueue.global(qos: .background).async {
            let pixelBuffer         = self.sceneView.session.currentFrame?.capturedImage
            let ciImage             = CIImage(cvImageBuffer: pixelBuffer!)
            let handler             = VNImageRequestHandler(ciImage: ciImage)
            let rectService         = RectangleDetectionService(sceneView: self.sceneView, rootAnchor: self.rootAnchor!)
            #if DEBUG
                rectService.delegate = self
            #endif
            let rectangleRequest    = VNDetectRectanglesRequest(completionHandler: rectService.handleRectangles)
            
            do {
                try handler.perform([rectangleRequest])
            } catch {
                log.error(error)
            }
        }
    }
   
    // MARK: Methods
    private func pageDetected() {
        sceneView.scene.rootNode.addChildNode(animationNode!)
        switch detectedPage! {
//        case .judgesChoiceGlobal:
//            playAnimation(key: "punching")
        case .judgesChoice:
            playAnimation(key: "dribbling")
//        case .bestOfShowGlobal:
//            playAnimation(key: "quickRoll")
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
        loadAnimation(withKey: "dribbling", sceneName: "3dAssets.scnassets/DribbleFormatted", animationIdentifier: "DribbleFormatted-1")
        loadAnimation(withKey: "quickRoll", sceneName: "3dAssets.scnassets/quickRollFormatted", animationIdentifier: "QuickRollFormatted-1")
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
            self.appendToDebugLabel("\n✅ CoreML Running")
            let coreMLService       = CoreMLService()
            coreMLService.delegate  = self
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try coreMLService.getPageType((self.sceneView.session.currentFrame?.capturedImage)!)
                } catch {
                    log.error(error)
                }
            }
        })
    }
    
    // MARK: - Debug Methods
    private func setupDebug() {
        #if DEBUG
            debugLabel.sizeToFit()
            debugLabel.isHidden     = false
            debugButton.isHidden    = false
        #endif
    }
}

// MARK: - ARKit Delegate
extension HomeViewController: ARSCNViewDelegate, ARSessionObserver {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        appendToDebugLabel("\n✅ Plane Detected")
        if waitingOnPlane {
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node                = SCNNode()
        rootAnchor              = anchor
        appendToDebugLabel("\n✅ Root Anchor Set")
        node.transform          = SCNMatrix4(anchor.transform)
        animationNode?.position = node.worldPosition
        return node
    }
}

// MARK: - CoreMLService Delegate
extension HomeViewController: CoreMLServiceDelegate {
    func didRecognizePage(sender: CoreMLService, page: Page) {
        detectedPage = page
        appendToDebugLabel("\n✅ " + (self.detectedPage?.rawValue)!)
        if rootAnchor != nil  {
            appendToDebugLabel("\n✅ Rectangle Detection Running")
            loadRectangleDetection()
        } else {
            waitingOnPlane = true
        }
    }
    
    func didReceiveRecognitionError(sender: CoreMLService, error: CoreMLError) {
        switch error {
        case .lowConfidence:
            appendToDebugLabel("\n💥 Low Confidence Observation")
//            loadCoreMLService()
        case .observationError:
            log.debug("Observation Error")
        }
    }
    
    private func appendToDebugLabel(_ string: String) {
        #if DEBUG
            DispatchQueue.main.async {
                self.debugLabel.text?.append(string)
            }
        #endif
    }
}

// MARK: - Rectangle Detection Delegate
extension HomeViewController: RectangleDetectionServiceDelegate {
    func didDetectRectangle(sender: RectangleDetectionService, corners: [CGPoint]) {
        appendToDebugLabel("\n✅ Rectangle Detected")
        pageDetected()
    }
    
    func rectangleDetectionError(sender: RectangleDetectionService) {
        log.error("Rectangle Error")
        appendToDebugLabel("\n💥 Rectangle Detection Error")
        loadRectangleDetection()
    }
}







