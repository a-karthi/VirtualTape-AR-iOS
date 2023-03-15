//
//  HomeViewController.swift
//  VirtualTape
//
//  Created by @karthi on 15/03/23.

import ARKit
import SceneKit
import UIKit

class HomeViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var arContainer: VirtualObjectARView!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    var pathIterator = 1
    
    private lazy var tapeSDKManager = VirtualTapeSDK(arContainer)

    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        tapeSDKManager.delegate = self
        tapeSDKManager.resetTracking()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        tapeSDKManager.pauseARSession()
    }
    
    @IBAction func backButtonAction(_ sender:Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addButtonAction(_ sender:Any) {
        let name = "Dot-Node-\(pathIterator)"
        tapeSDKManager.addVirtualObject(name: name)
        pathIterator += 1
    }
    
    @IBAction func resetAction(_ sender:Any) {
        pathIterator = 1
        self.tapeSDKManager.restartExperience()
    }
    
    // MARK: - Navigation
     class func initWithStory() -> HomeViewController? {
         let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController
         return vc
     }
}


extension HomeViewController: VirtualTapeDelegate {
    
}
