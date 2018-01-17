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
        let scene                   = SCNScene()
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
            let pixelBuffer = self.sceneView.session.currentFrame?.capturedImage
            let ciImage     = CIImage(cvImageBuffer: pixelBuffer!)
            let handler     = VNImageRequestHandler(ciImage: ciImage)
            let rectangleRequest = VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
            
            do {
                try handler.perform([rectangleRequest])
            } catch {
                log.error(error)
            }
        }
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations      = request.results as? [VNRectangleObservation],
              let firstObservation  = observations.first else {
                return
        }
        
        DispatchQueue.main.async {
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
        
        let hitTransform = SCNMatrix4(result.worldTransform)
        let vector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        
        return vector
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let cube = SCNBox(width: 0.1, height: 0.01, length: 0.1, chamferRadius: 0.005)
        let cubeNode = SCNNode(geometry: cube)
        let wrapper = SCNNode()
        wrapper.addChildNode(cubeNode)
        wrapper.transform = SCNMatrix4(anchor.transform)
        return wrapper
    }
}











