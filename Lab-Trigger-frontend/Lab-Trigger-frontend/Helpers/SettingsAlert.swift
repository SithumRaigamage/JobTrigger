//
//  SettingsAlert.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import Foundation

enum SettingsAlert: Identifiable, Hashable {
    case success
    case deleted
    case validationError(errors: [String])
    case connectionError(message: String)
    case saveError(message: String)

    var id: String {
        switch self {
        case .success: return "success"
        case .deleted: return "deleted"
        case .validationError: return "validationError"
        case .connectionError: return "connectionError"
        case .saveError: return "saveError"
        }
    }

    var title: String {
        switch self {
        case .success: return "Success"
        case .deleted: return "Deleted"
        case .validationError: return "Validation Error"
        case .connectionError: return "Connection Failed"
        case .saveError: return "Save Error"
        }
    }

    var message: String {
        switch self {
        case .success: 
            return "Settings saved successfully."
        case .deleted: 
            return "Settings deleted."
        case .validationError(let errors):
            return errors.joined(separator: "\n")
        case .connectionError(let message):
            return message
        case .saveError(let message):
            return "Failed to save: \(message)"
        }
    }
}
