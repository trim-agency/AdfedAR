import Foundation
import ARKit

class MainARSCNView: ARSCNView {

    convenience init() {
        self.init()
        self.debugOptions      = [ ARSCNDebugOptions.showFeaturePoints ]
        self.automaticallyUpdatesLighting = true
        #if DEBUG
            self.showsStatistics   = true
            self.debugOptions      = [ SCNDebugOptions.showLightExtents,
                                       ARSCNDebugOptions.showFeaturePoints,
                                       SCNDebugOptions.showWireframe]
        #endif
    }
}
