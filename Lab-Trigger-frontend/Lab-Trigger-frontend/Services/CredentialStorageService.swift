//
//  CredentialStorageService.swift
//  Lab-Trigger-frontend
//
//  Created by Sithum Raigamage on 2026-02-08.
//

import Foundation
// MARK: - Storage Service Protocol

protocol CredentialStorageProtocol {
    func save(_ credentials: JenkinsCredentials) throws
    func load() -> JenkinsCredentials?
    func loadAll() -> [JenkinsCredentials]
}

// MARK: - JSON File Storage Service

/// Service for storing credentials in a JSON file
/// ⚠️ WARNING: This is for development/testing only.
/// In production, use iOS Keychain for secure storage.
final class CredentialStorageService: CredentialStorageProtocol {
    
    // MARK: - Properties
    
    private let folderName = "Resources"
    private let fileName = "jenkins_credentials.json"
    
    /// Returns the project source directory (for development only)
    /// This uses #file to get the current source file location
    private var projectSourceDirectory: URL {
        // Get the directory containing this Swift file
        let currentFile = URL(fileURLWithPath: #file)
        // Go up to Lab-Trigger-frontend folder (Services -> Lab-Trigger-frontend)
        let projectDir = currentFile
            .deletingLastPathComponent()  // Remove CredentialStorageService.swift
            .deletingLastPathComponent()  // Remove Services/
        return projectDir
    }
    
    private var storageDirectory: URL {
        return projectSourceDirectory.appendingPathComponent(folderName, isDirectory: true)
    }
    
    private var fileURL: URL {
        return storageDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Singleton
    
    static let shared = CredentialStorageService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save credentials (adds new or updates existing)
    func save(_ credentials: JenkinsCredentials) throws {
        var allCredentials = loadAll()
        
        // Update updatedAt timestamp
        var updatedCredentials = credentials
        updatedCredentials.updatedAt = Date()
        
        // Check if this is an update or new entry
        if let index = allCredentials.firstIndex(where: { $0.id == credentials.id }) {
            allCredentials[index] = updatedCredentials
        } else {
            // If this is the first credential, make it default
            if allCredentials.isEmpty {
                updatedCredentials.isDefault = true
            }
            allCredentials.append(updatedCredentials)
        }
        
        try saveAll(allCredentials)
    }
    
    /// Load the default (or first) credential
    func load() -> JenkinsCredentials? {
        let all = loadAll()
        return all.first(where: { $0.isDefault }) ?? all.first
    }
    
    /// Load all saved credentials
    func loadAll() -> [JenkinsCredentials] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let credentials = try decoder.decode([JenkinsCredentials].self, from: data)
            return credentials
        } catch {
            return []
        }
    }
    
    // MARK: - Private Methods
    
    /// Ensures the storage directory exists
    private func ensureStorageDirectoryExists() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try fileManager.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func saveAll(_ credentials: [JenkinsCredentials]) throws {
        // Ensure storage folder exists
        try ensureStorageDirectoryExists()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(credentials)
        try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
    }
}

