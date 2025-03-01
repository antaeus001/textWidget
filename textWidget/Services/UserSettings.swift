import Foundation
import StoreKit

class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard
    
    private let kFreeGenerateCount = "freeGenerateCount"
    private let kMaxFreeGenerates = 3
    private let kIsPremium = "isPremium"
    
    var isPremium: Bool {
        get { defaults.bool(forKey: kIsPremium) }
        set { defaults.set(newValue, forKey: kIsPremium) }
    }
    
    var remainingFreeGenerates: Int {
        if isPremium { return Int.max }
        let usedCount = defaults.integer(forKey: kFreeGenerateCount)
        return max(kMaxFreeGenerates - usedCount, 0)
    }
    
    func useOneGenerate() {
        if !isPremium {
            let currentCount = defaults.integer(forKey: kFreeGenerateCount)
            defaults.set(currentCount + 1, forKey: kFreeGenerateCount)
        }
    }
    
    var needsPurchase: Bool {
        !isPremium && remainingFreeGenerates == 0
    }
    
    // 重置免费次数（用于测试）
    func resetFreeGenerates() {
        defaults.set(0, forKey: kFreeGenerateCount)
    }
} 