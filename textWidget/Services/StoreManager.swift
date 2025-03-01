import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasingProduct: Product?
    @Published var purchaseError: String?
    
    private let productIds = ["com.yourapp.premium"]
    
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
    
    func purchase() async -> Bool {
        guard let product = products.first else { return false }
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