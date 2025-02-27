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
    
    var body: some View {
        NavigationView {
            VStack {
                // 预览区域
                TextPreviewView(model: viewModel.model)
                    .padding()
                    .onTapGesture {
                        isEditing = true
                    }
                
                // 样式控制面板
                StyleControlPanel(model: $viewModel.model)
                    .padding()
            }
            .navigationTitle("文本小组件")
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

#Preview {
    ContentView()
}
