//
//  VirtualObjectLoader.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//
import Foundation
import ARKit

/**
 Loads multiple `VirtualObject`s on a background queue to be able to display the
 objects quickly once they are needed.
*/
public class VirtualObjectLoader {
    
    public var virtualObjectAnchors = [ARAnchor]()
    
    public var dotObjects = [VirtualObject]()
    
    public var lineNodes = [LineNode]()
    
    public var distanceLabelNodes = [TextNode]()
    
    private(set) var isLoading = false
    
    // MARK: - Loading object

    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func loadVirtualObject(_ object: VirtualObject, loadedHandler: @escaping (VirtualObject) -> Void) {
        isLoading = true
        dotObjects.append(object)
        
        // Load the content into the reference node.
        DispatchQueue.global(qos: .userInitiated).async {
            self.isLoading = false
            loadedHandler(object)
        }
    }
    
    // MARK: - Removing Objects
    
    func removeAllVirtualObjects() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in dotObjects.indices.reversed() {
            removeVirtualObject(at: index)
        }
    }
    
    func removeAllLineNodes() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in lineNodes.indices.reversed() {
            removeLineNode(at: index)
        }
    }
    
    func removeAllTextNodes() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in distanceLabelNodes.indices.reversed() {
            removeTextNode(at: index)
        }
    }

    /// - Tag: RemoveVirtualObject
    func removeVirtualObject(at index: Int) {
        guard dotObjects.indices.contains(index) else { return }
        
        // Stop the object's tracked ray cast.
        dotObjects[index].stopTrackedRaycast()
        
        // Remove the visual node from the scene graph.
        dotObjects[index].removeFromParentNode()
        // Recoup resources allocated by the object.
        dotObjects.remove(at: index)
    
    }
    
    func removeLineNode(at index: Int) {
        guard lineNodes.indices.contains(index) else { return }
        
        // Remove the visual node from the scene graph.
        lineNodes[index].removeFromParentNode()
        // Recoup resources allocated by the object.
        lineNodes.remove(at: index)
    
    }
    
    func removeTextNode(at index: Int) {
        guard distanceLabelNodes.indices.contains(index) else { return }
        
        // Remove the visual node from the scene graph.
        distanceLabelNodes[index].removeFromParentNode()
        // Recoup resources allocated by the object.
        distanceLabelNodes.remove(at: index)
    
    }
}
