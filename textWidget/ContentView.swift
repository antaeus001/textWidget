//
//  ContentView.swift
//  textWidget
//
//  Created by antaeus on 2025/2/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TextViewModel()
    @State private var isEditing = false
    @State private var newText: String = ""
    
    var body: some View {
        NavigationView {
            List {
                // 预览区域
                TextPreviewView(model: viewModel.model)
                    .padding()
                    .onTapGesture {
                        isEditing = true
                    }
                
                // 样式控制面板
                StyleControlPanel(model: $viewModel.model)
                    .padding()
                
                // 轮播内容配置部分
                Section("轮播设置") {
                    // 轮播间隔设置
                    Stepper(value: $viewModel.currentConfig.rotationInterval, in: 1...60) {
                        Text("轮播间隔: \(Int(viewModel.currentConfig.rotationInterval))秒")
                    }
                    
                    // 添加新内容
                    HStack {
                        TextField("输入新的轮播内容", text: $newText)
                        Button("添加") {
                            if !newText.isEmpty {
                                viewModel.addContent(newText)
                                newText = ""
                            }
                        }
                    }
                    
                    // 显示现有内容列表
                    ForEach(viewModel.currentConfig.contents) { content in
                        Text(content.text)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.removeContent(at: index)
                        }
                    }
                }
                
                // 预览部分
                Section("预览") {
                    CarouselPreview(contents: viewModel.currentConfig.contents,
                                  interval: viewModel.currentConfig.rotationInterval)
                }
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
    
    var body: some View {
        Text(model.text)
            .font(.system(size: model.fontSize))
            .foregroundColor(model.textColor)
            .multilineTextAlignment(model.alignment)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(model.backgroundColor)
            .cornerRadius(8)
            .shadow(radius: model.hasShadow ? model.shadowRadius : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(model.borderColor, lineWidth: model.borderWidth)
            )
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
            
            // 阴影控制
            Toggle("启用阴影", isOn: $model.hasShadow)
            if model.hasShadow {
                HStack {
                    Text("阴影大小")
                    Slider(value: $model.shadowRadius, in: 0...10)
                }
            }
            
            // 边框控制
            HStack {
                Text("边框宽度")
                Slider(value: $model.borderWidth, in: 0...5)
            }
            if model.borderWidth > 0 {
                ColorPicker("边框颜色", selection: $model.borderColor)
            }
        }
    }
}

// 轮播预览组件
struct CarouselPreview: View {
    let contents: [ContentItem]
    let interval: TimeInterval
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            if contents.isEmpty {
                Text("暂无轮播内容")
            } else {
                Text(contents[currentIndex].text)
                    .transition(.opacity)
                    .animation(.easeInOut, value: currentIndex)
            }
        }
        .frame(height: 100)
        .onAppear {
            guard contents.count > 1 else { return }
            // 启动定时器进行预览
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                currentIndex = (currentIndex + 1) % contents.count
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}

#Preview {
    ContentView()
}
