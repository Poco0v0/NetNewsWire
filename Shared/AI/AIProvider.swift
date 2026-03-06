//
//  AIProvider.swift
//  NetNewsWire
//
//  Created by AI Assistant on 2026/3/6.
//  Copyright © 2026 Ranchero Software. All rights reserved.
//

import Foundation

struct AIProvider: Codable, Identifiable, Sendable, Equatable {

	let id: UUID
	var name: String
	var endpointURL: String
	var apiKey: String
	var model: String
	var translationPrompt: String?
	var summaryPrompt: String?

	private enum CodingKeys: String, CodingKey {
		case id, name, endpointURL, model, translationPrompt, summaryPrompt
		// apiKey is intentionally excluded — stored in Keychain
	}

	init(id: UUID = UUID(), name: String, endpointURL: String, apiKey: String, model: String,
		 translationPrompt: String? = nil, summaryPrompt: String? = nil) {
		self.id = id
		self.name = name
		self.endpointURL = endpointURL
		self.apiKey = apiKey
		self.model = model
		self.translationPrompt = translationPrompt
		self.summaryPrompt = summaryPrompt
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		endpointURL = try container.decode(String.self, forKey: .endpointURL)
		model = try container.decode(String.self, forKey: .model)
		translationPrompt = try container.decodeIfPresent(String.self, forKey: .translationPrompt)
		summaryPrompt = try container.decodeIfPresent(String.self, forKey: .summaryPrompt)
		apiKey = "" // Populated from Keychain by AIProviderManager
	}
}
