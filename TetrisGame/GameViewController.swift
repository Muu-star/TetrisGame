//
//  GameViewController.swift
//  TetrisGame
//
//  Created by TOKITA HIROMU on 2025/03/29.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // シーンのサイズを画面サイズに合わせる
        if let view = self.view as! SKView? {
            // シーンを作成
            let scene = GameScene(size: view.bounds.size)
            
            // ScaleMode を .aspectFill に設定
            scene.scaleMode = .aspectFill
            
            // シーンを表示
            view.presentScene(scene)
            
            // デバッグ情報を表示（開発中のみ）
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
