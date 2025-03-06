enum MembershipType {
    case monthly
    case lifetime
    
    var title: String {
        switch self {
        case .monthly:
            return "月度会员"
        case .lifetime:
            return "永久会员"
        }
    }
    
    // ... 其他属性 ...
} 