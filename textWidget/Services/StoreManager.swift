import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasingProduct: Product?
    @Published var purchaseError: String?
    
    // 定义会员商品 ID
    private let productIds = [
        "com.textwidget.premium.monthly",   // 月度会员
        "com.textwidget.premium.lifetime"   // 永久会员
    ]
    
    // 会员类型
    enum MembershipType: String {
        case monthly = "com.textwidget.premium.monthly"
        case lifetime = "com.textwidget.premium.lifetime"
        
        var title: String {
            switch self {
            case .monthly: return "月度会员"
            case .lifetime: return "永久会员"
            }
        }
        
        var description: String {
            switch self {
            case .monthly: return "每月自动续期，可随时取消"
            case .lifetime: return "一次付费，永久使用"
            }
        }
        
        var features: [String] {
            [
                "✓ 无限使用 AI 生成功能",
                "✓ 解锁更多生成模板",
                "✓ 优先使用新功能",
                "✓ 去除广告"
            ]
        }
    }
    
    // 获取指定类型的商品
    func product(for type: MembershipType) -> Product? {
        products.first { $0.id == type.rawValue }
    }
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products:", error)
        }
    }
    
    func purchase(_ product: Product) async -> Bool {
        purchasingProduct = product
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    UserSettings.shared.isPremium = true
                    purchasingProduct = nil
                    return true
                case .unverified:
                    purchaseError = "购买验证失败"
                }
            case .userCancelled:
                purchaseError = "已取消购买"
            case .pending:
                purchaseError = "购买正在处理中"
            @unknown default:
                purchaseError = "未知错误"
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        
        purchasingProduct = nil
        return false
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            UserSettings.shared.isPremium = true
        } catch {
            purchaseError = "恢复购买失败：\(error.localizedDescription)"
        }
    }
} 