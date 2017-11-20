//
//  TargetNode.swift
//  Paint
//
//  Created by Andrew Finke on 10/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import SceneKit
import SpriteKit

class TargetNode: SCNNode {

    override init() {
        super.init()

        let geometry = SCNCylinder(radius: 2, height: 0.25)
        self.geometry = geometry

        name = "targetNode"
        position = SCNVector3(0,0,-5)
        rotation = SCNVector4(1, 0, 0, SCNFloat.pi / 2)


        let spriteScene = SKScene(size: CGSize(width: 150.0, height: 150.0))
        spriteScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spriteScene.backgroundColor = SCNColor.clear

        let texture = SKTexture(image: #imageLiteral(resourceName: "Target"))
        let target = SKSpriteNode(texture: texture)
        target.size = spriteScene.size
        spriteScene.addChild(target)

        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = spriteScene
        planeMaterial.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(-1, -1, 1), 1, 1, 0)
        

        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = SCNColor.white
        let targetMaterial = SCNMaterial()
        targetMaterial.diffuse.contents = #imageLiteral(resourceName: "Target")
        geometry.materials = [sideMaterial, planeMaterial, targetMaterial]

        
        let physicsBody = SCNPhysicsBody(type: .static,
                                         shape: SCNPhysicsShape(geometry: geometry, options: nil))

        physicsBody.categoryBitMask = Int(PhysicsCategory.Target)
        physicsBody.collisionBitMask = Int(PhysicsCategory.PaintBall)


        self.physicsBody = physicsBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didHit(color: SCNColor) {
        let particleSystem = SCNParticleSystem(named: "plok.scnp", inDirectory: "Art.scnassets")!
        particleSystem.particleColor = color
        let particleSystemNode = SCNNode()
        particleSystemNode.addParticleSystem(particleSystem)
      //  particleSystemNode.position = contact.contactPoint

        addChildNode(particleSystemNode)



      //  runAction(.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: 1.0))

    }
}
