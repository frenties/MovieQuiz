import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func comparisonResults(newResult: GameResult) -> Bool {
        newResult.correct > correct
    }
}
