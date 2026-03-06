//
//  AIService.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import Foundation

enum AIServiceError: LocalizedError {

	case noProvider
	case invalidURL
	case httpError(statusCode: Int, body: String)
	case decodingError(String)
	case emptyResponse

	var errorDescription: String? {
		switch self {
		case .noProvider:
			return NSLocalizedString("No AI provider configured.", comment: "AI error")
		case .invalidURL:
			return NSLocalizedString("Invalid endpoint URL.", comment: "AI error")
		case .httpError(let statusCode, let body):
			return "HTTP \(statusCode): \(body)"
		case .decodingError(let detail):
			return NSLocalizedString("Failed to decode AI response: ", comment: "AI error") + detail
		case .emptyResponse:
			return NSLocalizedString("AI returned an empty response.", comment: "AI error")
		}
	}
}

@MainActor final class AIService {

	// MARK: - Request/Response Models

	private struct ChatRequest: Encodable {
		let model: String
		let messages: [ChatMessage]
		let temperature: Double
		let stream: Bool
	}

	private struct ChatMessage: Encodable {
		let role: String
		let content: String
	}

	private struct ChatResponse: Decodable {
		struct Choice: Decodable {
			struct Message: Decodable {
				let content: String
			}
			let message: Message
		}
		let choices: [Choice]
	}

	// MARK: - Language Enforcement

	/// Append a repeated language instruction to the user's prompt.
	/// For summary, also require HTML output format.
	static func appendLanguageInstruction(to prompt: String, verb: String, targetLanguage: String) -> String {
		let instruction = "\(verb) in \(targetLanguage)!"
		let repeated = " \(instruction) \(instruction) \(instruction)"
		var result = prompt.isEmpty ? "" : prompt
		if verb == "Summarize" {
			result += " Return the result as HTML (use <ul><li> for bullet points). Do not use markdown."
		}
		if verb == "Translate" {
			result += " Return the result as a JSON object with two keys: \"title\" (translated title) and \"body\" (translated body HTML). Preserve all HTML tags and structure in the body. Only translate text content, not HTML tags or attributes. Output ONLY the raw JSON object, no markdown code fences."
		}
		result += repeated
		return result.trimmingCharacters(in: .whitespaces)
	}

	// MARK: - API

	static func complete(provider: AIProvider, systemPrompt: String, userContent: String) async throws -> String {
		guard let url = URL(string: provider.endpointURL) else {
			throw AIServiceError.invalidURL
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
		request.timeoutInterval = 120

		let chatRequest = ChatRequest(
			model: provider.model,
			messages: [
				ChatMessage(role: "system", content: systemPrompt),
				ChatMessage(role: "user", content: userContent)
			],
			temperature: 0.3,
			stream: false
		)
		request.httpBody = try JSONEncoder().encode(chatRequest)

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw AIServiceError.httpError(statusCode: 0, body: "Invalid response type")
		}

		guard httpResponse.statusCode == 200 else {
			let body = String(data: data, encoding: .utf8) ?? "Unknown error"
			throw AIServiceError.httpError(statusCode: httpResponse.statusCode, body: body)
		}

		let chatResponse: ChatResponse
		do {
			chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
		} catch {
			throw AIServiceError.decodingError(error.localizedDescription)
		}

		guard let content = chatResponse.choices.first?.message.content, !content.isEmpty else {
			throw AIServiceError.emptyResponse
		}

		return content
	}
}
