//
//  VirtualTapeSDK+Actions.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//

import UIKit
import SceneKit
import ARKit

extension VirtualTapeSDK: UIGestureRecognizerDelegate {
    
    // MARK: - Interface Actions
    
    /// Displays the `VirtualObjectSelectionViewController` from the `addObjectButton` or in response to a tap gesture in the `sceneView`.
    public func addVirtualObject(name:String) {
        let newObject = VirtualObject()
        if let query = sceneView.getRaycastQuery(for: newObject.allowedAlignment),
            let result = sceneView.castRay(for: query).first {
            newObject.mostRecentInitialPlacementResult = result
            newObject.raycastQuery = query
            newObject.name = name
            newObject.nameIdentifier = name
        } else {
            newObject.mostRecentInitialPlacementResult = nil
            newObject.raycastQuery = nil
        }
        self.virtualObjectSelectionViewController(didSelectObject: newObject)
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Determines if the tap gesture for presenting the `VirtualObjectSelectionViewController` should be used.
    public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return virtualObjectLoader.dotObjects.isEmpty
    }
    
    public func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// - Tag: restartExperience
    func restartExperience() {
        guard isRestartAvailable, !virtualObjectLoader.isLoading else { return }
        isRestartAvailable = false

        //statusViewController.cancelAllScheduledMessages()

        virtualObjectLoader.removeAllVirtualObjects()
        virtualObjectLoader.removeAllLineNodes()
        virtualObjectLoader.removeAllTextNodes()
        //addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        //addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        resetTracking()

        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
            //self.upperControlsView.isHidden = false
        }
    }
}
