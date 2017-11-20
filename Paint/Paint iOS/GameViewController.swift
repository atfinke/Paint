//
//  GameViewController.swift
//  Paint iOS
//
//  Created by Andrew Finke on 10/15/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {

    var gameView: SCNView {
        return self.view as! SCNView
    }
    
    var gameController: GameController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gameController = GameController(sceneRenderer: gameView)
        
        // Allow the user to manipulate the camera
        self.gameView.allowsCameraControl = true
        
        // Show statistics such as fps and timing information
        self.gameView.showsStatistics = true
        
        // Configure the view
        self.gameView.backgroundColor = UIColor.black
        
        // Add a tap gesture recognizer

        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        var gestureRecognizers = gameView.gestureRecognizers ?? []
        gestureRecognizers.insert(tapGesture, at: 0)
        self.gameView.gestureRecognizers = gestureRecognizers
    }
    
    @objc
    func handleTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .changed {
            gameController.launch()
        }
    }

    var touchCount = 1

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
super.touchesBegan(touches, with: event)
        touchCount += 1
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
            if self.touchCount == 2 {
                self.gameController.launch()
            } else {
                timer.invalidate()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchCount -= 1
        super.touchesEnded(touches, with: event)
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
