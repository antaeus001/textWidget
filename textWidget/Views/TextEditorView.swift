import SwiftUI

struct TextEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    @State private var tempText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // 添加标题属性，用于显示正在编辑的是哪个文本
    var title: String = "编辑文本"
    // 添加回调函数，用于保存文本到特定位置
    var onSave: ((String) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 字数统计
                HStack {
                    Text("\(tempText.count) 个字符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if !tempText.isEmpty {
                        Button(action: {
                            tempText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 文本编辑区
                ZStack(alignment: .topLeading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95))
                    
                    // 占位文本
                    if tempText.isEmpty {
                        Text("在此输入文本...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                    }
                    
                    // 文本编辑器
                    TextEditor(text: $tempText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(4)
                        .focused($isTextFieldFocused)
                }
                .frame(height: 200)
                .padding()
                
                // 常用文本建议
                VStack(alignment: .leading, spacing: 12) {
                    Text("常用文本")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(commonTexts, id: \.self) { suggestion in
                                Button(action: {
                                    tempText = suggestion
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
                }
                .padding(.vertical)
                
                Spacer()
                
                // 底部按钮
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        if let onSave = onSave {
                            // 如果提供了自定义保存函数，使用它
                            onSave(tempText)
                        } else {
                            // 否则使用默认的绑定更新
                            text = tempText
                        }
                        dismiss()
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.31, green: 0.54, blue: 0.38))
                            )
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            tempText = text
            // 自动聚焦
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // 常用文本建议
    private let commonTexts = [
        "今日天气：晴",
        "记得喝水",
        "今日待办事项",
        "每日一句：努力工作，快乐生活",
        "距离假期还有 7 天"
    ]
}

#Preview {
    TextEditorView(text: .constant("示例文本"))
} 