import UIKit
import SceneKit

class Scene: SCNScene {
    var isPlayingAnimation = false
    var animations              = [String: CAAnimation]()
    var animationNodes          = [String: [String:Any]]()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup() {
        
    }
    
    // MARK: - Node Management
    func removeAllNodes(completion: (() -> ())?) {
        for node in rootNode.childNodes {
            if isPlayingAnimation {
                let action = SCNAction.fadeOut(duration: 1.0)
                node.runAction(action){
                    log.debug("removing node")
                    node.removeFromParentNode()
                    log.debug("node removed")
                    self.isPlayingAnimation = false
                    completion?()
                }
            } else {
                self.isPlayingAnimation = false
                node.removeFromParentNode()
                completion?()
            }
        }
    }
    
    // Mark: - Asset management
    func loadAllAnimations() {
        loadColladaAsset(key: "grandma", for: "3dAssets.scnassets/hipHopFormatted", animationID:  "hipHopFormatted-1")
        loadColladaAsset(key: "bellyDancing", for: "3dAssets.scnassets/BellydancingFormatted", animationID: "BellydancingFormatted-1")
    }
    
    func loadColladaAsset(key: String, for filePath: String, animationID: String) {
        let scene       = SCNScene(named: filePath + ".dae")!
        let parentNode  = SCNNode()
        parentNode.name = key
        add(node: scene.rootNode, to: parentNode)
        let animation: CAAnimation = loadAnimation(withKey: key,
                                                   sceneName: filePath,
                                                   animationIdentifier: animationID)!
        let animationDetails = [ "node": parentNode,
                                 "animation": animation ]
        animationNodes[key] = animationDetails
    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) -> CAAnimation? {
        let sceneURL    = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        guard let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) else {
            log.error("animation nil")
            return nil
        }

        return animationObject
    }
    
    func loadAndPlayAnimation(key: String) {
        DispatchQueue.main.async {
            let node        = self.animationNodes[key]!["node"] as! SCNNode
            node.opacity    = 0.0
            self.add(node: node, to: self.rootNode)
            self.rootNode.scale = SCNVector3(0.001, 0.001, 0.001)
            self.playAnimation(key: key, for: node)
        }
    }
 
    
    private func add(node: SCNNode, to parentNode: SCNNode) {
        parentNode.addChildNode(node)
    }
    
    // MARK: - Start & Stop
    private func playAnimation(key: String, for node: SCNNode) {
        isPlayingAnimation      = true
        let animation           = self.animationNodes[key]!["animation"] as! CAAnimation
        rootNode.addAnimation(animation, forKey: key)
        fadeIn(node)
    }
    
    func stopAnimation(key: String) {
        isPlayingAnimation      = false
        rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    // MARK: - Transitions
    private func fadeIn(_ node: SCNNode) {
        let action = SCNAction.fadeIn(duration: 1.0)
        node.runAction(action)
    }
    
    private func fadeOut(_ node: SCNNode) {
        let action = SCNAction.fadeOut(duration: 1.0)
        node.runAction(action)
    }
    
    func removeAllAnimations() {
        rootNode.removeAllAnimations()
    }
}
