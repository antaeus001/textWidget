//
//  textWidgetApp.swift
//  textWidget
//
//  Created by antaeus on 2025/2/27.
//

import SwiftUI
import StoreKit

@main
struct textWidgetApp: App {
    @StateObject private var transactionListener = TransactionListener()
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // 应用启动时检查订阅状态
                    await storeManager.checkSubscriptionStatus()
                }
        }
    }
}

// 事务监听器类
class TransactionListener: ObservableObject {
    init() {
        // 启动事务监听
        Task {
            // 监听新交易
            for await verificationResult in StoreKit.Transaction.updates {
                await handle(verificationResult)
            }
        }
        
        // 检查之前的购买记录
        Task {
            await checkPreviousPurchases()
        }
    }
    
    @MainActor
    private func handle(_ verificationResult: VerificationResult<StoreKit.Transaction>) async {
        do {
            switch verificationResult {
            case .verified(let transaction):
                print("收到已验证的交易:", transaction.id)
                // 处理验证通过的交易
                await transaction.finish()
                UserSettings.shared.isPremium = true
            case .unverified(let transaction, let error):
                print("收到未验证的交易:", transaction.id)
                print("验证错误:", error)
            }
        } catch {
            print("处理交易时出错:", error)
        }
    }
    
    @MainActor
    func checkPreviousPurchases() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            await handle(result)
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
