import Foundation

struct AIResponse: Codable {
    let choices: [Choice]
    let error: ErrorResponse?
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
    
    struct ErrorResponse: Codable {
        let message: String
    }
}

class AIService {
    static let shared = AIService()
    private let apiKey = "sk-cf6bade5c848421e83600d07592beb2b"
    private let endpoint = "https://api.deepseek.com/v1/chat/completions"
    
    func generateTexts(prompt: String, count: Int) async throws -> [String] {
        let systemPrompt = """
        你是一个文本生成助手。请基于用户提供的提示词，生成\(count)条相关的文本。
        请将生成的文本以JSON数组的格式返回，格式为：
        {
            "texts": ["文本1", "文本2", "文本3"]
        }
        """
        
        let userPrompt = """
        提示词：\(prompt)
        """
        
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7
        ]
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Request URL: \(endpoint)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("Response: \(String(data: data, encoding: .utf8) ?? "")")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorResponse = try? JSONDecoder().decode(AIResponse.self, from: data)
                throw NSError(
                    domain: "",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorResponse?.error?.message ?? "Unknown error"]
                )
            }
        }
        
        let aiResponse = try JSONDecoder().decode(AIResponse.self, from: data)
        guard let content = aiResponse.choices.first?.message.content else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        // 解析返回的 JSON 字符串
        struct GeneratedTexts: Codable {
            let texts: [String]
        }
        
        // 尝试从内容中提取 JSON
        if let jsonData = content.data(using: .utf8),
           let generatedTexts = try? JSONDecoder().decode(GeneratedTexts.self, from: jsonData) {
            return Array(generatedTexts.texts.prefix(count))
        }
        
        // 如果 JSON 解析失败，回退到按行分割
        return content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .prefix(count)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
} 