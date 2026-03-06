//
//  AIPreferencesViewController.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import AppKit

@MainActor final class AIPreferencesViewController: NSViewController {

	private var tableView: NSTableView!
	private var scrollView: NSScrollView!
	private var addButton: NSButton!
	private var removeButton: NSButton!
	private var editButton: NSButton!
	private var translationPopUp: NSPopUpButton!
	private var summaryPopUp: NSPopUpButton!
	private var languagePopUp: NSPopUpButton!

	private var providers: [AIProvider] = []

	override func loadView() {
		let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 512, height: 400))
		view = containerView
		setupUI()
		reloadData()
	}

	override func viewWillAppear() {
		super.viewWillAppear()
		reloadData()
	}
}

// MARK: - UI Setup

private extension AIPreferencesViewController {

	func setupUI() {
		let providersLabel = makeLabel("AI Providers:")
		providersLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
		view.addSubview(providersLabel)

		setupTableView()
		setupButtons()
		setupPopUps()

		let translationLabel = makeLabel("Translation Provider:")
		let summaryLabel = makeLabel("Summary Provider:")
		let languageLabel = makeLabel("Target Language:")

		view.addSubview(translationLabel)
		view.addSubview(summaryLabel)
		view.addSubview(languageLabel)

		NSLayoutConstraint.activate([
			providersLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
			providersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

			scrollView.topAnchor.constraint(equalTo: providersLabel.bottomAnchor, constant: 8),
			scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
			scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
			scrollView.heightAnchor.constraint(equalToConstant: 140),

			addButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 4),
			addButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			removeButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 4),
			removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 4),
			editButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 4),
			editButton.leadingAnchor.constraint(equalTo: removeButton.trailingAnchor, constant: 4),

			translationLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 24),
			translationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
			translationLabel.widthAnchor.constraint(equalToConstant: 150),

			translationPopUp.centerYAnchor.constraint(equalTo: translationLabel.centerYAnchor),
			translationPopUp.leadingAnchor.constraint(equalTo: translationLabel.trailingAnchor, constant: 8),
			translationPopUp.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

			summaryLabel.topAnchor.constraint(equalTo: translationLabel.bottomAnchor, constant: 12),
			summaryLabel.leadingAnchor.constraint(equalTo: translationLabel.leadingAnchor),
			summaryLabel.widthAnchor.constraint(equalToConstant: 150),

			summaryPopUp.centerYAnchor.constraint(equalTo: summaryLabel.centerYAnchor),
			summaryPopUp.leadingAnchor.constraint(equalTo: summaryLabel.trailingAnchor, constant: 8),
			summaryPopUp.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

			languageLabel.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 12),
			languageLabel.leadingAnchor.constraint(equalTo: translationLabel.leadingAnchor),
			languageLabel.widthAnchor.constraint(equalToConstant: 150),

			languagePopUp.centerYAnchor.constraint(equalTo: languageLabel.centerYAnchor),
			languagePopUp.leadingAnchor.constraint(equalTo: languageLabel.trailingAnchor, constant: 8),
			languagePopUp.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
		])
	}

	func setupTableView() {
		tableView = NSTableView()
		tableView.style = .fullWidth
		tableView.usesAlternatingRowBackgroundColors = true
		tableView.allowsMultipleSelection = false
		tableView.delegate = self
		tableView.dataSource = self
		tableView.doubleAction = #selector(editProvider(_:))
		tableView.target = self

		let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
		nameColumn.title = NSLocalizedString("Name", comment: "AI Preferences column")
		nameColumn.width = 160
		tableView.addTableColumn(nameColumn)

		let modelColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("model"))
		modelColumn.title = NSLocalizedString("Model", comment: "AI Preferences column")
		modelColumn.width = 150
		tableView.addTableColumn(modelColumn)

		let usageColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("usage"))
		usageColumn.title = NSLocalizedString("Usage", comment: "AI Preferences column")
		usageColumn.width = 130
		tableView.addTableColumn(usageColumn)

		scrollView = NSScrollView()
		scrollView.documentView = tableView
		scrollView.hasVerticalScroller = true
		scrollView.borderType = .bezelBorder
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(scrollView)
	}

	func setupButtons() {
		addButton = NSButton(title: "+", target: self, action: #selector(addProvider(_:)))
		addButton.bezelStyle = .smallSquare
		addButton.translatesAutoresizingMaskIntoConstraints = false
		addButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
		view.addSubview(addButton)

		removeButton = NSButton(title: "\u{2212}", target: self, action: #selector(removeProvider(_:)))
		removeButton.bezelStyle = .smallSquare
		removeButton.translatesAutoresizingMaskIntoConstraints = false
		removeButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
		view.addSubview(removeButton)

		editButton = NSButton(title: NSLocalizedString("Edit", comment: "AI Preferences button"), target: self, action: #selector(editProvider(_:)))
		editButton.bezelStyle = .smallSquare
		editButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(editButton)
	}

	func setupPopUps() {
		translationPopUp = NSPopUpButton()
		translationPopUp.translatesAutoresizingMaskIntoConstraints = false
		translationPopUp.target = self
		translationPopUp.action = #selector(translationProviderChanged(_:))
		view.addSubview(translationPopUp)

		summaryPopUp = NSPopUpButton()
		summaryPopUp.translatesAutoresizingMaskIntoConstraints = false
		summaryPopUp.target = self
		summaryPopUp.action = #selector(summaryProviderChanged(_:))
		view.addSubview(summaryPopUp)

		languagePopUp = NSPopUpButton()
		languagePopUp.translatesAutoresizingMaskIntoConstraints = false
		languagePopUp.target = self
		languagePopUp.action = #selector(targetLanguageChanged(_:))
		view.addSubview(languagePopUp)
	}

	func makeLabel(_ text: String) -> NSTextField {
		let label = NSTextField(labelWithString: text)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.alignment = .right
		return label
	}
}

// MARK: - Data

private extension AIPreferencesViewController {

	func reloadData() {
		providers = AIProviderManager.shared.providers
		tableView.reloadData()
		updatePopUps()
		updateButtonStates()
	}

	func updatePopUps() {
		updateProviderPopUp(translationPopUp, selectedID: AIProviderManager.shared.translationProviderID)
		updateProviderPopUp(summaryPopUp, selectedID: AIProviderManager.shared.summaryProviderID)
		updateLanguagePopUp()
	}

	func updateProviderPopUp(_ popUp: NSPopUpButton, selectedID: UUID?) {
		popUp.removeAllItems()
		popUp.addItem(withTitle: NSLocalizedString("None", comment: "AI Preferences popup"))
		popUp.menu?.items.first?.representedObject = nil

		for provider in providers {
			let title: String = "\(provider.name) (\(provider.model))"
			popUp.addItem(withTitle: title)
			popUp.lastItem?.representedObject = provider.id.uuidString
		}

		if let selectedID {
			let index: Int? = providers.firstIndex(where: { $0.id == selectedID })
			if let index {
				popUp.selectItem(at: index + 1)
			} else {
				popUp.selectItem(at: 0)
			}
		} else {
			popUp.selectItem(at: 0)
		}
	}

	func updateLanguagePopUp() {
		languagePopUp.removeAllItems()
		let languages = AIProviderManager.availableLanguages
		for language in languages {
			languagePopUp.addItem(withTitle: language)
		}

		let current = AIProviderManager.shared.targetLanguage
		if let index = languages.firstIndex(of: current) {
			languagePopUp.selectItem(at: index)
		} else {
			languagePopUp.addItem(withTitle: current)
			languagePopUp.selectItem(withTitle: current)
		}
	}

	func updateButtonStates() {
		let hasSelection = tableView.selectedRow >= 0
		removeButton.isEnabled = hasSelection
		editButton.isEnabled = hasSelection
	}

	func usageString(for provider: AIProvider) -> String {
		var usages = [String]()
		if AIProviderManager.shared.translationProviderID == provider.id {
			usages.append(NSLocalizedString("Translate", comment: "AI usage"))
		}
		if AIProviderManager.shared.summaryProviderID == provider.id {
			usages.append(NSLocalizedString("Summary", comment: "AI usage"))
		}
		return usages.isEmpty ? "-" : usages.joined(separator: ", ")
	}
}

// MARK: - Actions

private extension AIPreferencesViewController {

	@objc func addProvider(_ sender: Any?) {
		let editVC = AIProviderEditViewController(provider: nil)
		editVC.onSave = { [weak self] provider in
			AIProviderManager.shared.addProvider(provider)
			self?.reloadData()
		}
		presentAsSheet(editVC)
	}

	@objc func removeProvider(_ sender: Any?) {
		let row = tableView.selectedRow
		guard row >= 0 && row < providers.count else {
			return
		}

		let provider = providers[row]
		let alert = NSAlert()
		alert.messageText = NSLocalizedString("Remove AI Provider?", comment: "AI Preferences alert")
		alert.informativeText = String.localizedStringWithFormat(
			NSLocalizedString("Are you sure you want to remove \"%@\"?", comment: "AI Preferences alert format"),
			provider.name
		)
		alert.addButton(withTitle: NSLocalizedString("Remove", comment: "AI Preferences button"))
		alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "AI Preferences button"))
		alert.alertStyle = .warning

		guard alert.runModal() == .alertFirstButtonReturn else {
			return
		}

		AIProviderManager.shared.removeProvider(id: provider.id)
		reloadData()
	}

	@objc func editProvider(_ sender: Any?) {
		let row = tableView.selectedRow
		guard row >= 0 && row < providers.count else {
			return
		}

		let provider = providers[row]
		let editVC = AIProviderEditViewController(provider: provider)
		editVC.onSave = { [weak self] updatedProvider in
			AIProviderManager.shared.updateProvider(updatedProvider)
			self?.reloadData()
		}
		presentAsSheet(editVC)
	}

	@objc func translationProviderChanged(_ sender: NSPopUpButton) {
		let selectedIndex = sender.indexOfSelectedItem
		if selectedIndex == 0 {
			AIProviderManager.shared.translationProviderID = nil
		} else {
			let provider = providers[selectedIndex - 1]
			AIProviderManager.shared.translationProviderID = provider.id
		}
		tableView.reloadData()
	}

	@objc func summaryProviderChanged(_ sender: NSPopUpButton) {
		let selectedIndex = sender.indexOfSelectedItem
		if selectedIndex == 0 {
			AIProviderManager.shared.summaryProviderID = nil
		} else {
			let provider = providers[selectedIndex - 1]
			AIProviderManager.shared.summaryProviderID = provider.id
		}
		tableView.reloadData()
	}

	@objc func targetLanguageChanged(_ sender: NSPopUpButton) {
		guard let title = sender.titleOfSelectedItem else {
			return
		}
		AIProviderManager.shared.targetLanguage = title
	}
}

// MARK: - NSTableViewDataSource

extension AIPreferencesViewController: NSTableViewDataSource {

	func numberOfRows(in tableView: NSTableView) -> Int {
		providers.count
	}
}

// MARK: - NSTableViewDelegate

extension AIPreferencesViewController: NSTableViewDelegate {

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard row < providers.count, let identifier = tableColumn?.identifier else {
			return nil
		}

		let provider = providers[row]

		let cellIdentifier = NSUserInterfaceItemIdentifier("AIProviderCell_\(identifier.rawValue)")
		let textField: NSTextField
		if let existing = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTextField {
			textField = existing
		} else {
			textField = NSTextField(labelWithString: "")
			textField.identifier = cellIdentifier
			textField.lineBreakMode = .byTruncatingTail
		}

		switch identifier.rawValue {
		case "name":
			textField.stringValue = provider.name
		case "model":
			textField.stringValue = provider.model
		case "usage":
			textField.stringValue = usageString(for: provider)
		default:
			textField.stringValue = ""
		}

		return textField
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		updateButtonStates()
	}
}
