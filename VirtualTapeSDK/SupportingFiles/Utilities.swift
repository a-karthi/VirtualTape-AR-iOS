//
//  Utilities.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//

import Foundation
import ARKit

// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
    }
    
    /**
     Factors out the orientation component of the transform.
    */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }

    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}


extension SCNVector3 {
    
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
    
    func normalized() -> SCNVector3 {
        return self / length()
    }
    
    func dot(vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
    }
    
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
    
    func distanceWithZaxis(to destination: SCNVector3) -> Float {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        let meters = sqrt(dx*dx + dy*dy + dz*dz)
        return meters
    }
    
    var cgPoint: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    var simd: simd_float3 {
        SIMD3(self)
    }
    
    func isNearByY(with vector: SCNVector3, limit: Float) -> Bool {
        let difference = abs(y - vector.y)
        return difference <= limit
    }
}

extension SCNVector3: Equatable {
    
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x &&
            lhs.y == rhs.y &&
            lhs.z == rhs.z
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {

    return left + (right * -1.0)
}

func *(vector:SCNVector3, multiplier:SCNFloat) -> SCNVector3 {
    
    return SCNVector3(vector.x * multiplier, vector.y * multiplier, vector.z * multiplier)
}

func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}

extension SCNMatrix4 {
    
    init(x: SCNVector3, y: SCNVector3, z: SCNVector3, w: SCNVector3) {
        self.init(
            m11: x.x,
            m12: x.y,
            m13: x.z,
            m14: 0.0,
            
            m21: y.x,
            m22: y.y,
            m23: y.z,
            m24: 0.0,
            
            m31: z.x,
            m32: z.y,
            m33: z.z,
            m34: 0.0,
            
            m41: w.x,
            m42: w.y,
            m43: w.z,
            m44: 1.0)
    }
}

func * (left: SCNMatrix4, right: SCNMatrix4) -> SCNMatrix4 {
    return SCNMatrix4Mult(left, right)
}

extension SCNVector3 {
    static func cross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
    }
    func distance(to otherVector: SCNVector3) -> Float {
        let dx = self.x - otherVector.x
        let dy = self.y - otherVector.y
        let dz = self.z - otherVector.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}


extension UIColor {
    
    /// Returns app gray color
    @nonobjc class var theme1: UIColor {
        return UIColor(hexString: "#FFD478")
    }
    
    @nonobjc class var theme2: UIColor {
        return UIColor(hexString: "#009192")
    }
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let aValue, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (aValue, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (aValue, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (aValue, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (aValue, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(red) / 255,
                  green: CGFloat(green) / 255,
                  blue: CGFloat(blue) / 255,
                  alpha: CGFloat(aValue) / 255)
    }
    
}


extension UIViewController {
    
    func showToast(message : String, font: UIFont) {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let attributes = [NSAttributedString.Key.font: font]
        let boundingRect = NSString(string: message).boundingRect(with: size, options: options, attributes: attributes, context: nil)

        let width = boundingRect.width + 25
        let height = boundingRect.height + 20

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - (width/2), y: self.view.frame.size.height-200, width: width, height: height))
        
        toastLabel.backgroundColor = UIColor.black
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastLabel.removeFromSuperview()
        }

    }
    
}


extension SCNNode {
    func placeBetweenNodes(_ nodeA: SCNNode, and nodeB: SCNNode) {
        let minPosition = nodeA.position
        let maxPosition = nodeB.position
        let x = ((maxPosition.x + minPosition.x)/2.0)
        let y = (maxPosition.y + minPosition.y)/2.0 + 0.01
        let z = (maxPosition.z + minPosition.z)/2.0
        self.position =  SCNVector3(x, y, z)
    }
}
