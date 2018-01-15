import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
   
    @IBOutlet var sceneView: ARSCNView!
    var configuration: ARWorldTrackingConfiguration?
    let planeHeight: CGFloat = 0
    
    var planeIdentifiers    = [UUID]()
    var anchors             = [ARAnchor]()
    var nodes               = [SCNNode]()
    var planeNodesCount     =  0
    var isPlaneSelected     = false
    var isSessionPaused     = false
    
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
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
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
                                        ARSCNDebugOptions.showFeaturePoints,
                                        ARSCNDebugOptions.showWorldOrigin ]
        #endif
    }
    
    private func addCubeAtTouch(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0.25
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let planeNode = node.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane else { return }
        
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let hitTestResults = sceneView.hitTest(touch.location(in: sceneView), types: .featurePoint)
        
        guard let hitTestResult = hitTestResults.last else { return }
        let hitTransform = SCNMatrix4(hitTestResult.worldTransform)
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        createCube(hitVector)
    }
    
    func createCube(_ vector: SCNVector3) {
        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.001)
        let node = SCNNode(geometry: cube)
        node.position = vector
        sceneView.scene.rootNode.addChildNode(node)
    }
}











