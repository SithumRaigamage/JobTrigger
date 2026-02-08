//
//  ConnectionResult.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import Foundation

// MARK: - Connection Result

struct ConnectionResult {
    let isSuccess: Bool
    let serverVersion: String?
    let message: String
}