//
//  AIProviderManager.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import Foundation

@MainActor final class AIProviderManager {

	static let shared = AIProviderManager()

	private struct Key {
		static let providersData = "aiProvidersData"
		static let translationProviderID = "aiTranslationProviderID"
		static let summaryProviderID = "aiSummaryProviderID"
		static let targetLanguage = "aiTargetLanguage"
	}

	private let defaults = UserDefaults.standard
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()

	// MARK: - Providers

	var providers: [AIProvider] {
		guard let data = defaults.data(forKey: Key.providersData) else {
			return []
		}
		return (try? decoder.decode([AIProvider].self, from: data)) ?? []
	}

	func saveProviders(_ providers: [AIProvider]) {
		guard let data = try? encoder.encode(providers) else {
			return
		}
		defaults.set(data, forKey: Key.providersData)
	}

	func addProvider(_ provider: AIProvider) {
		var list = providers
		list.append(provider)
		saveProviders(list)
	}

	func updateProvider(_ provider: AIProvider) {
		var list = providers
		guard let index = list.firstIndex(where: { $0.id == provider.id }) else {
			return
		}
		list[index] = provider
		saveProviders(list)
	}

	func removeProvider(id: UUID) {
		var list = providers
		list.removeAll { $0.id == id }
		saveProviders(list)

		if translationProviderID == id {
			translationProviderID = nil
		}
		if summaryProviderID == id {
			summaryProviderID = nil
		}
	}

	// MARK: - Provider Selection

	var translationProviderID: UUID? {
		get {
			guard let string = defaults.string(forKey: Key.translationProviderID) else {
				return nil
			}
			return UUID(uuidString: string)
		}
		set {
			defaults.set(newValue?.uuidString, forKey: Key.translationProviderID)
		}
	}

	var summaryProviderID: UUID? {
		get {
			guard let string = defaults.string(forKey: Key.summaryProviderID) else {
				return nil
			}
			return UUID(uuidString: string)
		}
		set {
			defaults.set(newValue?.uuidString, forKey: Key.summaryProviderID)
		}
	}

	var translationProvider: AIProvider? {
		guard let id = translationProviderID else {
			return nil
		}
		return providers.first { $0.id == id }
	}

	var summaryProvider: AIProvider? {
		guard let id = summaryProviderID else {
			return nil
		}
		return providers.first { $0.id == id }
	}

	// MARK: - Target Language

	var targetLanguage: String {
		get {
			defaults.string(forKey: Key.targetLanguage) ?? "Chinese (Simplified)"
		}
		set {
			defaults.set(newValue, forKey: Key.targetLanguage)
		}
	}

	static let availableLanguages = [
		"Chinese (Simplified)",
		"Chinese (Traditional)",
		"English",
		"Japanese",
		"Korean",
		"French",
		"German",
		"Spanish",
		"Portuguese",
		"Russian",
		"Arabic",
		"Italian",
		"Dutch",
		"Thai",
		"Vietnamese",
		"Indonesian"
	]
}
