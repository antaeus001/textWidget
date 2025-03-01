import Foundation

class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard
    
    private let kFreeGenerateCount = "freeGenerateCount"
    private let kMaxFreeGenerates = 3
    
    var remainingFreeGenerates: Int {
        let usedCount = defaults.integer(forKey: kFreeGenerateCount)
        return max(kMaxFreeGenerates - usedCount, 0)
    }
    
    func useOneGenerate() {
        let currentCount = defaults.integer(forKey: kFreeGenerateCount)
        defaults.set(currentCount + 1, forKey: kFreeGenerateCount)
    }
    
    var needsPurchase: Bool {
        remainingFreeGenerates == 0
    }
} 