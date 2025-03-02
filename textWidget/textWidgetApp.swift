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
    // 添加事务监听器
    @StateObject private var transactionListener = TransactionListener()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// 事务监听器类
class TransactionListener: ObservableObject {
    init() {
        // 启动事务监听
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    // 处理交易
                    await transaction.finish()
                    
                    // 更新用户状态
                    UserSettings.shared.isPremium = true
                } catch {
                    print("交易验证失败:", error)
                }
            }
        }
        
        // 检查之前的购买记录
        Task {
            await checkPreviousPurchases()
        }
    }
    
    @MainActor
    func checkPreviousPurchases() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                // 有效的购买记录，更新用户状态
                UserSettings.shared.isPremium = true
                await transaction.finish()
            } catch {
                print("之前的购买验证失败:", error)
            }
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            print("验证失败:", error)
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
