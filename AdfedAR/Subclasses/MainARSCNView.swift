import Foundation
import ARKit

class MainARSCNView: ARSCNView {
    func setup() {
        self.debugOptions      = [ ARSCNDebugOptions.showFeaturePoints ]
        self.automaticallyUpdatesLighting = true
        #if DEBUG
            self.showsStatistics   = true
            self.debugOptions      = [ SCNDebugOptions.showLightExtents,
                                       ARSCNDebugOptions.showFeaturePoints]
        #endif
    }
}
