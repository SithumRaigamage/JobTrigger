//
//  User.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Foundation

/// Represents a registered user in the system
struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String
    let password: String // ⚠️ Plaintext for development only
    
    init(id: UUID = UUID(), email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}
