//
//  SphereNode.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 19/01/23.
//

import ARKit

public class SphereNode: SCNNode {

    lazy var sphereGeometry: SCNSphere = {
        let sphereGeometry = SCNSphere()
        sphereGeometry.radius = FocusSquare.pointerRadiuses.max
        sphereGeometry.firstMaterial?.diffuse.contents = UIColor.white
        sphereGeometry.firstMaterial?.emission.contents = UIColor.white
        sphereGeometry.firstMaterial?.isDoubleSided = true
        sphereGeometry.firstMaterial?.ambient.contents = UIColor.black
        sphereGeometry.firstMaterial?.lightingModel = .constant
        return sphereGeometry
    }()
    
    override init() {
        super.init()
        geometry = sphereGeometry
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
