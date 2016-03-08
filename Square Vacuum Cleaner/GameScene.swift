//
//  GameScene.swift
//  Square Vacuum Cleaner
//
//  Created by Greg Willis on 3/7/16.
//  Copyright (c) 2016 Willis Programming. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var player: SKSpriteNode!
    var collectable: SKSpriteNode!
    
    var mainLabel: SKLabelNode!
    var scoreLabel: SKLabelNode!
    
    var touchLocation: CGPoint!
    
    var score = 0
    var playerSpeed = 0.7
    var collectableSpawnSpeed = 1.0
    var countDownTimer = 22
    
    var offBlackColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    var offWhiteColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    var darkRedColor = UIColor(red: (190/255), green: 0, blue: 0, alpha: 1.0)
    
    override func didMoveToView(view: SKView) {
        backgroundColor = darkRedColor
        physicsWorld.contactDelegate = self
        spawnPlayer()
        spawnMainLabel()
        spawnScoreLabel()
        collectableSpawnTimer()
        countDownTimerLogic()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch in touches {
            touchLocation = touch.locationInNode(self)
            rotatePlayer()
            movePlayerToTouch()
            
        }
    }
   
    override func update(currentTime: CFTimeInterval) {

    }
}

// MARK: - Spawn Functions
extension GameScene {
    
    func spawnPlayer() {
        player = SKSpriteNode(color: offWhiteColor, size: CGSize(width: 50, height: 50))
        player.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.collectable
        player.physicsBody?.dynamic = false
        addChild(player)
    }
    
    func spawnCollectable() {
        collectable = SKSpriteNode(color: offBlackColor, size: CGSize(width: 20, height: 20))
        let frameWidth = UInt32(CGRectGetMaxX(self.frame))
        let randomX = Int(arc4random_uniform(frameWidth))
        let frameHeight = UInt32(CGRectGetMaxY(self.frame))
        let randomY = Int(arc4random_uniform(frameHeight))
        collectable.position = CGPoint(x: randomX, y: randomY)
        collectable.physicsBody = SKPhysicsBody(rectangleOfSize: collectable.size)
        collectable.physicsBody?.affectedByGravity = false
        collectable.physicsBody?.categoryBitMask = PhysicsCategory.collectable
        collectable.physicsBody?.contactTestBitMask = PhysicsCategory.player
        collectable.physicsBody?.dynamic = true
        collectable.zPosition = -1
        collectable.name = "collectable"
        addChild(collectable)
    }
    
    func spawnMainLabel() {
        mainLabel = SKLabelNode(fontNamed: "Futura")
        mainLabel.fontSize = CGRectGetMaxY(self.frame) * 0.2
        mainLabel.fontColor = offWhiteColor
        mainLabel.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMaxY(self.frame) * 0.8)
        mainLabel.text = "Start"
        addChild(mainLabel)
    }
    
    func spawnScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Futura")
        scoreLabel.fontSize = CGRectGetMaxY(self.frame) * 0.1
        scoreLabel.fontColor = offWhiteColor
        scoreLabel.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMaxY(self.frame) * 0.1)
        scoreLabel.text = "Score: \(score)"
        addChild(scoreLabel)
    }
}

// MARK: - Player movement functions
extension GameScene {
    
    func rotatePlayer() {
        let angle = atan2(touchLocation.y - player.position.y, touchLocation.x - player.position.x)
        player.zRotation = angle - CGFloat(M_PI_2)

    }
    
    func movePlayerToTouch() {
        let position = CGPoint(x: touchLocation.x, y: touchLocation.y)
        let moveForward = SKAction.moveTo(position, duration: playerSpeed)
        player.runAction(moveForward)
    }
}

// MARK: - Timer functions
extension GameScene {
    
    func collectableSpawnTimer() {
        let wait = SKAction.waitForDuration(collectableSpawnSpeed)
        let spawner = SKAction.runBlock {
            self.spawnCollectable()
        }
        let sequence = SKAction.sequence([wait, spawner])
        runAction(SKAction.repeatActionForever(sequence))
    }
    
    func countDownTimerLogic() {
        let wait = SKAction.waitForDuration(1.0)
        let countDown = SKAction.runBlock {
            self.countDownTimer--
            
            if self.countDownTimer <= 20 && self.countDownTimer > 0 {
                self.mainLabel.alpha = 0.5
                self.mainLabel.text = "\(self.countDownTimer)"
            }
            
            if self.countDownTimer < 0 {
                self.gameOverLogic()
            }
        }
        let sequence = SKAction.sequence([wait, countDown])
        runAction(SKAction.repeatActionForever(sequence))
    }
}

// MARK: - Physicsbody functions
extension GameScene: SKPhysicsContactDelegate {
    
    struct PhysicsCategory {
        static let player: UInt32 = 1
        static let collectable: UInt32 = 2
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody = contact.bodyA
        let secondBody: SKPhysicsBody = contact.bodyB
        
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.collectable ) || (firstBody.categoryBitMask == PhysicsCategory.collectable && secondBody.categoryBitMask == PhysicsCategory.player) {
            
            if let firstNode = firstBody.node as? SKSpriteNode, secondNode = secondBody.node as? SKSpriteNode {
                collectableContactLogic(firstNode, playerTemp:  secondNode)
            }
        }
            
    }
    
    func collectableContactLogic(collectableTemp: SKSpriteNode, playerTemp: SKSpriteNode) {
        
        if collectableTemp.name == collectable.name {
            collectableTemp.removeFromParent()
        }
        if collectableTemp.name != collectable.name {
            playerTemp.removeFromParent()
        }
        score++
        updateScore()
    }
}

// MARK: - Helper functions
extension GameScene {
    
    func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }
    
    func gameOverLogic() {
        player.removeFromParent()
        collectable.removeFromParent()
        mainLabel.fontSize = CGRectGetMaxY(self.frame) * 0.1
        mainLabel.alpha = 1.0
        mainLabel.text = "Game Over"
        
        let wait = SKAction.waitForDuration(3.5)
        let transition = SKAction.runBlock {
            if let view = self.view {
                if let gameScene = GameScene(fileNamed: "GameScene") {
                    view.ignoresSiblingOrder = true
                    gameScene.scaleMode = .ResizeFill
                    view.presentScene(gameScene, transition: SKTransition.doorwayWithDuration(1.0))
                }
            }
        }
        let sequence = SKAction.sequence([wait, transition])
        runAction(SKAction.repeatAction(sequence, count: 1))
    }
    
    
}