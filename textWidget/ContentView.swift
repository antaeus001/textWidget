//
//  ContentView.swift
//  textWidget
//
//  Created by antaeus on 2025/2/27.
//

import SwiftUI
import SafariServices
import MessageUI

// 添加预览尺寸枚举
enum PreviewSize: String, CaseIterable {
    case small = "小尺寸"
    case medium = "中尺寸"
    case large = "大尺寸"
    
    var height: CGFloat {
        switch self {
        case .small: return 155  // iOS 小组件标准高度
        case .medium: return 155 // iOS 中尺寸组件标准高度
        case .large: return 345  // iOS 大尺寸组件标准高度
        }
    }
    
    var width: CGFloat {
        switch self {
        case .small: return 155  // iOS 小组件标准宽度
        case .medium: return 329 // iOS 中尺寸组件标准宽度
        case .large: return 329  // iOS 大尺寸组件标准宽度
        }
    }
    
    var contentHeight: CGFloat {
        height  // 移除减法，使用完整高度
    }
}

struct ContentView: View {
    @StateObject private var viewModel = TextViewModel()
    @State private var isEditing = false
    @State private var showingSettings = false  // 添加状态变量
    
    var body: some View {
        NavigationView {
            List {
                // 预览区域
                Section {
                    TextPreviewView(
                        model: viewModel.model,
                        isEditing: $isEditing,
                        onModelUpdate: { updatedModel in
                            viewModel.model = updatedModel
                        }
                    )
                    .padding()
                    .listRowInsets(EdgeInsets())
                    }
                
                // 样式控制面板
                StyleControlPanel(model: $viewModel.model)
                    .padding()
            }
            .navigationTitle("AI Widget Text配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                TextEditorView(text: $viewModel.model.text)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// 预览视图组件
struct TextPreviewView: View {
    let model: TextModel
    @State private var currentPage = 0
    @State private var newText: String = ""
    @Binding var isEditing: Bool
    let onModelUpdate: (TextModel) -> Void
    @State private var isAddingText = false
    @State private var editingText: String = ""
    @State private var selectedSize: PreviewSize = .medium  // 添加尺寸选择状态
    @State private var editingIndex: Int = -1  // -1表示主文本，>=0表示轮播文本索引
    @State private var isUserInteracting: Bool = false
    @State private var lastInteractionTime = Date()
    
    // 添加定时器
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var lastUpdateTime = Date()
    
    private let containerCornerRadius: CGFloat = 20  // 添加统一的圆角常量
    
    var body: some View {
        VStack(spacing: 8) {
            // 尺寸选择器
            Picker("预览尺寸", selection: $selectedSize) {
                ForEach(PreviewSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 预览容器
            TabView(selection: $currentPage) {
                // 主文本视图
                mainTextView
                    .tag(0)
                
                // 轮播文本列表视图
                ForEach(model.texts.indices, id: \.self) { index in
                    carouselItemView(text: model.texts[index], index: index)
                        .tag(index + 1)
                }
                
                // 添加新轮播文本视图
                addNewTextView
                    .tag(model.texts.count + 1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: selectedSize.width, height: selectedSize.height)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(containerCornerRadius)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        // 用户开始交互
                        isUserInteracting = true
                        lastInteractionTime = Date()
                    }
                    .onEnded { _ in
                        // 用户结束交互
                        lastInteractionTime = Date()
                        // 延迟一段时间后恢复自动轮播
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if Date().timeIntervalSince(lastInteractionTime) >= 2 {
                                isUserInteracting = false
                            }
                        }
                    }
            )
            
            // 页面指示器移到外面
            if model.texts.count > 0 {
                HStack {
                    ForEach(0...model.texts.count + 1, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 4)
            }
        }
        .onReceive(timer) { currentTime in
            // 只在有轮播文本且用户不在交互时进行轮播
            if !model.texts.isEmpty && !isUserInteracting {
                let timeDiff = currentTime.timeIntervalSince(lastUpdateTime)
                if timeDiff >= model.rotationInterval {
                    withAnimation {
                        // 计算下一页，考虑主文本页和添加按钮页
                        if currentPage >= model.texts.count {
                            currentPage = 0  // 回到主文本
                        } else {
                            currentPage += 1
                        }
                    }
                    lastUpdateTime = currentTime
                }
            }
        }
        .sheet(isPresented: $isAddingText) {
            TextEditorView(
                text: $editingText,
                title: editingIndex == -2 ? "添加新文本" : 
                       (editingIndex == -1 ? "编辑主文本" : "编辑轮播文本 #\(editingIndex + 1)"),
                onSave: { newText in
                    if !newText.isEmpty {
                        var updatedModel = model
                        if editingIndex == -2 {
                            // 添加新文本
                            updatedModel.texts.append(newText)
                            // 保存后跳转到新添加的文本
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    currentPage = updatedModel.texts.count
                                }
                            }
                        } else if editingIndex == -1 {
                            // 更新主文本
                            updatedModel.text = newText
                            // 保存后跳转到主文本
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    currentPage = 0
                                }
                            }
                        } else if editingIndex >= 0 && editingIndex < model.texts.count {
                            // 更新轮播文本
                            updatedModel.texts[editingIndex] = newText
                            // 保存后跳转到编辑的文本
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    currentPage = editingIndex + 1
                                }
                            }
                        }
                        onModelUpdate(updatedModel)
                    }
                }
            )
        }
    }
    
    private var mainTextView: some View {
        Text(model.text)
            .font(.system(size: model.fontSize))
            .foregroundColor(model.textColor)
            .multilineTextAlignment(model.alignment)
            .padding(.horizontal, 16)  // 添加水平内边距
            .padding(.vertical, 12)    // 添加垂直内边距
            .frame(
                maxWidth: selectedSize.width,
                maxHeight: selectedSize.height,
                alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing)
            )
            .background(model.backgroundColor)
            .cornerRadius(containerCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: containerCornerRadius)
                    .stroke(model.borderColor, lineWidth: model.borderWidth)
            )
            .onTapGesture {
                editingText = model.text
                editingIndex = -1  // -1 表示主文本
                isAddingText = true
            }
    }
    
    private func carouselItemView(text: String, index: Int) -> some View {
        Text(text)
            .font(.system(size: model.fontSize))
            .foregroundColor(model.textColor)
            .multilineTextAlignment(model.alignment)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(
                maxWidth: selectedSize.width,
                maxHeight: selectedSize.height,
                alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing)
            )
            .background(model.backgroundColor)
            .cornerRadius(containerCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: containerCornerRadius)
                    .stroke(model.borderColor, lineWidth: model.borderWidth)
            )
            .onTapGesture {
                editingText = text
                editingIndex = index  // 直接使用轮播文本的索引
                isAddingText = true
            }
            .contextMenu {
                Button(role: .destructive) {
                    var updatedModel = model
                    updatedModel.texts.remove(at: index)
                    onModelUpdate(updatedModel)
                    if currentPage > model.texts.count {
                        currentPage -= 1
                    }
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
    }
    
    private var addNewTextView: some View {
        VStack {
            if newText.isEmpty {
                Text("点击添加轮播文本")
                    .foregroundColor(.gray)
            } else {
                Text(newText)
            }
        }
        .font(.system(size: model.fontSize))
        .foregroundColor(model.textColor)
        .multilineTextAlignment(model.alignment)
        .padding(.horizontal, 16)  // 添加水平内边距
        .padding(.vertical, 12)    // 添加垂直内边距
        .frame(
            maxWidth: selectedSize.width,
            maxHeight: selectedSize.height,
            alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing)
        )
        .background(model.backgroundColor)
        .cornerRadius(containerCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: containerCornerRadius)
                .stroke(model.borderColor, lineWidth: model.borderWidth)
        )
        .onTapGesture {
            editingText = ""
            editingIndex = -2  // -2 表示添加新文本
            isAddingText = true
        }
    }
}

struct AIGenerateView: View {
    @Environment(\.dismiss) var dismiss
    @State var numberOfTexts: Int
    @State var prompt: String = ""
    let onGenerate: ([String]) -> Void
    
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var keyboardHeight: CGFloat = 0 // 添加键盘高度状态
    
    // 添加常用提示词
    private let commonPrompts = [
        "生成励志短语",
        "创建日常提醒",
        "生成节日祝福语",
        "创建工作效率提示",
        "生成健康生活建议",
        "生成古诗词",
        "生成英语四级单词和中文释义",
        "生成名著中的优美句子"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView { // 使用 ScrollView 替代 VStack 作为主容器
                VStack(alignment: .leading, spacing: 16) {
                    // 生成数量控制
                    Stepper("生成数量: \(numberOfTexts)", value: $numberOfTexts, in: 1...10)
                        .padding(.horizontal)
                    
                    // Prompt 输入区域
                    VStack(alignment: .leading) {
                        Text("提示词")
                            .font(.headline)
                        TextEditor(text: $prompt)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // 常用提示词
                    VStack(alignment: .leading, spacing: 12) {
                        Text("常用提示词")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // 使用 FlowLayout 替代 ScrollView
                        FlowLayout(spacing: 10) {
                            ForEach(commonPrompts, id: \.self) { suggestion in
                                Button(action: {
                                    prompt = suggestion
                                }) {
                                    Text(suggestion)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(red: 0.31, green: 0.54, blue: 0.38).opacity(0.1))
                                        )
                                        .foregroundColor(Color(red: 0.31, green: 0.54, blue: 0.38))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: keyboardHeight > 0 ? keyboardHeight - 100 : 0) // 添加动态间距
                }
                .padding(.bottom, 20) // 确保底部有足够空间
            }
            .navigationTitle("AI生成轮播内容")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("生成") {
                    Task {
                        await generateTexts()
                    }
                }
                .disabled(prompt.isEmpty || isGenerating)
            )
            .overlay {
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("AI 正在生成中...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("这可能需要几秒钟时间")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.31, green: 0.54, blue: 0.38).opacity(0.9))
                        )
                        .shadow(radius: 10)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isGenerating)
            .onAppear {
                // 添加键盘通知监听
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
        }
    }
    
    private func generateTexts() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            let texts = try await AIService.shared.generateTexts(
                prompt: prompt,
                count: numberOfTexts
            )
            onGenerate(texts)
            dismiss()
        } catch {
            errorMessage = "生成失败：\(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}

// 样式控制面板组件
struct StyleControlPanel: View {
    @Binding var model: TextModel
    @State private var isGeneratingTexts = false
    @State private var numberOfTexts = 3
    @State private var showingPurchaseAlert = false
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // 字体大小控制
            HStack {
                Text("字体大小")
                Slider(value: $model.fontSize, in: 12...48)
            }
            
            // 文本颜色选择
            ColorPicker("文本颜色", selection: $model.textColor)
            
            // 背景颜色选择
            ColorPicker("背景颜色", selection: $model.backgroundColor)
            
            // 对齐方式
            Picker("对齐方式", selection: $model.alignment) {
                Text("左对齐").tag(TextAlignment.leading)
                Text("居中").tag(TextAlignment.center)
                Text("右对齐").tag(TextAlignment.trailing)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // 边框控制
            HStack {
                Text("边框宽度")
                Slider(value: $model.borderWidth, in: 0...5)
            }
            if model.borderWidth > 0 {
                ColorPicker("边框颜色", selection: $model.borderColor)
            }
            
            // 轮播设置
            Section("轮播设置") {
                // AI 生成按钮
                Button(action: {
                    if UserSettings.shared.needsPurchase {
                        showingPurchaseAlert = true
                    } else {
                        isGeneratingTexts = true
                    }
                }) {
                    VStack {
                        Label("AI生成轮播内容", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                        if !UserSettings.shared.isPremium {
                            Text("剩余免费次数：\(UserSettings.shared.remainingFreeGenerates)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                if !model.texts.isEmpty {
                    HStack {
                        Text("轮播间隔")
                        Slider(
                            value: $model.rotationInterval,
                            in: 1...60,
                            step: 1
                        ) {
                            Text("轮播间隔")
                        } minimumValueLabel: {
                            Text("1秒")
                        } maximumValueLabel: {
                            Text("60秒")
                        }
                    }
                    Text("\(Int(model.rotationInterval)) 秒")
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(isPresented: $isGeneratingTexts) {
            AIGenerateView(
                numberOfTexts: numberOfTexts,
                prompt: "",
                onGenerate: { generatedTexts in
                    var updatedModel = model
                    if let firstText = generatedTexts.first {
                        updatedModel.text = firstText
                        updatedModel.texts = Array(generatedTexts.dropFirst())
                    }
                    model = updatedModel
                    UserSettings.shared.useOneGenerate()
                }
            )
        }
        .sheet(isPresented: $showingPurchaseAlert) {
            PurchaseView {
                isGeneratingTexts = true
            }
        }
    }
}

struct PurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeManager = StoreManager.shared
    let onPurchaseSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题区域
                    VStack(spacing: 8) {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("解锁全部功能")
                            .font(.title)
                            .bold()
                        
                        Text("选择适合您的会员方案")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)
                    
                    if storeManager.isLoadingProducts {
                        ProgressView("正在加载商品...")
                            .padding()
                    } else if storeManager.products.isEmpty {
                        VStack(spacing: 12) {
                            Text("暂无可用商品")
                                .font(.headline)
                            Button("重试") {
                                Task {
                                    await storeManager.loadProducts()
                                }
                            }
                        }
                        .padding()
            } else {
                        // 会员方案选择
                        VStack(spacing: 16) {
                            // 月度会员
                            if let monthlyProduct = storeManager.product(for: .monthly) {
                                membershipCard(
                                    type: .monthly,
                                    price: monthlyProduct.displayPrice,
                                    action: {
                                        Task {
                                            if await storeManager.purchase(monthlyProduct) {
                                                onPurchaseSuccess()
                                                dismiss()
                                            }
                                        }
                                    }
                                )
                            }
                            
                            // 永久会员
                            if let lifetimeProduct = storeManager.product(for: .lifetime) {
                                membershipCard(
                                    type: .lifetime,
                                    price: lifetimeProduct.displayPrice,
                                    action: {
                                        Task {
                                            if await storeManager.purchase(lifetimeProduct) {
                                                onPurchaseSuccess()
                                                dismiss()
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // 恢复购买按钮
                        Button("恢复购买") {
                            Task {
                                await storeManager.restorePurchases()
                                if UserSettings.shared.isPremium {
                                    dismiss()
                                }
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(.top)
                        
                        // 隐私和条款链接
                        HStack {
                            Link("隐私政策", destination: URL(string: "https://your-privacy-policy-url")!)
                            Text("·")
                            Link("使用条款", destination: URL(string: "https://your-terms-url")!)
                        }
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 30)
                    }
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("关闭") {
                    dismiss()
                }
            )
        }
        .onAppear {
            if storeManager.products.isEmpty {
                Task {
                    await storeManager.loadProducts()
                }
            }
        }
        .alert("购买失败", isPresented: .init(
            get: { storeManager.purchaseError != nil },
            set: { if !$0 { storeManager.purchaseError = nil } }
        )) {
            Button("确定", role: .cancel) { }
        } message: {
            if let error = storeManager.purchaseError {
                Text(error)
            }
        }
    }
    
    private func membershipCard(type: StoreManager.MembershipType, price: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(type.title)
                    .font(.title2)
                    .bold()
                Spacer()
                Text(price)
                    .font(.title3)
                    .bold()
            }
            
            Text(type.description)
                .foregroundColor(.gray)
            
            ForEach(type.features, id: \.self) { feature in
                Text(feature)
                    .foregroundColor(.secondary)
            }
            
            Button(action: action) {
                Text("选择")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// 流式布局视图
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRow: CGFloat = 0
        
        for (index, size) in sizes.enumerated() {
            if currentX + size.width > width {
                // 换行
                currentX = 0
                currentRow += 1
            }
            
            let y = currentRow * (size.height + spacing)
            height = max(height, y + size.height)
            currentX += size.width + spacing
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            rowHeight = max(rowHeight, size.height)
            
            if currentX + size.width > bounds.maxX {
                // 换行
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = size.height
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            
            currentX += size.width + spacing
        }
    }
}

// 修改 SettingsView 视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingHelp = false
    @State private var showingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showingEmailAlert = false  // 添加提示状态
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("关于")) {
                    HStack {
                        // 使用应用的实际图标
                        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                           let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
                           let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
                           let lastIcon = iconFiles.last {
                            Image(uiImage: UIImage(named: lastIcon) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                        } else {
                            // 回退到系统图标
                            Image(systemName: "text.bubble.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color(red: 0.31, green: 0.54, blue: 0.38))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.31, green: 0.54, blue: 0.38).opacity(0.1))
                                )
                        }
                        
                        VStack(alignment: .leading) {
                            Text("AI Widget Text")
                                .font(.headline)
                            Text("版本 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("帮助")) {
                    Button(action: {
                        showingHelp = true
                    }) {
                        HStack {
                            Text("使用帮助")
                            Spacer()
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("法律")) {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        showingTerms = true
                    }) {
                        HStack {
                            Text("用户协议")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("联系我们")) {
                    Button(action: {
                        let email = "wushengwuxi01@163.com"
                        let subject = "AI Widget Text 反馈"
                        
                        // 首先尝试使用内置邮件视图
                        if MFMailComposeViewController.canSendMail() {
                            showingMailView = true
                        } else {
                            // 如果内置邮件不可用，尝试打开邮件应用
                            let mailtoString = "mailto:\(email)?subject=\(subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                            if let mailtoUrl = URL(string: mailtoString ?? "") {
                                if UIApplication.shared.canOpenURL(mailtoUrl) {
                                    UIApplication.shared.open(mailtoUrl)
                                } else {
                                    // 如果邮件应用也不可用，复制邮箱地址到剪贴板
                                    UIPasteboard.general.string = email
                                    showingEmailAlert = true  // 显示提示
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text("发送邮件")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
            .sheet(isPresented: $showingPrivacyPolicy) {
                SafariView(url: URL(string: "https://www.huohuaai.com/privacy-textwidget.html")!)
            }
            .sheet(isPresented: $showingTerms) {
                SafariView(url: URL(string: "https://www.huohuaai.com/terms-textwidget.html")!)
            }
            .sheet(isPresented: $showingHelp) {
                SafariView(url: URL(string: "https://www.huohuaai.com/support-textwidget.html")!)
            }
            .sheet(isPresented: $showingMailView) {
                MailView(result: $mailResult, subject: "AI Widget Text 反馈", recipients: ["wushengwuxi01@163.com"], message: "")
            }
            .alert("邮箱已复制", isPresented: $showingEmailAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("邮箱地址已复制到剪贴板，您可以手动发送邮件。")
            }
        }
    }
}

// 添加 MailView 用于发送邮件
struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var result: Result<MFMailComposeResult, Error>?
    var subject: String
    var recipients: [String]
    var message: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients(recipients)
        vc.setMessageBody(message, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 添加 SafariView 用于显示网页
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    ContentView()
}
