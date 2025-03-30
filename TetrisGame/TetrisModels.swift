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
    
    init(rows: Int = 20, cols: Int = 10) {
        self.rows = rows
        self.cols = cols
        self.grid = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        prepareTetrominoes()
    }
    
    // テトリミノを準備する
    mutating private func prepareTetrominoes() {
        if nextTetromino == nil {
            nextTetromino = Tetromino.create(type: TetrominoType.allCases.randomElement()!)
        }
    }
    
    // 新しいテトリミノを生成
    mutating func spawnNewTetromino() -> Bool {
        prepareTetrominoes()
        currentTetromino = nextTetromino
        nextTetromino = Tetromino.create(type: TetrominoType.allCases.randomElement()!)
        
        // ゲームオーバー判定 - 実際に衝突する場合のみゲームオーバーにする
        if let tetromino = currentTetromino {
            if !isValidPosition(tetromino) {
                // 表示可能領域内で衝突がある場合のみゲームオーバー
                for i in 0..<tetromino.blocks.count {
                    for j in 0..<tetromino.blocks[i].count {
                        if tetromino.blocks[i][j] {
                            let row = tetromino.position.row + i
                            if row >= 0 && row < rows { // 画面内のブロックのみチェック
                                let col = tetromino.position.col + j
                                if col >= 0 && col < cols && grid[row][col] != nil {
                                    return false // 有効な画面内でブロックが衝突 -> ゲームオーバー
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    // テトリミノを下に移動
    mutating func moveTetrominoDown() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        tetromino.position.row += 1
        
        if isValidPosition(tetromino) {
            currentTetromino = tetromino
            return true
        }
        
        // 移動できない場合は固定
        lockTetromino()
        return false
    }
    
    // テトリミノを左に移動
    mutating func moveTetrominoLeft() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        tetromino.position.col -= 1
        
        if isValidPosition(tetromino) {
            currentTetromino = tetromino
            return true
        }
        return false
    }
    
    // テトリミノを右に移動
    mutating func moveTetrominoRight() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        tetromino.position.col += 1
        
        if isValidPosition(tetromino) {
            currentTetromino = tetromino
            return true
        }
        return false
    }
    
    // テトリミノを時計回りに回転
    mutating func rotateTetromino() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        tetromino.rotate()
        
        if isValidPosition(tetromino) {
            currentTetromino = tetromino
            return true
        }
        return false
    }
    
    // テトリミノを反時計回りに回転
    mutating func rotateTetrominoCounterClockwise() -> Bool {
        guard var tetromino = currentTetromino else { return false }
        tetromino.rotateCounterClockwise()
        
        if isValidPosition(tetromino) {
            currentTetromino = tetromino
            return true
        }
        return false
    }
    
    // ハードドロップ機能
    mutating func hardDrop() {
        guard var tetromino = currentTetromino else { return }
        
        // 衝突するまで下に移動
        while true {
            tetromino.position.row += 1
            if !isValidPosition(tetromino) {
                tetromino.position.row -= 1
                break
            }
        }
        
        currentTetromino = tetromino
        lockTetromino()
    }
    
    // テトリミノの位置が有効かチェック（ゲームエリア外の場合にも対応）
    private func isValidPosition(_ tetromino: Tetromino) -> Bool {
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let row = tetromino.position.row + i
                    let col = tetromino.position.col + j
                    
                    // 左右と下の範囲チェック（上は画面外からの登場を許可）
                    if col < 0 || col >= cols || row >= rows {
                        return false
                    }
                    
                    // 画面内にある場合のみブロックとの衝突チェック
                    if row >= 0 && grid[row][col] != nil {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    // テトリミノを固定する
    mutating private func lockTetromino() {
        guard let tetromino = currentTetromino else { return }
        
        // テトリミノのブロックをグリッドに固定
        for i in 0..<tetromino.blocks.count {
            for j in 0..<tetromino.blocks[i].count {
                if tetromino.blocks[i][j] {
                    let row = tetromino.position.row + i
                    let col = tetromino.position.col + j
                    if row >= 0 && row < rows && col >= 0 && col < cols {
                        grid[row][col] = tetromino.type
                    }
                }
            }
        }
        
        // ラインの消去とスコアの更新
        clearLines()
        
        // 現在のテトリミノをクリア（新しいテトリミノは別のメソッドで生成）
        currentTetromino = nil
    }
    
    // ラインを消去する
    mutating private func clearLines() {
        var linesCleared = 0
        
        for i in (0..<rows).reversed() {
            if grid[i].allSatisfy({ $0 != nil }) {
                // ラインを消去
                grid.remove(at: i)
                grid.insert(Array(repeating: nil, count: cols), at: 0)
                linesCleared += 1
            }
        }
        
        // スコアの更新
        if linesCleared > 0 {
            score += [0, 100, 300, 500, 800][linesCleared]
        }
    }
} // GameBoard構造体の終わり
