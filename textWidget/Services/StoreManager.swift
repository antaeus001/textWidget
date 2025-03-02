import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasingProduct: Product?
    @Published var purchaseError: String?
    @Published private(set) var isLoadingProducts = false
    
    private let productIds = [
        IAPProducts.monthlySubscription,
        IAPProducts.lifetimeSubscription
    ]
    
    // 会员类型
    enum MembershipType: String {
        case monthly = "com.textwidget.premium.automonthly"
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
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        
        do {
            let products = try await Product.products(for: productIds)
            // 按照月度、永久的顺序排序
            self.products = products.sorted { product1, product2 in
                if product1.id == MembershipType.monthly.rawValue { return true }
                if product2.id == MembershipType.monthly.rawValue { return false }
                return true
            }
            print("Loaded products:", self.products.map { $0.id })
        } catch {
            print("Failed to load products:", error)
            purchaseError = "加载商品失败：\(error.localizedDescription)"
        }
    }
    
    func checkAccountStatus() async -> Bool {
        do {
            // 添加更多状态检查信息
            print("开始检查账号状态...")
            print("Bundle ID:", Bundle.main.bundleIdentifier ?? "unknown")
            print("Receipt URL:", Bundle.main.appStoreReceiptURL?.path ?? "none")
            
            try await AppStore.sync()
            print("账号状态检查成功")
            return true
        } catch let error as SKError {
            switch error.code {
            case .storeProductNotAvailable:
                purchaseError = "请在设置中登录 App Store 账号"
            case .cloudServiceNetworkConnectionFailed:
                purchaseError = "网络连接失败，请检查网络设置"
            case .cloudServiceRevoked:
                purchaseError = "App Store 账号已被撤销，请重新登录"
            case .privacyAcknowledgementRequired:
                purchaseError = "需要同意 App Store 隐私条款"
            case .unauthorizedRequestData:
                purchaseError = "未授权的请求"
            default:
                purchaseError = "账号状态检查失败：\(error.localizedDescription)"
            }
            print("账号状态检查失败: \(error)")
            return false
        } catch {
            print("账号状态检查失败: \(error)")
            purchaseError = "请确保已登录 App Store 账号并连接网络"
            return false
        }
    }
    
    func purchase(_ product: Product) async -> Bool {
        purchasingProduct = product
        purchaseError = nil
        
        // 先检查账号状态
        guard await checkAccountStatus() else {
            purchasingProduct = nil
            return false
        }
        
        do {
            print("开始购买商品: \(product.id)")
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                print("购买成功，验证结果: \(verification)")
                switch verification {
                case .verified(let transaction):
                    print("验证通过，完成交易")
                    await transaction.finish()
                    UserSettings.shared.isPremium = true
                    purchasingProduct = nil
                    return true
                case .unverified(_, let error):
                    print("验证失败: \(error)")
                    purchaseError = "购买验证失败: \(error.localizedDescription)"
                }
            case .userCancelled:
                print("用户取消购买")
                purchaseError = "已取消购买"
            case .pending:
                print("购买待处理")
                purchaseError = "购买正在处理中"
            @unknown default:
                print("未知错误")
                purchaseError = "未知错误"
            }
        } catch {
            print("购买出错: \(error)")
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