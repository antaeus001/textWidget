import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    @Published var purchasingProduct: Product?
    @Published var purchaseError: String?
    @Published var isLoadingProducts = false
    @Published var currentSubscription: MembershipType?
    @Published var subscriptionExpirationDate: Date?
    
    private var hasLoadedProducts = false
    private var isInitialLoading = true
    
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
        // 在初始化时立即开始加载产品
        Task { @MainActor in
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        guard isInitialLoading || products.isEmpty else {
            return
        }
        
        isLoadingProducts = true
        
        do {
            let products = try await Product.products(for: productIds)
            
            // 确保在主线程更新 UI
            await MainActor.run {
                self.products = products.sorted { product1, product2 in
                    if product1.id == MembershipType.monthly.rawValue { return true }
                    if product2.id == MembershipType.monthly.rawValue { return false }
                    return true
                }
                self.hasLoadedProducts = true
                self.isInitialLoading = false
                self.isLoadingProducts = false
            }
            
            print("Loaded products:", self.products.map { $0.id })
        } catch {
            await MainActor.run {
                self.isLoadingProducts = false
                self.purchaseError = "加载商品失败：\(error.localizedDescription)"
            }
            print("Failed to load products:", error)
        }
    }
    
    // 刷新产品列表
    func refreshProducts() async {
        isInitialLoading = true
        await loadProducts()
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
        
        guard await checkAccountStatus() else {
            purchasingProduct = nil
            return false
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    
                    if transaction.productID == IAPProducts.lifetimeSubscription {
                        print("永久会员购买成功")
                        DispatchQueue.main.async {
                            self.currentSubscription = .lifetime
                            self.subscriptionExpirationDate = nil
                            UserSettings.shared.isPremium = true
                        }
                    } else if transaction.productID == IAPProducts.monthlySubscription {
                        print("月度会员购买成功")
                        if let expirationDate = transaction.expirationDate {
                            DispatchQueue.main.async {
                                self.currentSubscription = .monthly
                                self.subscriptionExpirationDate = expirationDate
                                UserSettings.shared.isPremium = true
                            }
                        }
                    }
                    
                    purchasingProduct = nil
                    return true
                    
                case .unverified(_, let error):
                    purchaseError = "购买验证失败: \(error.localizedDescription)"
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
    
    func checkSubscriptionStatus() async {
        // 先重置状态
        DispatchQueue.main.async {
            self.currentSubscription = nil
            self.subscriptionExpirationDate = nil
        }
        
        var mostRecentTransaction: StoreKit.Transaction? = nil
        var mostRecentDate = Date.distantPast
        
        // 获取当前有效的订阅
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            // 检查是否是我们的产品
            guard [IAPProducts.monthlySubscription, IAPProducts.lifetimeSubscription].contains(transaction.productID) else {
                continue
            }
            
            // 对于永久会员，直接设置
            if transaction.productID == IAPProducts.lifetimeSubscription {
                DispatchQueue.main.async {
                    self.currentSubscription = .lifetime
                    self.subscriptionExpirationDate = nil
                    UserSettings.shared.isPremium = true
                }
                print("永久会员已激活")
                return
            }
            
            // 对于月度会员，找出最新的交易
            if transaction.productID == IAPProducts.monthlySubscription {
                // 只考虑有效期内的交易
                if let expirationDate = transaction.expirationDate, 
                   expirationDate > Date() {
                    // 找出最新的交易
                    if transaction.purchaseDate > mostRecentDate {
                        mostRecentTransaction = transaction
                        mostRecentDate = transaction.purchaseDate
                    }
                }
            }
        }
        
        // 处理月度订阅
        if let transaction = mostRecentTransaction, 
           let expirationDate = transaction.expirationDate {
            print("月度会员信息:")
            print("- 购买日期: \(transaction.purchaseDate)")
            print("- 到期日期: \(expirationDate)")
            
            // 设置会员状态
            DispatchQueue.main.async {
                self.currentSubscription = .monthly
                self.subscriptionExpirationDate = expirationDate
                UserSettings.shared.isPremium = true
            }
            print("月度会员有效期至: \(expirationDate)")
        } else {
            print("未找到有效的月度会员")
        }
    }
    
    func restorePurchases() async throws {
        print("开始恢复购买...")
        
        // 先同步 App Store 的购买记录
        try await AppStore.sync()
        print("App Store 同步完成")
        
        var hasValidPurchase = false
        
        // 检查所有交易
        for await verificationResult in Transaction.all {
            switch verificationResult {
            case .verified(let transaction):
                print("验证交易: \(transaction.productID)")
                
                // 检查是否是我们的产品
                if transaction.productID == IAPProducts.lifetimeSubscription {
                    print("找到永久会员购买记录")
                    hasValidPurchase = true
                    DispatchQueue.main.async {
                        self.currentSubscription = .lifetime
                        self.subscriptionExpirationDate = nil
                        UserSettings.shared.isPremium = true
                    }
                    break
                } else if transaction.productID == IAPProducts.monthlySubscription {
                    // 检查月度会员是否过期
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        print("找到有效的月度会员，到期时间：\(expirationDate)")
                        hasValidPurchase = true
                        DispatchQueue.main.async {
                            self.currentSubscription = .monthly
                            self.subscriptionExpirationDate = expirationDate
                            UserSettings.shared.isPremium = true
                        }
                        break
                    }
                }
                
            case .unverified(_, let error):
                print("交易验证失败: \(error)")
            }
        }
        
        if !hasValidPurchase {
            print("未找到有效的购买记录")
            DispatchQueue.main.async {
                self.currentSubscription = nil
                self.subscriptionExpirationDate = nil
                UserSettings.shared.isPremium = false
            }
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到有效的会员权限"])
        }
        
        print("恢复购买完成")
        // 检查最终状态
        print("会员状态：")
        print("- Is Premium: \(UserSettings.shared.isPremium)")
        print("- Current Subscription: \(String(describing: currentSubscription))")
        print("- Expiration Date: \(String(describing: subscriptionExpirationDate))")
    }
} 