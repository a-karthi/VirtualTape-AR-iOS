//
//  VirtualTapeSDK+ObjectSelection.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//

import UIKit
import ARKit

extension VirtualTapeSDK {
    
    /** Adds the specified virtual object to the scene, placed at the world-space position
     estimated by a hit test from the center of the screen.
     - Tag: PlaceVirtualObject */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard focusSquare.state != .initializing, let query = virtualObject.raycastQuery else {
            print("CANNOT PLACE OBJECT\nTry moving left or right.")
            //self.statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
            self.virtualObjectSelectionViewController(didDeselectObject: virtualObject)
            return
        }
       
        let trackedRaycast = createTrackedRaycastAndSet3DPosition(of: virtualObject, from: query,
                                                                  withInitialResult: virtualObject.mostRecentInitialPlacementResult)
        
        virtualObject.raycast = trackedRaycast
        virtualObjectInteraction?.selectedObject = virtualObject
        virtualObject.isHidden = false
    }

    func connectObjects() {
        let objects = virtualObjectLoader.dotObjects
        if objects.count > 1 {
            guard let lastNode = objects.last else {return}
            let previousNode = objects[objects.count - 2]
            let firstline: LineNode = LineFactory.createMeasurementLine()
            firstline.update(with: .continuous)
            firstline.isHidden = false
            let lookAt = lastNode.position - previousNode.position
            let height = lookAt.length()
            let y = lookAt.normalized()
            let up = lookAt.cross(vector: lastNode.position).normalized()
            let x = y.cross(vector: up).normalized()
            let z = x.cross(vector: y).normalized()
            let transform = SCNMatrix4(x: x, y: y, z: z, w: previousNode.position)
            firstline.cylinderGeometry.height = CGFloat(height)
            firstline.transform = SCNMatrix4MakeTranslation(0.0, height / 2.0, 0.0) * transform
            sceneView.scene.rootNode.addChildNode(firstline)
            virtualObjectLoader.lineNodes.append(firstline)
        }
    }
    
    // - Tag: GetTrackedRaycast
    func createTrackedRaycastAndSet3DPosition(of virtualObject: VirtualObject, from query: ARRaycastQuery,
                                              withInitialResult initialResult: ARRaycastResult? = nil) -> ARTrackedRaycast? {
        if let initialResult = initialResult {
            self.setTransform(of: virtualObject, with: initialResult)
        }
        
        return session.trackedRaycast(query) { (results) in
            self.setVirtualObject3DPosition(results, with: virtualObject)
        }
    }
    
    func createRaycastAndUpdate3DPosition(of virtualObject: VirtualObject, from query: ARRaycastQuery) {
        guard let result = session.raycast(query).first else {
            return
        }
        
        if virtualObject.allowedAlignment == .any && self.virtualObjectInteraction?.trackedObject == virtualObject {
            
            // If an object that's aligned to a surface is being dragged, then
            // smoothen its orientation to avoid visible jumps, and apply only the translation directly.
            virtualObject.simdWorldPosition = result.worldTransform.translation
            
            let previousOrientation = virtualObject.simdWorldTransform.orientation
            let currentOrientation = result.worldTransform.orientation
            virtualObject.simdWorldOrientation = simd_slerp(previousOrientation, currentOrientation, 0.1)
        } else {
            self.setTransform(of: virtualObject, with: result)
        }
    }
    
    // - Tag: ProcessRaycastResults
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult], with virtualObject: VirtualObject) {
        
        guard let result = results.first else {
            fatalError("Unexpected case: the update handler is always supposed to return at least one result.")
        }
        
        self.setTransform(of: virtualObject, with: result)
        
        // If the virtual object is not yet in the scene, add it.
        if virtualObject.parent == nil {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            virtualObject.shouldUpdateAnchor = true
        }
        
        if virtualObject.shouldUpdateAnchor {
            virtualObject.shouldUpdateAnchor = false
            self.updateQueue.async {
                self.sceneView.addOrUpdateAnchor(for: virtualObject)
            }
        }
    }

    
    func setTransform(of virtualObject: VirtualObject, with result: ARRaycastResult) {
        virtualObject.simdWorldTransform = result.worldTransform
    }

    // MARK: - VirtualObjectSelectionViewControllerDelegate
    // - Tag: PlaceVirtualContent
    func virtualObjectSelectionViewController(didSelectObject object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
                self.connectObjects()
            }
            
        })
        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(didDeselectObject object: VirtualObject) {
        guard let objectIndex = virtualObjectLoader.dotObjects.firstIndex(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }
        virtualObjectLoader.removeVirtualObject(at: objectIndex)
        virtualObjectInteraction?.selectedObject = nil
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
    }

    // MARK: Object Loading UI

    func displayObjectLoadingUI() {
//        // Show progress indicator.
//        spinner.startAnimating()
//
//        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
//
//        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
//        spinner.stopAnimating()
//
//        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
//        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
//
//        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}
