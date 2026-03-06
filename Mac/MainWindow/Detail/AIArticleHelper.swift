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
		currentArticleID = articleID
		isTranslated = false
		isTranslating = false
		isSummarizing = false
	}

	// MARK: - Translation

	var canTranslate: Bool {
		currentArticleID != nil && !isTranslating
	}

	func toggleTranslation(article: Article) async {
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

		let title = article.title ?? ""
		let body = article.contentHTML ?? article.contentText ?? ""
		let userContent = "Title: \(title)\n\nBody:\n\(body)"

		isTranslating = true
		_ = try? await webView.evaluateJavaScript("nnwShowAILoading('translate')")

		do {
			let articleID = article.articleID
			let result = try await AIService.complete(
				provider: provider,
				systemPrompt: systemPrompt,
				userContent: userContent
			)

			guard currentArticleID == articleID else {
				return
			}

			let (translatedTitle, translatedBody) = parseTranslationResult(result, hasTitle: !title.isEmpty)

			_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('translate')")
			_ = try? await webView.evaluateJavaScript("nnwShowTranslation(\(translatedTitle.javaScriptQuoted), \(translatedBody.javaScriptQuoted))")
			isTranslated = true
		} catch {
			_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('translate')")
			showErrorAlert(error)
		}

		isTranslating = false
	}

	// MARK: - Summary

	var canSummarize: Bool {
		currentArticleID != nil && !isSummarizing
	}

	func summarize(article: Article) async {
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
		let text = article.contentText ?? article.contentHTML ?? ""

		isSummarizing = true
		_ = try? await webView.evaluateJavaScript("nnwShowAILoading('summary')")

		do {
			let articleID = article.articleID
			let result = try await AIService.complete(
				provider: provider,
				systemPrompt: systemPrompt,
				userContent: text
			)

			guard currentArticleID == articleID else {
				return
			}

			_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('summary')")
			_ = try? await webView.evaluateJavaScript("nnwShowSummary(\(result.javaScriptQuoted))")
		} catch {
			_ = try? await webView.evaluateJavaScript("nnwRemoveAILoading('summary')")
			showErrorAlert(error)
		}

		isSummarizing = false
	}
}

// MARK: - Private

private extension AIArticleHelper {

	func parseTranslationResult(_ result: String, hasTitle: Bool) -> (String, String) {
		guard hasTitle else {
			return ("", result)
		}

		let lines = result.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
		if lines.count >= 2 {
			let titlePart = String(lines[0]).trimmingCharacters(in: .whitespacesAndNewlines)
			let bodyPart = String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines)
			if !bodyPart.isEmpty {
				return (titlePart, bodyPart)
			}
		}

		return ("", result)
	}

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
