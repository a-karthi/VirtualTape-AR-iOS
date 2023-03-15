//
//  LineNode.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 19/01/23.
//

import SceneKit

public class LineNode: SCNNode {
    
    lazy var cylinderGeometry: SCNCylinder = {
        let cylinderGeometry = SCNCylinder()
        let material = SCNMaterial()
        material.lightingModel = .blinn
        cylinderGeometry.firstMaterial = material
        return cylinderGeometry
    }()
    
    override init() {
        super.init()
        
        geometry = cylinderGeometry
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    func update(with style: LineStyle) {
        cylinderGeometry.firstMaterial?.transparent.contents = style.transparentContent
    }
}

enum LineStyle {
    case stripes
    case continuous
    
    var transparentContent: Any? {
        switch self {
        case .stripes:
            return UIImage(named: "stripes")
        case .continuous:
            return nil
        }
    }
}

struct LineFactory {
    
    static func createMeasurementLine() -> LineNode {
        let line = LineNode()
        let lineType = LineType.distance
        line.cylinderGeometry.firstMaterial?.diffuse.contents = lineType.color
        line.cylinderGeometry.radius = lineType.radius
        return line
    }
}

enum LineType {
    case distance
    case axis
    
    var color: UIColor {
        return .white
    }
    
    var radius: CGFloat {
        return 0.003
    }
}
