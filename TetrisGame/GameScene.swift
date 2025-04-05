import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // ゲーム関連のプロパティ
    private var gameBoard: GameBoard!
    private var blockSize: CGFloat = 14.0  // ブロックサイズをさらに小さくして画面に収まるようにする
    private var boardNode: SKNode!
    private var dropInterval: TimeInterval = 1.0  // 自動下降の間隔（秒）
    private var lastDropTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    
    // スコア表示用
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    
    // 操作ボタン用
    private var leftButton: SKShapeNode!
    private var rightButton: SKShapeNode!
    private var downButton: SKShapeNode!
    private var upButton: SKShapeNode!  // 上ボタン（ハードドロップ用）
    private var rotateLeftButton: SKShapeNode!
    private var rotateRightButton: SKShapeNode!
    
    // ゲームボードの位置調整用のオフセット
    private var boardOffset: CGPoint {
        let x = (size.width - CGFloat(gameBoard.cols) * blockSize) / 2
        let y = (size.height - CGFloat(gameBoard.rows) * blockSize) / 2
        return CGPoint(x: x, y: y)
    }
    
    // ゲームオーバー関連
    private var isGameOver = false
    private var gameOverNode: SKNode?
    
    // 次のテトリミノ表示用
    private var nextTetrominoNode: SKNode?
    
    // 初期化
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        
        // ゲームボードの初期化
        gameBoard = GameBoard()
        
        // ゲームボードのノードを作成
        boardNode = SKNode()
        addChild(boardNode)
        
        // グリッドの描画
        drawGrid()
        
        // 操作ボタンの設定
        setupControlButtons()
        
        // スコアラベルの初期化
        setupScoreLabel()
        
        // 次のテトリミノラベルの初期化
        setupNextTetrominoLabel()
        
        // 最初のテトリミノを生成
        gameBoard.spawnNewTetromino()
        updateDisplay()
    }
    
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "Arial-Bold"
        scoreLabel.fontSize = 20
        scoreLabel.position = CGPoint(x: size.width - 100, y: size.height - 30)
        scoreLabel.horizontalAlignmentMode = .right
        addChild(scoreLabel)
    }
    
    private func setupNextTetrominoLabel() {
        // グリッドの右端座標を計算
        let gridRightEdge = boardOffset.x + CGFloat(gameBoard.cols) * blockSize
        
        let nextLabel = SKLabelNode(text: "Next")
        nextLabel.fontName = "Arial-Bold"
        nextLabel.fontSize = 18
        nextLabel.position = CGPoint(x: gridRightEdge + 60, y: size.height - 60)
            addChild(nextLabel)
        
        // 次のテトリミノ表示用ノード
            nextTetrominoNode = SKNode()
            nextTetrominoNode?.position = CGPoint(x: gridRightEdge + 60, y: size.height - 100)
            addChild(nextTetrominoNode!)
        }
    
    private func setupControlButtons() {
        // 十字キーの中心位置
        let centerX: CGFloat = 100
        let centerY: CGFloat = size.height/2
        let buttonRadius: CGFloat = 30
        let buttonSpacing: CGFloat = 80  // ボタン間の距離
        
        // 左ボタン
        leftButton = createDirectionButton(
            position: CGPoint(x: centerX - buttonSpacing/2, y: centerY),
            name: "leftButton",
            symbolPoints: [CGPoint(x: -10, y: 0), CGPoint(x: 5, y: 15), CGPoint(x: 5, y: -15)]
        )
        
        // 右ボタン
        rightButton = createDirectionButton(
            position: CGPoint(x: centerX + buttonSpacing/2, y: centerY),
            name: "rightButton",
            symbolPoints: [CGPoint(x: 10, y: 0), CGPoint(x: -5, y: 15), CGPoint(x: -5, y: -15)]
        )
        
        // 下ボタン
        downButton = createDirectionButton(
            position: CGPoint(x: centerX, y: centerY - buttonSpacing/2),
            name: "downButton",
            symbolPoints: [CGPoint(x: 0, y: -10), CGPoint(x: 15, y: 5), CGPoint(x: -15, y: 5)]
        )
        
        // 上ボタン（ハードドロップ）
        upButton = createDirectionButton(
            position: CGPoint(x: centerX, y: centerY + buttonSpacing/2),
            name: "upButton",
            symbolPoints: [CGPoint(x: 0, y: 10), CGPoint(x: 15, y: -5), CGPoint(x: -15, y: -5)]
        )
        
        // 右回転ボタン
        rotateRightButton = createRotationButton(
            position: CGPoint(x: size.width - 70, y: size.height/2),
            name: "rotateRightButton",
            clockwise: true
        )
        
        // 左回転ボタン
        rotateLeftButton = createRotationButton(
            position: CGPoint(x: size.width - 130, y: size.height/2),
            name: "rotateLeftButton",
            clockwise: false
        )
    }
    
    private func createDirectionButton(position: CGPoint, name: String, symbolPoints: [CGPoint]) -> SKShapeNode {
        // ボタンの背景
        let button = SKShapeNode(circleOfRadius: 30)
        button.position = position
        button.fillColor = .darkGray
        button.strokeColor = .lightGray
        button.alpha = 0.7
        button.name = name
        
        // 矢印記号
        let arrow = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: symbolPoints[0])
        path.addLine(to: symbolPoints[1])
        path.addLine(to: symbolPoints[2])
        path.close()
        arrow.path = path.cgPath
        arrow.fillColor = .white
        arrow.strokeColor = .clear
        
        button.addChild(arrow)
        addChild(button)
        return button
    }
    
    private func createRotationButton(position: CGPoint, name: String, clockwise: Bool) -> SKShapeNode {
        // ボタンの背景
        let button = SKShapeNode(circleOfRadius: 30)
        button.position = position
        button.fillColor = .darkGray
        button.strokeColor = .lightGray
        button.alpha = 0.7
        button.name = name
        
        // 回転記号
        let symbol = SKShapeNode(circleOfRadius: 15)
        symbol.strokeColor = .white
        symbol.lineWidth = 2
        symbol.fillColor = .clear
        
        // 矢印
        let arrow = SKShapeNode()
        let arrowPath = UIBezierPath()
        if clockwise {
            arrowPath.move(to: CGPoint(x: 15, y: 0))
            arrowPath.addLine(to: CGPoint(x: 22, y: 0))
            arrowPath.addLine(to: CGPoint(x: 18, y: 7))
        } else {
            arrowPath.move(to: CGPoint(x: -15, y: 0))
            arrowPath.addLine(to: CGPoint(x: -22, y: 0))
            arrowPath.addLine(to: CGPoint(x: -18, y: 7))
        }
        arrowPath.close()
        arrow.path = arrowPath.cgPath
        arrow.fillColor = .white
        arrow.strokeColor = .clear
        
        button.addChild(symbol)
        button.addChild(arrow)
        addChild(button)
        return button
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // ゲームオーバー時のリスタートボタン処理
        if isGameOver {
            let nodes = self.nodes(at: location)
            for node in nodes {
                if node.name == "restartButton" {
                    restartGame()
                    return
                }
            }
            return
        }
        
        // 操作ボタンのタッチ処理
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "leftButton" || node.parent?.name == "leftButton" {
                if gameBoard.moveTetrominoLeft() {
                    updateDisplay()
                }
                return
            } else if node.name == "rightButton" || node.parent?.name == "rightButton" {
                if gameBoard.moveTetrominoRight() {
                    updateDisplay()
                }
                return
            } else if node.name == "downButton" || node.parent?.name == "downButton" {
                if gameBoard.moveTetrominoDown() {
                    updateDisplay()
                }
                return
            } else if node.name == "upButton" || node.parent?.name == "upButton" {
                // 上ボタンでハードドロップを実行
                gameBoard.hardDrop()
                updateDisplay()
                return
            } else if node.name == "rotateRightButton" || node.parent?.name == "rotateRightButton" {
                if gameBoard.rotateTetromino() {
                    updateDisplay()
                }
                return
            } else if node.name == "rotateLeftButton" || node.parent?.name == "rotateLeftButton" {
                if gameBoard.rotateTetrominoCounterClockwise() {
                    updateDisplay()
                }
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タッチ移動処理なし
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タッチ終了処理なし
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タッチキャンセル処理なし
    }
    
    override func update(_ currentTime: TimeInterval) {
        // ゲームオーバー時は更新しない
        if isGameOver {
            return
        }
        
        // 初期化
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            lastDropTime = currentTime
        }
        
        // 自動下降の処理
        if currentTime - lastDropTime > dropInterval {
            if !gameBoard.moveTetrominoDown() {
                // 下に移動できない場合、ブロックが固定される
                // 新しいテトリミノを生成（またはゲームオーバー処理）
                if !gameBoard.spawnNewTetromino() {
                    showGameOver()
                }
            }
            updateDisplay()
            lastDropTime = currentTime
        }
        
        lastUpdateTime = currentTime
    }
    
    // グリッドを描画する関数
    private func drawGrid() {
        for row in 0..<gameBoard.rows {
            for col in 0..<gameBoard.cols {
                let block = SKShapeNode(rectOf: CGSize(width: blockSize, height: blockSize))
                block.position = positionForBlock(row: row, col: col)
                block.strokeColor = .darkGray
                block.lineWidth = 1
                block.fillColor = .black
                boardNode.addChild(block)
            }
        }
    }
    
    // ブロックの位置を計算する関数
    private func positionForBlock(row: Int, col: Int) -> CGPoint {
        let x = boardOffset.x + CGFloat(col) * blockSize + blockSize / 2
        let y = boardOffset.y + CGFloat(gameBoard.rows - 1 - row) * blockSize + blockSize / 2
        return CGPoint(x: x, y: y)
    }
    
    // テトリミノを描画する関数
    private func drawTetromino() {
        guard let tetromino = gameBoard.currentTetromino else { return }
        
        // 既存のテトリミノノードを削除
        boardNode.children.forEach { node in
            if node.name == "tetromino" {
                node.removeFromParent()
            }
        }
        
        // 新しいテトリミノを描画
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let block = SKShapeNode(rectOf: CGSize(width: blockSize, height: blockSize))
                    block.position = positionForBlock(
                        row: tetromino.position.row + i,
                        col: tetromino.position.col + j
                    )
                    // カラー名ではなく直接UIColorを使用
                    let blockColor: UIColor
                    switch tetromino.type {
                    case .I: blockColor = .cyan
                    case .O: blockColor = .yellow
                    case .T: blockColor = .purple
                    case .S: blockColor = .green
                    case .Z: blockColor = .red
                    case .J: blockColor = .blue
                    case .L: blockColor = .orange
                    }
                    block.fillColor = blockColor
                    block.strokeColor = .white
                    block.name = "tetromino"
                    boardNode.addChild(block)
                }
            }
        }
    }
    
    // 次のテトリミノを描画する関数
    private func drawNextTetromino() {
        guard let nextTetromino = gameBoard.nextTetromino else { return }
        
        // 既存のプレビューを削除
        nextTetrominoNode?.removeAllChildren()
        
        let previewBlockSize = blockSize * 0.8  // 少し小さめに表示
        
        // 中央揃えのためのオフセット計算
        let maxWidth = 4 * previewBlockSize // 最大幅（I型テトリミノの幅）
        let tetrominoWidth = CGFloat(nextTetromino.blocks[0].count) * previewBlockSize
        let offsetX = (maxWidth - tetrominoWidth) / 2
        
        // 次のテトリミノを描画
        for i in 0..<nextTetromino.blocks.count {
            for j in 0..<nextTetromino.blocks[i].count {
                if nextTetromino.blocks[i][j] {
                    let block = SKShapeNode(rectOf: CGSize(width: previewBlockSize, height: previewBlockSize))
                    block.position = CGPoint(
                        x: CGFloat(j) * previewBlockSize,
                        y: -CGFloat(i) * previewBlockSize
                    )
                    
                    // 色の設定
                    let blockColor: UIColor
                    switch nextTetromino.type {
                    case .I: blockColor = .cyan
                    case .O: blockColor = .yellow
                    case .T: blockColor = .purple
                    case .S: blockColor = .green
                    case .Z: blockColor = .red
                    case .J: blockColor = .blue
                    case .L: blockColor = .orange
                    }
                    
                    block.fillColor = blockColor
                    block.strokeColor = .white
                    nextTetrominoNode?.addChild(block)
                }
            }
        }
<<<<<<< HEAD
        // 次の4つまでのテトリミノを表示
            displayNextTetrominoes()
    }
    // GameScene.swiftファイルのdisplayDummyNextTetrominoes()メソッドを修正

    private func displayNextTetrominoes() {
        // 実際の次のテトリミノを表示するように修正
        guard let gameBoard = gameBoard, let nextTetromino = gameBoard.nextTetromino else { return }
        
        // 現在のバッグの内容を取得（実際のゲーム状態を反映）
        let upcomingPieces = gameBoard.tetrominoBag
        
        // 最初に次のテトリミノ（既に決定されているもの）を表示
        let previewBlockSize = blockSize * 0.8
        
        // 次のテトリミノの表示（既存のコードを利用）
        // 既存のプレビューを削除
        nextTetrominoNode?.removeAllChildren()
        
        // 中央揃えのためのオフセット計算
        let maxWidth = 4 * previewBlockSize // 最大幅（I型テトリミノの幅）
        let tetrominoWidth = CGFloat(nextTetromino.blocks[0].count) * previewBlockSize
        let offsetX = (maxWidth - tetrominoWidth) / 2
        
        // 次のテトリミノを描画
        for i in 0..<nextTetromino.blocks.count {
            for j in 0..<nextTetromino.blocks[i].count {
                if nextTetromino.blocks[i][j] {
                    let block = SKShapeNode(rectOf: CGSize(width: previewBlockSize, height: previewBlockSize))
                    block.position = CGPoint(
                        x: CGFloat(j) * previewBlockSize,
                        y: -CGFloat(i) * previewBlockSize
                    )
                    
                    // 色の設定
                    let blockColor: UIColor
                    switch nextTetromino.type {
                    case .I: blockColor = .cyan
                    case .O: blockColor = .yellow
                    case .T: blockColor = .purple
                    case .S: blockColor = .green
                    case .Z: blockColor = .red
                    case .J: blockColor = .blue
                    case .L: blockColor = .orange
                    }
                    
                    block.fillColor = blockColor
                    block.strokeColor = .white
                    nextTetrominoNode?.addChild(block)
                }
            }
        }
        
        // バッグに残っているテトリミノを順に表示（最大4つまで）
        let displayCount = min(upcomingPieces.count, 4)
        
        for i in 0..<displayCount {
            let yOffset = -CGFloat(i + 1) * (blockSize * 4) // 各テトリミノの間隔
            
            let pieceNode = SKNode()
            pieceNode.position = CGPoint(x: 0, y: yOffset)
            
            // バッグの中のテトリミノを表示
            let dummyTetromino = Tetromino.create(type: upcomingPieces[i])
=======
        // 次の4つのテトリミノをシミュレートして表示
        // 実際のゲームロジックには実装されていないため、ダミーデータを表示
        displayDummyNextTetrominoes()
        
    }
    private func displayDummyNextTetrominoes() {
        // サンプルとして4つの追加テトリミノを表示
        let tetrominoTypes: [TetrominoType] = [.L, .I, .T, .Z] // サンプルのタイプ（ランダムな順序）
        
        for i in 0..<4 {
            let yOffset = -CGFloat(i + 1) * (blockSize * 4) // 各テトリミノの間隔
            
            let dummyNode = SKNode()
            dummyNode.position = CGPoint(x: 0, y: yOffset)
            
            // サンプルテトリミノの作成
            let dummyTetromino = Tetromino.create(type: tetrominoTypes[i])
            let previewBlockSize = blockSize * 0.8
>>>>>>> 916ff9b22dc415264a9003e9c47ef9d1aa7c8190
            
            // 中央揃えのためのオフセット計算
            let maxWidth = 4 * previewBlockSize
            let tetrominoWidth = CGFloat(dummyTetromino.blocks[0].count) * previewBlockSize
            let offsetX = (maxWidth - tetrominoWidth) / 2
            
            // テトリミノを描画
            for row in 0..<dummyTetromino.blocks.count {
                for col in 0..<dummyTetromino.blocks[row].count {
                    if dummyTetromino.blocks[row][col] {
                        let block = SKShapeNode(rectOf: CGSize(width: previewBlockSize, height: previewBlockSize))
                        block.position = CGPoint(
                            x: offsetX + CGFloat(col) * previewBlockSize,
                            y: -CGFloat(row) * previewBlockSize
                        )
                        
                        // 色の設定
                        let blockColor: UIColor
                        switch dummyTetromino.type {
                        case .I: blockColor = .cyan
                        case .O: blockColor = .yellow
                        case .T: blockColor = .purple
                        case .S: blockColor = .green
                        case .Z: blockColor = .red
                        case .J: blockColor = .blue
                        case .L: blockColor = .orange
                        }
                        
                        block.fillColor = blockColor
                        block.strokeColor = .white
<<<<<<< HEAD
                        pieceNode.addChild(block)
=======
                        dummyNode.addChild(block)
>>>>>>> 916ff9b22dc415264a9003e9c47ef9d1aa7c8190
                    }
                }
            }
            
<<<<<<< HEAD
            nextTetrominoNode?.addChild(pieceNode)
=======
            nextTetrominoNode?.addChild(dummyNode)
>>>>>>> 916ff9b22dc415264a9003e9c47ef9d1aa7c8190
        }
    }
    // 固定されたブロックを描画する関数
    private func drawFixedBlocks() {
        // 既存の固定ブロックノードを削除
        boardNode.children.forEach { node in
            if node.name == "fixed" {
                node.removeFromParent()
            }
        }
        
        // 固定されたブロックを描画
        for row in 0..<gameBoard.rows {
            for col in 0..<gameBoard.cols {
                if let type = gameBoard.grid[row][col] {
                    let block = SKShapeNode(rectOf: CGSize(width: blockSize, height: blockSize))
                    block.position = positionForBlock(row: row, col: col)
                    // カラー名ではなく直接UIColorを使用
                    let blockColor: UIColor
                    switch type {
                    case .I: blockColor = .cyan
                    case .O: blockColor = .yellow
                    case .T: blockColor = .purple
                    case .S: blockColor = .green
                    case .Z: blockColor = .red
                    case .J: blockColor = .blue
                    case .L: blockColor = .orange
                    }
                    block.fillColor = blockColor
                    block.strokeColor = .white
                    block.name = "fixed"
                    boardNode.addChild(block)
                }
            }
        }
    }
    
    // 表示を更新する関数
    private func updateDisplay() {
        drawFixedBlocks()
        drawTetromino()
        drawNextTetromino()
        
        // スコア表示も更新
        scoreLabel.text = "Score: \(gameBoard.score)"
    }
    
    // ゲームオーバー時の処理
    private func showGameOver() {
        isGameOver = true
        
        // ゲームオーバー表示用のノード
        gameOverNode = SKNode()
        
        // 半透明の背景
        let background = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        background.fillColor = UIColor.black.withAlphaComponent(0.7)
        background.strokeColor = .clear
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        gameOverNode!.addChild(background)
        
        // ゲームオーバーテキスト
        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontName = "Arial-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 50)
        gameOverNode!.addChild(gameOverLabel)
        
        // スコア表示
        let finalScoreLabel = SKLabelNode(text: "Final Score: \(gameBoard.score)")
        finalScoreLabel.fontName = "Arial"
        finalScoreLabel.fontSize = 30
        finalScoreLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        gameOverNode!.addChild(finalScoreLabel)
        
        // リスタートボタン
        let restartButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        restartButton.fillColor = .blue
        restartButton.strokeColor = .white
        restartButton.position = CGPoint(x: size.width/2, y: size.height/2 - 70)
        restartButton.name = "restartButton"
        
        let restartLabel = SKLabelNode(text: "Restart")
        restartLabel.fontName = "Arial"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .white
        restartLabel.verticalAlignmentMode = .center
        restartButton.addChild(restartLabel)
        
        gameOverNode!.addChild(restartButton)
        addChild(gameOverNode!)
    }
    
    // ゲームをリスタートする関数
    private func restartGame() {
        // ゲームオーバーノードを削除
        gameOverNode?.removeFromParent()
        gameOverNode = nil
        
        // ゲームボードをリセット
        gameBoard = GameBoard()
        
        // 既存のブロックを削除
        boardNode.removeAllChildren()
        
        // グリッドの再描画
        drawGrid()
        
        // 最初のテトリミノを生成
        gameBoard.spawnNewTetromino()
        
        // 表示を更新
        updateDisplay()
        
        // ゲームオーバーフラグをリセット
        isGameOver = false
    }
}
