//
//  JenkinsServerInfo.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import Foundation

// MARK: - Jenkins Server Info Response

struct JenkinsServerInfo: Codable {
    let mode: String?
    let nodeDescription: String?
    let nodeName: String?
    let numExecutors: Int?
    let useCrumbs: Bool?
    let useSecurity: Bool?
    
    // Simplified jobs list
    let jobs: [JenkinsJob]?
}

struct JenkinsJob: Codable, Identifiable {
    let name: String
    let url: String
    let color: String?
    
    var id: String { url }
}