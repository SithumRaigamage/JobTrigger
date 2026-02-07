//
//  SettingsAlert.swift
//  Lab-Trigger-frontend
//
//  Created by Thamindu Dasanayake on 2026-02-08.
//

import Foundation

enum SettingsAlert: Identifiable {
    case success
    case deleted

    var id: Int { hashValue }

    var title: String {
        switch self {
        case .success: return "Success"
        case .deleted: return "Deleted"
        }
    }

    var message: String {
        switch self {
        case .success: return "Settings saved successfully."
        case .deleted: return "Settings deleted."
        }
    }
}
