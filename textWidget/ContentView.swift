//
//  ContentView.swift
//  textWidget
//
//  Created by antaeus on 2025/2/27.
//

import SwiftUI

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
        switch self {
        case .small: return 135  // 减去边距和指示器的高度
        case .medium: return 135 // 与小尺寸相同的高度
        case .large: return 325
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = TextViewModel()
    @State private var isEditing = false
    
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
            .navigationTitle("文本小组件配置")
            .sheet(isPresented: $isEditing) {
                TextEditorView(text: $viewModel.model.text)
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
    
    // 添加定时器
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var lastUpdateTime = Date()
    
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
            .cornerRadius(20)
            
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
            // 只在有轮播文本时进行轮播
            if !model.texts.isEmpty {
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
            TextEditorView(text: Binding(
                get: { editingText },
                set: { newValue in
                    editingText = newValue
                    if !newValue.isEmpty {
                        var updatedModel = model
                        if currentPage == model.texts.count + 1 {
                            updatedModel.texts.append(newValue)
                            currentPage = model.texts.count
                        } else if currentPage > 0 {
                            updatedModel.texts[currentPage - 1] = newValue
                        }
                        onModelUpdate(updatedModel)
                    }
                }
            ))
        }
    }
    
    private var mainTextView: some View {
        Text(model.text)
            .font(.system(size: model.fontSize))
            .foregroundColor(model.textColor)
            .multilineTextAlignment(model.alignment)
            .padding()
            .frame(
                maxWidth: .infinity,
                minHeight: selectedSize.contentHeight,
                alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing)
            )
            .background(model.backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(model.borderColor, lineWidth: model.borderWidth)
            )
            .onTapGesture {
                isEditing = true
            }
    }
    
    private func carouselItemView(text: String, index: Int) -> some View {
        Text(text)
            .font(.system(size: model.fontSize))
            .foregroundColor(model.textColor)
            .multilineTextAlignment(model.alignment)
            .padding()
            .frame(
                maxWidth: .infinity,
                minHeight: selectedSize.contentHeight,
                alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing)
            )
            .background(model.backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(model.borderColor, lineWidth: model.borderWidth)
            )
            .onTapGesture {
                editingText = text
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
        .padding()
        .frame(
            maxWidth: .infinity,
            minHeight: selectedSize.contentHeight,
            alignment: model.alignment == .center ? .center : (model.alignment == .leading ? .leading : .trailing)
        )
        .background(model.backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(model.borderColor, lineWidth: model.borderWidth)
        )
        .onTapGesture {
            editingText = ""
            isAddingText = true
        }
    }
}

// 样式控制面板组件
struct StyleControlPanel: View {
    @Binding var model: TextModel
    
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
            if !model.texts.isEmpty {
                Section("轮播设置") {
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
    }
}

#Preview {
    ContentView()
}
