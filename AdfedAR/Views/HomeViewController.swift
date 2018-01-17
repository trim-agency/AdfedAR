import UIKit
import SceneKit
import ARKit
import Vision

class HomeViewController: UIViewController {
   
    let planeHeight: CGFloat    = 1
    var planeIdentifiers        = [UUID]()
    var anchors                 = [ARAnchor]()
    var nodes                   = [SCNNode]()
    var planeNodesCount         =  0
    var isPlaneSelected         = false
    var isSessionPaused         = false
    let visionHandler           = VNSequenceRequestHandler()
    let scene                   = SCNScene()
    var animations              = [String: CAAnimation]()

    @IBOutlet var sceneView: ARSCNView!
    var configuration: ARWorldTrackingConfiguration?
    var lastObservation: VNDetectedObjectObservation?
    var debugLayer: CAShapeLayer?
    var rootAnchor: ARAnchor?
    
    // MARK: - Protocol Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        defineSceneView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAR()
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
        sceneView.showsStatistics   = true
        
        sceneView.automaticallyUpdatesLighting = true
        #if DEBUG
        sceneView.showsStatistics   = true
        sceneView.debugOptions      = [ SCNDebugOptions.showLightExtents,
                                        ARSCNDebugOptions.showFeaturePoints ]
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
        guard let observations      = request.results as? [VNRectangleObservation],
            let firstObservation = observations.first else {
                return
        }
        
log.debug(firstObservation.confidence)
//        var firstObservation: VNRectangleObservation?
//        observations.forEach{
//            guard let observation = firstObservation else {
//                firstObservation = $0
//                return
//            }
//
//            if observation.confidence > (firstObservation?.confidence)! {
//                firstObservation = $0
//            }
//        }
        

        DispatchQueue.main.async {
//            guard let firstObservation = firstObservation else { return }
            let points          = [ firstObservation.topLeft, firstObservation.topRight, firstObservation.bottomRight, firstObservation.bottomLeft]
            let convertedPoints = points.map{ self.sceneView.convertFromCamera($0) }
            
            var rect    = firstObservation.boundingBox
            rect        = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
            rect        = rect.applying(CGAffineTransform(translationX: 0, y: 1))
            
            let center          = CGPoint(x: rect.midX, y: rect.midY)
            let hitTestResults  = self.sceneView.hitTest(center, types: [.existingPlaneUsingExtent])
            guard let result    = hitTestResults.first else { return }
            
            if let rootAnchor = self.rootAnchor,
               let node = self.sceneView.node(for: rootAnchor) {
                
                // Updates position of element when rect moves
                node.transform = SCNMatrix4(result.worldTransform)
                
            } else {
                
                // Creates a element if rootAnchor doesn't exist
                self.rootAnchor = ARAnchor(transform: result.worldTransform)
                self.sceneView.session.add(anchor: self.rootAnchor!)
                
                let rectTrackingRequest = VNTrackRectangleRequest(rectangleObservation: firstObservation, completionHandler: self.handleRectangles)
            }
            
            #if DEBUG
                self.debugLayer = self.drawPolygon(convertedPoints, color: .red)
                self.sceneView.layer.addSublayer(self.debugLayer!)
            #endif
        }
    }
    
    private func drawPolygon(_ points: [CGPoint], color: UIColor) -> CAShapeLayer {
       
        let layer           = CAShapeLayer()
        layer.fillColor     = nil
        layer.strokeColor   = color.cgColor
        layer.lineWidth     = 2
        let path            = UIBezierPath()
        
        path.move(to: points.last!)
        points.forEach { point in
            path.addLine(to: point)
        }
        layer.path = path.cgPath
        return layer
    }
    
    // MARK: - Custom Animations
    private func loadAllAnimations() {
        let jumpingScene = SCNScene(named: "3dAssets.scnassets/JumpingFixed.dae")!
        let node = SCNNode()
        for child in jumpingScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        node.position = SCNVector3(0, -1, -2)
        node.scale = SCNVector3(0.2, 0.2, 0.2)
        
        sceneView.scene.rootNode.addChildNode(node)
        
        loadAnimation(withKey: "jumping", sceneName: "3dAssets.scnassets/JumpingFixed", animationIdentifier: "JumpingFixed")
    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will only play once
            animationObject.repeatCount = 1
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            
            // Store the animation for later use
            animations[withKey] = animationObject
        }
    }
}

extension HomeViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        loadVision()
    }

    
    func createCube(_ vector: SCNVector3) {
        let cube        = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.001)
        let node        = SCNNode(geometry: cube)
        node.position   = vector
        sceneView.scene.rootNode.addChildNode(node)
    }
    

    private func pointToVect(_ results: [ARHitTestResult]) -> SCNVector3? {
        guard let result = results.first else {
            log.debug("No Hit Test Results")
            return nil
        }
        
        let hitTransform    = SCNMatrix4(result.worldTransform)
        let vector          = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        
        return vector
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        var jumpingScene = SCNScene(named: "3dAssets.scnassets/JumpingFixed.dae")!
        let wrapper     = SCNNode()
        
        scene.rootNode.childNodes.forEach{ wrapper.addChildNode($0) }
        
        wrapper.position = SCNVector3(0, -1, -2)
        wrapper.scale = SCNVector3(0.2, 0.2, 0.2)
        
        sceneView.scene.rootNode.addChildNode(wrapper)
        loadAnimation(withKey: "Jumping", sceneName: "3dAssets.scnassets/JumpingFixed", animationIdentifier: "JumpingFixed")
        return wrapper
    }
}











