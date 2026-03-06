//
//  AIProviderManager.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import Foundation
import os
import Secrets

@MainActor final class AIProviderManager {

	static let shared = AIProviderManager()

	private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AIProviderManager")

	private struct Key {
		static let providersData = "aiProvidersData"
		static let translationProviderID = "aiTranslationProviderID"
		static let summaryProviderID = "aiSummaryProviderID"
		static let targetLanguage = "aiTargetLanguage"
	}

	private static let keychainService = "com.ranchero.NetNewsWire.ai-provider"

	private let defaults = UserDefaults.standard
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()

	// MARK: - Providers

	var providers: [AIProvider] {
		guard let data = defaults.data(forKey: Key.providersData) else {
			return []
		}
		guard var list = try? decoder.decode([AIProvider].self, from: data) else {
			return []
		}
		for i in list.indices {
			list[i].apiKey = retrieveAPIKey(forProviderID: list[i].id)
		}
		return list
	}

	func saveProviders(_ providers: [AIProvider]) {
		guard let data = try? encoder.encode(providers) else {
			return
		}
		defaults.set(data, forKey: Key.providersData)

		for provider in providers {
			storeAPIKey(provider.apiKey, forProviderID: provider.id)
		}
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
		deleteAPIKey(forProviderID: id)

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

// MARK: - Keychain

private extension AIProviderManager {

	func storeAPIKey(_ apiKey: String, forProviderID id: UUID) {
		do {
			try CredentialsManager.removeCredentials(
				type: .aiProviderAPIKey,
				server: Self.keychainService,
				username: id.uuidString
			)

			guard !apiKey.isEmpty else {
				return
			}

			let credentials = Credentials(
				type: .aiProviderAPIKey,
				username: id.uuidString,
				secret: apiKey
			)
			try CredentialsManager.storeCredentials(credentials, server: Self.keychainService)
		} catch {
			logger.error("Failed to store API key for provider \(id): \(error)")
		}
	}

	func retrieveAPIKey(forProviderID id: UUID) -> String {
		do {
			let credentials = try CredentialsManager.retrieveCredentials(
				type: .aiProviderAPIKey,
				server: Self.keychainService,
				username: id.uuidString
			)
			return credentials?.secret ?? ""
		} catch {
			logger.error("Failed to retrieve API key for provider \(id): \(error)")
			return ""
		}
	}

	func deleteAPIKey(forProviderID id: UUID) {
		do {
			try CredentialsManager.removeCredentials(
				type: .aiProviderAPIKey,
				server: Self.keychainService,
				username: id.uuidString
			)
		} catch {
			logger.error("Failed to delete API key for provider \(id): \(error)")
		}
	}
}
