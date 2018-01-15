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
//        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        sceneView.debugOptions      = [ SCNDebugOptions.showLightExtents,
                                        ARSCNDebugOptions.showFeaturePoints,
                                        ARSCNDebugOptions.showWorldOrigin ]
        sceneView.automaticallyUpdatesLighting = true
    }
}

extension ViewController: ARSCNViewDelegate {
 
    func session(_ session: ARSession, didFailWithError error: Error) {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
