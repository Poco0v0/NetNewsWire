//
//  AIArticleHelper.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit
@preconcurrency import WebKit
import Articles

@MainActor final class AIArticleHelper {

	private weak var webView: WKWebView?
	private var currentArticleID: String?
	private var isTranslated = false
	private(set) var isTranslating = false
	private(set) var isSummarizing = false

	private var translationTask: Task<Void, Never>?
	private var summaryTask: Task<Void, Never>?

	var onStateChange: (() -> Void)?

	var isBusy: Bool {
		isTranslating || isSummarizing
	}

	init(webView: WKWebView) {
		self.webView = webView
	}

	func updateWebView(_ webView: WKWebView) {
		self.webView = webView
	}

	func articleDidChange(articleID: String?) {
		translationTask?.cancel()
		summaryTask?.cancel()
		translationTask = nil
		summaryTask = nil
		currentArticleID = articleID
		isTranslated = false
		isTranslating = false
		isSummarizing = false
	}

	// MARK: - Translation

	var canTranslate: Bool {
		currentArticleID != nil && !isTranslating
	}

	func toggleTranslation(article: Article, extractedContent: (title: String?, body: String?)? = nil) {
		translationTask?.cancel()
		translationTask = Task { @MainActor in
			await performTranslation(article: article, extractedContent: extractedContent)
		}
	}

	// MARK: - Summary

	var canSummarize: Bool {
		currentArticleID != nil && !isSummarizing
	}

	func summarize(article: Article, extractedContent: (title: String?, body: String?)? = nil) {
		summaryTask?.cancel()
		summaryTask = Task { @MainActor in
			await performSummarize(article: article, extractedContent: extractedContent)
		}
	}
}

// MARK: - Private

private extension AIArticleHelper {

	func performTranslation(article: Article, extractedContent: (title: String?, body: String?)?) async {
		guard let webView else {
			return
		}

		if isTranslated {
			_ = try? await webView.evaluateJavaScript("nnwRevertTranslation()")
			isTranslated = false
			return
		}

		guard let provider = AIProviderManager.shared.translationProvider else {
			showNoProviderAlert(for: NSLocalizedString("Translation", comment: "AI feature"))
			return
		}

		let targetLanguage = AIProviderManager.shared.targetLanguage
		let systemPrompt = AIService.appendLanguageInstruction(
			to: provider.translationPrompt ?? "",
			verb: "Translate",
			targetLanguage: targetLanguage
		)

		let title: String
		let body: String
		if let extracted = extractedContent {
			title = extracted.title ?? article.title ?? ""
			body = extracted.body ?? article.contentHTML ?? article.contentText ?? ""
		} else {
			title = article.title ?? ""
			body = article.contentHTML ?? article.contentText ?? ""
		}
		let userContent = "Title: \(title)\n\nBody:\n\(body)"

		isTranslating = true
		onStateChange?()
		_ = try? await webView.evaluateJavaScript("nnwShowAILoading('translate')")

		do {
			let articleID = article.articleID
			let result = try await AIService.complete(
				provider: provider,
				systemPrompt: systemPrompt,
				userContent: userContent
			)

			guard !Task.isCancelled else {
				return
			}
			guard currentArticleID == articleID else {
				return
			}

			let (translatedTitle, translatedBody) = parseTranslationResult(result, hasTitle: !title.isEmpty)

			_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('translate')")
			_ = try? await webView.evaluateJavaScript("nnwShowTranslation(\(translatedTitle.javaScriptQuoted), \(translatedBody.javaScriptQuoted))")
			isTranslated = true
		} catch {
			if !Task.isCancelled {
				_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('translate')")
				showErrorAlert(error)
			}
		}

		isTranslating = false
		onStateChange?()
	}

	func performSummarize(article: Article, extractedContent: (title: String?, body: String?)?) async {
		guard let webView else {
			return
		}

		guard let provider = AIProviderManager.shared.summaryProvider else {
			showNoProviderAlert(for: NSLocalizedString("Summary", comment: "AI feature"))
			return
		}

		let targetLanguage = AIProviderManager.shared.targetLanguage
		let systemPrompt = AIService.appendLanguageInstruction(
			to: provider.summaryPrompt ?? "",
			verb: "Summarize",
			targetLanguage: targetLanguage
		)

		let text: String
		if let extracted = extractedContent {
			text = extracted.body ?? article.contentText ?? article.contentHTML ?? ""
		} else {
			text = article.contentText ?? article.contentHTML ?? ""
		}

		isSummarizing = true
		onStateChange?()
		_ = try? await webView.evaluateJavaScript("nnwShowAILoading('summary')")

		do {
			let articleID = article.articleID
			let result = try await AIService.complete(
				provider: provider,
				systemPrompt: systemPrompt,
				userContent: text
			)

			guard !Task.isCancelled else {
				return
			}
			guard currentArticleID == articleID else {
				return
			}

			_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('summary')")
			_ = try? await webView.evaluateJavaScript("nnwShowSummary(\(result.javaScriptQuoted))")
		} catch {
			if !Task.isCancelled {
				_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('summary')")
				showErrorAlert(error)
			}
		}

		isSummarizing = false
		onStateChange?()
	}

	// MARK: - Translation Result Parsing

	struct TranslationJSON: Decodable {
		let title: String?
		let body: String?
	}

	func parseTranslationResult(_ result: String, hasTitle: Bool) -> (String, String) {
		// Try JSON parsing first
		if let data = result.data(using: .utf8),
		   let json = try? JSONDecoder().decode(TranslationJSON.self, from: data) {
			let title = hasTitle ? (json.title ?? "") : ""
			let body = json.body ?? json.title ?? result
			return (title, body)
		}

		// Fallback: try to extract JSON from markdown code fences
		let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.hasPrefix("```") {
			let lines = trimmed.components(separatedBy: "\n")
			let jsonLines = lines.dropFirst().prefix(while: { !$0.hasPrefix("```") })
			let jsonString = jsonLines.joined(separator: "\n")
			if let data = jsonString.data(using: .utf8),
			   let json = try? JSONDecoder().decode(TranslationJSON.self, from: data) {
				let title = hasTitle ? (json.title ?? "") : ""
				let body = json.body ?? result
				return (title, body)
			}
		}

		// Final fallback: old newline-based split
		guard hasTitle else {
			return ("", result)
		}
		let splitLines = result.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
		if splitLines.count >= 2 {
			let titlePart = String(splitLines[0]).trimmingCharacters(in: .whitespacesAndNewlines)
			let bodyPart = String(splitLines[1]).trimmingCharacters(in: .whitespacesAndNewlines)
			if !bodyPart.isEmpty {
				return (titlePart, bodyPart)
			}
		}
		return ("", result)
	}

	// MARK: - Alerts

	func showNoProviderAlert(for feature: String) {
		let alert = NSAlert()
		alert.messageText = NSLocalizedString("No AI Provider Configured", comment: "AI alert")
		alert.informativeText = String.localizedStringWithFormat(
			NSLocalizedString("Please configure an AI provider for %@ in Preferences > AI.", comment: "AI alert format"),
			feature
		)
		alert.addButton(withTitle: NSLocalizedString("Open Preferences", comment: "AI alert button"))
		alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "AI alert button"))

		if alert.runModal() == .alertFirstButtonReturn {
			NotificationCenter.default.post(name: .OpenAIPreferences, object: nil)
		}
	}

	func showErrorAlert(_ error: Error) {
		let alert = NSAlert()
		alert.messageText = NSLocalizedString("AI Request Failed", comment: "AI alert")
		alert.informativeText = error.localizedDescription
		alert.runModal()
	}
}

// MARK: - String JavaScript Escaping

private extension String {

	var javaScriptQuoted: String {
		let escaped = self
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "'", with: "\\'")
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "\\n")
			.replacingOccurrences(of: "\r", with: "\\r")
			.replacingOccurrences(of: "\t", with: "\\t")
			.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
			.replacingOccurrences(of: "\u{2029}", with: "\\u2029")
		return "'\(escaped)'"
	}
}
