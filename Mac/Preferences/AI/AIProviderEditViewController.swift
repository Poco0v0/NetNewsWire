//
//  AIProviderEditViewController.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit

@MainActor final class AIProviderEditViewController: NSViewController {

	var onSave: ((AIProvider) -> Void)?

	private let existingProvider: AIProvider?

	private var nameField: NSTextField!
	private var endpointField: NSTextField!
	private var apiKeyField: NSSecureTextField!
	private var modelField: NSTextField!
	private var translationPromptView: NSTextView?
	private var summaryPromptView: NSTextView?

	init(provider: AIProvider?) {
		self.existingProvider = provider
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 480))
		view = containerView
		setupUI()
		populateFields()
	}
}

// MARK: - UI Setup

private extension AIProviderEditViewController {

	func setupUI() {
		let nameLabel = makeLabel("Name:")
		nameField = makeTextField(placeholder: "My OpenAI Provider")

		let endpointLabel = makeLabel("Endpoint URL:")
		endpointField = makeTextField(placeholder: "https://api.openai.com/v1/chat/completions")

		let apiKeyLabel = makeLabel("API Key:")
		apiKeyField = NSSecureTextField()
		apiKeyField.translatesAutoresizingMaskIntoConstraints = false
		apiKeyField.placeholderString = "sk-..."

		let modelLabel = makeLabel("Model:")
		modelField = makeTextField(placeholder: "gpt-4o-mini")

		let translationPromptLabel = makeLabel("Translation Prompt:")
		let translationPromptScroll = makeTextView()
		translationPromptView = translationPromptScroll.documentView as? NSTextView

		let summaryPromptLabel = makeLabel("Summary Prompt:")
		let summaryPromptScroll = makeTextView()
		summaryPromptView = summaryPromptScroll.documentView as? NSTextView

		let promptHint = NSTextField(labelWithString: NSLocalizedString("Optional. Target language is appended automatically.", comment: "AI Provider edit hint"))
		promptHint.translatesAutoresizingMaskIntoConstraints = false
		promptHint.font = NSFont.systemFont(ofSize: 11)
		promptHint.textColor = .secondaryLabelColor

		let saveButton = NSButton(title: NSLocalizedString("Save", comment: "AI Provider edit button"), target: self, action: #selector(save(_:)))
		saveButton.keyEquivalent = "\r"
		saveButton.translatesAutoresizingMaskIntoConstraints = false

		let cancelButton = NSButton(title: NSLocalizedString("Cancel", comment: "AI Provider edit button"), target: self, action: #selector(cancel(_:)))
		cancelButton.keyEquivalent = "\u{1b}"
		cancelButton.translatesAutoresizingMaskIntoConstraints = false

		let allViews: [NSView] = [nameLabel, nameField, endpointLabel, endpointField,
								  apiKeyLabel, apiKeyField, modelLabel, modelField,
								  translationPromptLabel, translationPromptScroll,
								  summaryPromptLabel, summaryPromptScroll,
								  promptHint, saveButton, cancelButton]
		for v in allViews {
			view.addSubview(v)
		}

		let labelWidth: CGFloat = 130
		let margin: CGFloat = 20

		NSLayoutConstraint.activate([
			nameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
			nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin),
			nameLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			nameField.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
			nameField.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
			nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),

			endpointLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
			endpointLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			endpointLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			endpointField.centerYAnchor.constraint(equalTo: endpointLabel.centerYAnchor),
			endpointField.leadingAnchor.constraint(equalTo: endpointLabel.trailingAnchor, constant: 8),
			endpointField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),

			apiKeyLabel.topAnchor.constraint(equalTo: endpointLabel.bottomAnchor, constant: 12),
			apiKeyLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			apiKeyLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			apiKeyField.centerYAnchor.constraint(equalTo: apiKeyLabel.centerYAnchor),
			apiKeyField.leadingAnchor.constraint(equalTo: apiKeyLabel.trailingAnchor, constant: 8),
			apiKeyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),

			modelLabel.topAnchor.constraint(equalTo: apiKeyLabel.bottomAnchor, constant: 12),
			modelLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			modelLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			modelField.centerYAnchor.constraint(equalTo: modelLabel.centerYAnchor),
			modelField.leadingAnchor.constraint(equalTo: modelLabel.trailingAnchor, constant: 8),
			modelField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),

			translationPromptLabel.topAnchor.constraint(equalTo: modelLabel.bottomAnchor, constant: 16),
			translationPromptLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			translationPromptLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			translationPromptScroll.topAnchor.constraint(equalTo: translationPromptLabel.topAnchor),
			translationPromptScroll.leadingAnchor.constraint(equalTo: translationPromptLabel.trailingAnchor, constant: 8),
			translationPromptScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
			translationPromptScroll.heightAnchor.constraint(equalToConstant: 70),

			summaryPromptLabel.topAnchor.constraint(equalTo: translationPromptScroll.bottomAnchor, constant: 12),
			summaryPromptLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
			summaryPromptLabel.widthAnchor.constraint(equalToConstant: labelWidth),

			summaryPromptScroll.topAnchor.constraint(equalTo: summaryPromptLabel.topAnchor),
			summaryPromptScroll.leadingAnchor.constraint(equalTo: summaryPromptLabel.trailingAnchor, constant: 8),
			summaryPromptScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
			summaryPromptScroll.heightAnchor.constraint(equalToConstant: 70),

			promptHint.topAnchor.constraint(equalTo: summaryPromptScroll.bottomAnchor, constant: 4),
			promptHint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),

			cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
			cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -8),

			saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
			saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin),
		])
	}

	func populateFields() {
		guard let provider = existingProvider else {
			return
		}
		nameField.stringValue = provider.name
		endpointField.stringValue = provider.endpointURL
		apiKeyField.stringValue = provider.apiKey
		modelField.stringValue = provider.model
		translationPromptView?.string = provider.translationPrompt ?? ""
		summaryPromptView?.string = provider.summaryPrompt ?? ""
	}

	func makeLabel(_ text: String) -> NSTextField {
		let label = NSTextField(labelWithString: text)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.alignment = .right
		return label
	}

	func makeTextField(placeholder: String) -> NSTextField {
		let field = NSTextField()
		field.translatesAutoresizingMaskIntoConstraints = false
		field.placeholderString = placeholder
		return field
	}

	func makeTextView() -> NSScrollView {
		let scrollView = NSScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.hasVerticalScroller = true
		scrollView.borderType = .bezelBorder

		let textView = NSTextView()
		textView.isRichText = false
		textView.font = NSFont.systemFont(ofSize: 12)
		textView.isEditable = true
		textView.isSelectable = true
		textView.autoresizingMask = [.width]
		textView.textContainer?.widthTracksTextView = true

		scrollView.documentView = textView
		return scrollView
	}
}

// MARK: - Actions

private extension AIProviderEditViewController {

	@objc func save(_ sender: Any?) {
		let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		let rawEndpoint = endpointField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		let apiKey = apiKeyField.stringValue
		let model = modelField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

		guard !name.isEmpty else {
			showValidationError(NSLocalizedString("Name is required.", comment: "AI Provider validation"))
			return
		}
		guard !rawEndpoint.isEmpty else {
			showValidationError(NSLocalizedString("Endpoint URL is required.", comment: "AI Provider validation"))
			return
		}
		guard !apiKey.isEmpty else {
			showValidationError(NSLocalizedString("API Key is required.", comment: "AI Provider validation"))
			return
		}
		guard !model.isEmpty else {
			showValidationError(NSLocalizedString("Model is required.", comment: "AI Provider validation"))
			return
		}

		let endpoint = Self.normalizeEndpointURL(rawEndpoint)

		let translationPrompt = (translationPromptView?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
		let summaryPrompt = (summaryPromptView?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

		let provider = AIProvider(
			id: existingProvider?.id ?? UUID(),
			name: name,
			endpointURL: endpoint,
			apiKey: apiKey,
			model: model,
			translationPrompt: translationPrompt.isEmpty ? nil : translationPrompt,
			summaryPrompt: summaryPrompt.isEmpty ? nil : summaryPrompt
		)

		onSave?(provider)
		dismiss(nil)
	}

	@objc func cancel(_ sender: Any?) {
		dismiss(nil)
	}

	func showValidationError(_ message: String) {
		let alert = NSAlert()
		alert.messageText = NSLocalizedString("Validation Error", comment: "AI Provider validation alert")
		alert.informativeText = message
		alert.runModal()
	}

	/// Normalize endpoint URL: ensure https scheme and /v1/chat/completions path.
	/// Uses URLComponents to inspect path only, so query parameters are preserved.
	static func normalizeEndpointURL(_ raw: String) -> String {
		var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)

		if !url.contains("://") {
			url = "https://" + url
		}

		while url.hasSuffix("/") {
			url = String(url.dropLast())
		}

		guard var components = URLComponents(string: url) else {
			return url
		}

		let path = components.path

		if path.hasSuffix("/chat/completions") {
			return components.string ?? url
		}

		if path.hasSuffix("/v1") {
			components.path = path + "/chat/completions"
		} else if path.hasSuffix("/v1/chat") {
			components.path = path + "/completions"
		} else {
			components.path = path + "/v1/chat/completions"
		}

		return components.string ?? url
	}
}
