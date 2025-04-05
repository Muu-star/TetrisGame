import Foundation
import UIKit

// テトリミノの種類を表す列挙型
enum TetrominoType: Int, CaseIterable {
    case I = 0
    case O = 1
    case T = 2
    case S = 3
    case Z = 4
    case J = 5
    case L = 6
    
    // テトリミノの色を定義
    var color: String {
        switch self {
        case .I: return "cyan"
        case .O: return "yellow"
        case .T: return "purple"
        case .S: return "green"
        case .Z: return "red"
        case .J: return "blue"
        case .L: return "orange"
        }
    }
}

// テトリミノの形状を定義する構造体
struct Tetromino {
    let type: TetrominoType
    var blocks: [[Bool]]
    var position: (row: Int, col: Int)
    
    // 各テトリミノの形状を定義
    static func create(type: TetrominoType) -> Tetromino {
        let blocks: [[Bool]]
        switch type {
        case .I:
            blocks = [
                [false, false, false, false],
                [true, true, true, true],
                [false, false, false, false],
                [false, false, false, false]
            ]
        case .O:
            blocks = [
                [true, true],
                [true, true]
            ]
        case .T:
            blocks = [
                [false, true, false],
                [true, true, true],
                [false, false, false]
            ]
        case .S:
            blocks = [
                [false, true, true],
                [true, true, false],
                [false, false, false]
            ]
        case .Z:
            blocks = [
                [true, true, false],
                [false, true, true],
                [false, false, false]
            ]
        case .J:
            blocks = [
                [true, false, false],
                [true, true, true],
                [false, false, false]
            ]
        case .L:
            blocks = [
                [false, false, true],
                [true, true, true],
                [false, false, false]
            ]
        }
        // 初期位置を画面上部中央に設定（十分なスペースを確保）
        let initialRow = -2  // 画面外から登場させる
        let initialCol = 3
        return Tetromino(type: type, blocks: blocks, position: (initialRow, initialCol))
    }
    
    // テトリミノを時計回りに回転させる
    mutating func rotate() {
        let rows = blocks.count
        let cols = blocks[0].count
        var newBlocks = Array(repeating: Array(repeating: false, count: rows), count: cols)
        
        for i in 0..<rows {
            for j in 0..<cols {
                newBlocks[j][rows - 1 - i] = blocks[i][j]
            }
        }
        blocks = newBlocks
    }
    
    // テトリミノを反時計回りに回転させる
    mutating func rotateCounterClockwise() {
        let rows = blocks.count
        let cols = blocks[0].count
        var newBlocks = Array(repeating: Array(repeating: false, count: rows), count: cols)
        
        for i in 0..<rows {
            for j in 0..<cols {
                newBlocks[cols - 1 - j][i] = blocks[i][j]
            }
        }
        blocks = newBlocks
    }
}

// ゲームボードを表現する構造体
struct GameBoard {
    let rows: Int
    let cols: Int
    var grid: [[TetrominoType?]]
    var currentTetromino: Tetromino?
    var nextTetromino: Tetromino?
    var score: Int = 0
    // 七種一巡のためのテトリミノバッグ
    var tetrominoBag: [TetrominoType] = []
    
    init(rows: Int = 20, cols: Int = 10) {
        self.rows = rows
        self.cols = cols
        self.grid = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        // 初期化時にテトリミノバッグを準備
        fillTetrominoBag()
        prepareTetrominoes()
    }
    
    // テトリミノバッグを満たす（七種一巡の実装）
    mutating private func fillTetrominoBag() {
        // バッグが空の場合のみ新しいセットを作成
        if tetrominoBag.isEmpty {
            // 全種類のテトリミノを用意
            tetrominoBag = TetrominoType.allCases
            // バッグをシャッフル
            tetrominoBag.shuffle()
        }
    }
    
    // 現在のテトリミノと次のテトリミノを準備する
    mutating private func prepareTetrominoes() {
        // 現在のテトリミノが存在しない場合、新しいテトリミノを設定
        if currentTetromino == nil {
            // バッグからテトリミノの種類を取り出し
            let type = tetrominoBag.removeFirst()
            // 新しいテトリミノを作成
            currentTetromino = Tetromino.create(type: type)
            
            // バッグが空になったら再び満たす
            if tetrominoBag.isEmpty {
                fillTetrominoBag()
            }
        }
        
        // 次のテトリミノが存在しない場合、新しいテトリミノを設定
        if nextTetromino == nil {
            // バッグからテトリミノの種類を取り出し
            let type = tetrominoBag.removeFirst()
            // 新しいテトリミノを作成
            nextTetromino = Tetromino.create(type: type)
            
            // バッグが空になったら再び満たす
            if tetrominoBag.isEmpty {
                fillTetrominoBag()
            }
        }
    }
    
    // 新しいテトリミノを生成する
    mutating func spawnNewTetromino() -> Bool {
        // 次のテトリミノを現在のテトリミノに設定
        currentTetromino = nextTetromino
        
        // バッグから新しいテトリミノの種類を取り出し
        let type = tetrominoBag.removeFirst()
        // 新しいテトリミノを作成
        nextTetromino = Tetromino.create(type: type)
        
        // バッグが空になったら再び満たす
        if tetrominoBag.isEmpty {
            fillTetrominoBag()
        }
        
        // テトリミノの生成が成功したかどうかを返す
        return currentTetromino != nil
    }
    
    // 現在のテトリミノを左に移動させる
    mutating func moveTetrominoLeft() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        
        // 左に移動した位置を計算
        let newCol = tetromino.position.col - 1
        
        // 移動先がボードの範囲内かチェック
        if newCol < 0 {
            return false
        }
        
        // 移動先に他のブロックがないかチェック
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = tetromino.position.row + i
                    let boardCol = newCol + j
                    
                    // ボードの範囲外または既にブロックがある場合は移動できない
                    if boardRow >= 0 && (boardCol < 0 || boardCol >= cols || grid[boardRow][boardCol] != nil) {
                        return false
                    }
                }
            }
        }
        
        // テトリミノを左に移動
        tetromino.position.col = newCol
        currentTetromino = tetromino
        return true
    }
    
    // 現在のテトリミノを右に移動させる
    mutating func moveTetrominoRight() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        
        // 右に移動した位置を計算
        let newCol = tetromino.position.col + 1
        
        // 移動先に他のブロックがないかチェック
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = tetromino.position.row + i
                    let boardCol = newCol + j
                    
                    // ボードの範囲外または既にブロックがある場合は移動できない
                    if boardRow >= 0 && (boardCol < 0 || boardCol >= cols || grid[boardRow][boardCol] != nil) {
                        return false
                    }
                }
            }
        }
        
        // テトリミノを右に移動
        tetromino.position.col = newCol
        currentTetromino = tetromino
        return true
    }
    
    // 現在のテトリミノを下に移動させる
    mutating func moveTetrominoDown() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        
        // 下に移動した位置を計算
        let newRow = tetromino.position.row + 1
        
        // 移動先に他のブロックがないかチェック
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = newRow + i
                    let boardCol = tetromino.position.col + j
                    
                    // ボードの範囲外または既にブロックがある場合は移動できない
                    if boardRow >= rows || (boardCol >= 0 && boardCol < cols && grid[boardRow][boardCol] != nil) {
                        // テトリミノを固定
                        fixTetromino()
                        return false
                    }
                }
            }
        }
        
        // テトリミノを下に移動
        tetromino.position.row = newRow
        currentTetromino = tetromino
        return true
    }
    
    // テトリミノを固定する
    mutating private func fixTetromino() {
        guard let tetromino = currentTetromino else { return }
        
        // テトリミノのブロックをグリッドに固定
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = tetromino.position.row + i
                    let boardCol = tetromino.position.col + j
                    
                    if boardRow >= 0 && boardRow < rows && boardCol >= 0 && boardCol < cols {
                        grid[boardRow][boardCol] = tetromino.type
                    }
                }
            }
        }
        
        // 現在のテトリミノをクリア
        currentTetromino = nil
        
        // 行の消去をチェック
        checkLineClears()
        
        // 新しいテトリミノを生成
        spawnNewTetromino()
    }
    
    // 行の消去をチェックする
    mutating private func checkLineClears() {
        var linesCleared = 0
        
        // 下から上に向かってチェック
        for row in (0..<rows).reversed() {
            // 行が完全に埋まっているかチェック
            if grid[row].allSatisfy({ $0 != nil }) {
                // 行を消去
                grid.remove(at: row)
                // 新しい空の行を追加
                grid.insert(Array(repeating: nil, count: cols), at: 0)
                linesCleared += 1
            }
        }
        
        // スコアを更新
        if linesCleared > 0 {
            score += linesCleared * 100
        }
    }
    
    // テトリミノを一気に下まで落とす
    mutating func hardDrop() {
        // テトリミノが固定されるまで下に移動
        while moveTetrominoDown() {
            // 移動可能な間は何もしない
        }
    }
    
    // 現在のテトリミノを回転させる
    mutating func rotateTetromino() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        
        // 回転前のブロックを保存
        let originalBlocks = tetromino.blocks
        
        // テトリミノを回転
        tetromino.rotate()
        
        // 回転後の位置が有効かチェック
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = tetromino.position.row + i
                    let boardCol = tetromino.position.col + j
                    
                    // ボードの範囲外または既にブロックがある場合は回転できない
                    if boardRow >= rows || boardCol < 0 || boardCol >= cols || (boardRow >= 0 && grid[boardRow][boardCol] != nil) {
                        // 回転を元に戻す
                        tetromino.blocks = originalBlocks
                        return false
                    }
                }
            }
        }
        
        // 回転を適用
        currentTetromino = tetromino
        return true
    }
    
    // 現在のテトリミノを反時計回りに回転させる
    mutating func rotateTetrominoCounterClockwise() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        
        // 回転前のブロックを保存
        let originalBlocks = tetromino.blocks
        
        // テトリミノを反時計回りに回転
        tetromino.rotateCounterClockwise()
        
        // 回転後の位置が有効かチェック
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = tetromino.position.row + i
                    let boardCol = tetromino.position.col + j
                    
                    // ボードの範囲外または既にブロックがある場合は回転できない
                    if boardRow >= rows || boardCol < 0 || boardCol >= cols || (boardRow >= 0 && grid[boardRow][boardCol] != nil) {
                        // 回転を元に戻す
                        tetromino.blocks = originalBlocks
                        return false
                    }
                }
            }
        }
        
        // 回転を適用
        currentTetromino = tetromino
        return true
    }
    
    // ゲームオーバーかどうかを判定する
    func isGameOver() -> Bool {
        // 現在のテトリミノが存在しない場合はゲームオーバーではない
        guard let tetromino = currentTetromino else { return false }
        
        // テトリミノの位置が画面上部を超えている場合はゲームオーバー
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let boardRow = tetromino.position.row + i
                    if boardRow < 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
