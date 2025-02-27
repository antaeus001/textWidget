import SwiftUI

struct TextEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @State private var tempText: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $tempText)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("编辑文本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        text = tempText
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempText = text
        }
    }
}

#Preview {
    TextEditorView(text: .constant("示例文本"))
} 