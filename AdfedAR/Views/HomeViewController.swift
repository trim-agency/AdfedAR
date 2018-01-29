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
    
    @IBOutlet var sceneView: ARSCNView!
    var animationNode: SCNNode?
    var configuration: ARWorldTrackingConfiguration?
    var lastObservation: VNDetectedObjectObservation?
    var debugLayer: CAShapeLayer?
    var rootAnchor: ARAnchor?
    var detectedPage: Page? {
        didSet {
            pageDetected()
        }
    }

    // MARK: - Protocol Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        defineSceneView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAR()
        loadAllAnimations()
    }
   

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - AR Setup
    private func configureAR() {
        let configuration               = ARWorldTrackingConfiguration()
        configuration.planeDetection    = .horizontal
        sceneView.session.run(configuration)
    }
    
    private func defineSceneView() {
        sceneView.scene             = scene
        sceneView.delegate          = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.debugOptions      = [ ARSCNDebugOptions.showFeaturePoints ]
        #if DEBUG
        sceneView.showsStatistics   = true
        sceneView.debugOptions      = [ SCNDebugOptions.showLightExtents ]
        #endif
    }
    
    func loadVision() {
        DispatchQueue.global(qos: .background).async {
            let pixelBuffer         = self.sceneView.session.currentFrame?.capturedImage
            let ciImage             = CIImage(cvImageBuffer: pixelBuffer!)
            let handler             = VNImageRequestHandler(ciImage: ciImage)
            let rectangleRequest    = VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
            
            do {
                try handler.perform([rectangleRequest])
            } catch {
                log.error(error)
            }
        }
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation] else {
            return
        }

        let highConfidenceObservation = observations.max { a, b in a.confidence < b.confidence }
        
        guard let highestConfidenceObservation = highConfidenceObservation else {
            log.debug("Error with high confidence observation")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let points = [ highestConfidenceObservation.topLeft,
                           highestConfidenceObservation.topRight,
                           highestConfidenceObservation.bottomRight,
                           highestConfidenceObservation.bottomLeft]

            highestConfidenceObservation.boundingBox.applying(CGAffineTransform(scaleX: 1, y: -1))
            highestConfidenceObservation.boundingBox.applying(CGAffineTransform(translationX: 0, y: 1))

            let center          = self.getBoxCenter(highConfidenceObservation)
            let hitTestResults  = self.sceneView.hitTest(center, types: [.existingPlaneUsingExtent, .featurePoint])
            guard let result    = hitTestResults.first else {
                log.debug("no hit test results")
                return
                
            }
            
            if let rootAnchor = self.rootAnchor,
               let node = self.sceneView.node(for: rootAnchor) {
                
                // Updates position of element when rect moves
                node.transform = SCNMatrix4(result.worldTransform)
                
            } else {
                
                // Creates a element if rootAnchor doesn't exist
                self.rootAnchor         = ARAnchor(transform: result.worldTransform)
                self.hasFoundRectangle  = true
                self.sceneView.session.add(anchor: self.rootAnchor!)
            }
            
            #if DEBUG
                let convertedPoints = points.map{ self.sceneView.convertFromCamera($0) }
                self.debugLayer     = self.drawPolygon(convertedPoints, color: .red)
                self.sceneView.layer.addSublayer(self.debugLayer!)
            #endif
        }
    }
    
    func playAnimation(key: String) {
        // Add the animation to start playing it right away
        sceneView.scene.rootNode.addAnimation(animations[key]!, forKey: key)
    }
    
    func stopAnimation(key: String) {
        // Stop the animation with a smooth transition
        sceneView.scene.rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }

    
    private func getBoxCenter(_ observation: VNRectangleObservation?) -> CGPoint {
        return CGPoint(x: (observation?.boundingBox.midX)!,
                       y: (observation?.boundingBox.midY)!)
    }

    private func drawPolygon(_ points: [CGPoint], color: UIColor) -> CAShapeLayer {
        return DebugPolygon(points: points, color: color)
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
    
    private func loadCoreMLService() {
        let coreMLService       = CoreMLService()
        coreMLService.delegate  = self
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try coreMLService.getPageType((self.sceneView.session.currentFrame?.capturedImage)!)
            } catch {
                log.error(error)
            }
        }
    }
    
    // MARK: - ARKit
    private func pageDetected() {
        log.debug("Animation Node Added")
        sceneView.scene.rootNode.addChildNode(animationNode!)
        switch detectedPage! {
        case .judgesChoiceGlobal:
            playAnimation(key: "punching")
        case .judgesChoiceLogo:
            playAnimation(key: "dribbling")
        case .bestOfShowGlobal:
            playAnimation(key: "quickRoll")
        case .bestOfShowLogo:
            playAnimation(key: "bellyDancing")
        }
    }
}

// MARK: - ARKit Delegate
extension HomeViewController: ARSCNViewDelegate, ARSessionObserver {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        loadVision() // Waits to load vision framework until after a plane is detected
        log.debug("plane detected")
        loadCoreMLService()
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        log.debug("Root Anchor Set")
        let node                = SCNNode()
        rootAnchor              = anchor
        node.transform          = SCNMatrix4(anchor.transform)
        animationNode?.position = node.worldPosition
//        sceneView.scene.rootNode.addChildNode(animationNode!)
        return node
    }
}

// MARK: - CoreMLService Delegate
extension HomeViewController: CoreMLServiceDelegate {
    func didRecognizePage(sender: CoreMLService, page: Page) {
        detectedPage = page
    }
    
    func didReceiveRecognitionError(sender: CoreMLService, error: Error) {
        log.debug(error)
    }
}








