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
                    node.removeFromParentNode()
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
        loadColladaAsset(key: "judgesChoice", for: "3dAssets.scnassets/judgesChoice")
        loadColladaAsset(key: "bestOfShow", for: "3dAssets.scnassets/bestOfShow")
    }
    
    func loadColladaAsset(key: String, for filePath: String) {
        let scene       = SCNScene(named: filePath + ".scn")!
        let parentNode  = SCNNode()
        parentNode.name = key
        add(node: scene.rootNode, to: parentNode)
//        let animation: CAAnimation = loadAnimation(withKey: key,
//                                                   sceneName: filePath)!
        let animationDetails = [ "node": parentNode ]
        animationNodes[key] = animationDetails
    }
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) -> CAAnimation? {
        let sceneURL    = Bundle.main.url(forResource: sceneName, withExtension: "scn")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        guard let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) else {
            log.error("animation nil")
            return nil
        }

        return animationObject
    }
    
    func loadAndPlayAnimation(key: String) {
        if let node = rootNode.childNode(withName: key, recursively: true) {
            node.opacity = 0.0
            node.isHidden = false
            fadeIn(node)
        } else {
            DispatchQueue.main.async {
                let node        = self.animationNodes[key]!["node"] as! SCNNode
                node.opacity    = 0.0
                node.scale = SCNVector3Make(0.1, 0.1, 0.1)
                self.add(node: node, to: self.rootNode)
                self.fadeIn(node)
            }
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
