
//
//  VirtualTapeSDK+CoachingOverlay.swift
//  VirtualTapeSDK
//
//  Created by @karthi on 18/01/23.
//


import UIKit
import ARKit

/// - Tag: CoachingOverlayViewDelegate
extension VirtualTapeSDK: ARCoachingOverlayViewDelegate {
    
    /// - Tag: HideUI
    public func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        //upperControlsView.isHidden = true
    }
    
    /// - Tag: PresentUI
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        //upperControlsView.isHidden = false
    }

    /// - Tag: StartOver
    public func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        restartExperience()
    }

    func setupCoachingOverlay(_ arContainerView: UIView) {
        // Set up coaching view
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: arContainerView.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: arContainerView.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: arContainerView.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: arContainerView.heightAnchor)
            ])
        
        setActivatesAutomatically()
        
        // Most of the virtual objects in this sample require a horizontal surface,
        // therefore coach the user to find a horizontal plane.
        setGoal()
    }
    
    /// - Tag: CoachingActivatesAutomatically
    func setActivatesAutomatically() {
        coachingOverlay.activatesAutomatically = true
    }

    /// - Tag: CoachingGoal
    func setGoal() {
        coachingOverlay.goal = .horizontalPlane
    }
}
