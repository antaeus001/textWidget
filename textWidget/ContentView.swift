//
//  ContentView.swift
//  textWidget
//
//  Created by antaeus on 2025/2/27.
//

import SwiftUI
import SharedModels

struct ContentView: View {
    @StateObject private var viewModel = TextViewModel()
    @State private var isEditing = false
    @State private var newText: String = ""
    @State private var showingDeleteAlert = false
    @State private var deletingIndex: IndexSet?
    
    var body: some View {
        NavigationView {
            List {
                // 文本样式预览
                Section {
                    TextPreviewView(model: viewModel.model)
                        .padding()
                        .onTapGesture {
                            isEditing = true
                        }
                } header: {
                    Text("样式预览")
                } footer: {
                    Text("点击预览区域编辑文本内容")
                }
                
                // 轮播内容管理
                Section {
                    // 轮播间隔设置
                    HStack {
                        Text("轮播间隔")
                        Spacer()
                        Text("\(Int(viewModel.currentConfig.rotationInterval))秒")
                    }
                    Slider(
                        value: Binding(
                            get: { viewModel.currentConfig.rotationInterval },
                            set: { viewModel.updateRotationInterval($0) }
                        ),
                        in: 1...60,
                        step: 1
                    )
                    
                    // 添加新内容
                    HStack {
                        TextField("输入新的轮播内容", text: $newText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            if !newText.isEmpty {
                                viewModel.addContent(newText)
                                newText = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newText.isEmpty)
                    }
                    
                    // 显示现有内容列表
                    if viewModel.currentConfig.contents.isEmpty {
                        Text("暂无轮播内容")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(viewModel.currentConfig.contents) { content in
                            HStack {
                                Text(content.text)
                                Spacer()
                                Text("\(viewModel.currentConfig.contents.firstIndex(where: { $0.id == content.id })! + 1)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            deletingIndex = indexSet
                            showingDeleteAlert = true
                        }
                    }
                } header: {
                    Text("轮播设置")
                } footer: {
                    Text("向左滑动删除轮播内容")
                }
                
                // 样式控制面板
                Section("样式设置") {
                    StyleControlPanel(model: $viewModel.model)
                }
            }
            .navigationTitle("文本小组件")
            .sheet(isPresented: $isEditing) {
                TextEditorView(text: $viewModel.model.text)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    if let indexSet = deletingIndex {
                        indexSet.forEach { index in
                            viewModel.removeContent(at: index)
                        }
                    }
                }
            } message: {
                Text("确定要删除这条轮播内容吗？")
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
struct CarouselPreviewView: View {
    let contents: [ContentItem]
    let interval: TimeInterval
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            if contents.isEmpty {
                Text("暂无轮播内容")
                    .foregroundColor(.secondary)
            } else {
                Text(contents[currentIndex].text)
                    .transition(.opacity)
                    .animation(.easeInOut, value: currentIndex)
                
                // 轮播指示器
                if contents.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<contents.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(height: 100)
        .onAppear {
            guard contents.count > 1 else { return }
            // 启动定时器进行预览
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                withAnimation {
                    currentIndex = (currentIndex + 1) % contents.count
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}

#Preview {
    ContentView()
}
