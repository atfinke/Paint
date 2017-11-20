//
//  GameViewController.swift
//  Paint macOS
//
//  Created by Andrew Finke on 10/15/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Cocoa
import SceneKit

class GameViewController: NSViewController {
    
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
        self.gameView.backgroundColor = NSColor.black
        

    }
    
    override func mouseMoved(with event: NSEvent) {
        print(1)
    }

    override func keyDown(with event: NSEvent) {
        gameController.launch()
    }
    
}
