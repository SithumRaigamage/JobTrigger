//
//  User.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-09.
//

import Foundation

/// Represents a registered user in the system
struct User: Codable, Identifiable, Equatable {
  let id: String
  let email: String

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case email
  }
}
