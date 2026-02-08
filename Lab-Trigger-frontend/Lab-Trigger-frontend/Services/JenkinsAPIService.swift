//
//  JenkinsAPIService.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import Foundation

// MARK: - Jenkins API Service

final class JenkinsAPIService {
    
    // MARK: - Singleton
    
    static let shared = JenkinsAPIService()
    
    private init() {}
    
    // MARK: - Properties
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    // MARK: - Public Methods
    
    /// Test connection to Jenkins server with provided credentials
    func testConnection(
        url: String,
        username: String,
        password: String,
        paramToken: String? = nil
    ) async -> Result<ConnectionResult, JenkinsAPIError> {
        
        // Normalize URL
        var normalizedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedURL.hasSuffix("/") {
            normalizedURL.removeLast()
        }
        
        // Build API endpoint with optional token parameter
        var urlString = "\(normalizedURL)/api/json"
        if let token = paramToken, !token.isEmpty {
            urlString += "?token=\(token)"
        }
        
        guard let apiURL = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        // Create request with Basic Auth
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknown)
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Parse server info
                let decoder = JSONDecoder()
                if let serverInfo = try? decoder.decode(JenkinsServerInfo.self, from: data) {
                    let jobCount = serverInfo.jobs?.count ?? 0
                    return .success(ConnectionResult(
                        isSuccess: true,
                        serverVersion: serverInfo.mode,
                        message: "Connected successfully! Found \(jobCount) jobs."
                    ))
                } else {
                    return .success(ConnectionResult(
                        isSuccess: true,
                        serverVersion: nil,
                        message: "Connected successfully!"
                    ))
                }
                
            case 401, 403:
                return .failure(.invalidCredentials)
                
            case 404:
                return .failure(.invalidURL)
                
            default:
                return .failure(.serverError(httpResponse.statusCode))
            }
            
        } catch let error as URLError {
            return .failure(.networkError(error))
        } catch {
            return .failure(.unknown)
        }
    }
    
    /// Fetch all Jenkins jobs from the server
    func fetchJobs(
        url: String,
        username: String,
        password: String,
        paramToken: String? = nil
    ) async -> Result<[JenkinsJob], JenkinsAPIError> {
        
        // Normalize URL
        var normalizedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedURL.hasSuffix("/") {
            normalizedURL.removeLast()
        }
        
        // Build API endpoint with tree parameter to get jobs
        var urlString = "\(normalizedURL)/api/json?tree=jobs[name,url,color]"
        if let token = paramToken, !token.isEmpty {
            urlString += "&token=\(token)"
        }
        
        guard let apiURL = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        // Create request with Basic Auth
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknown)
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Parse server info with jobs
                let decoder = JSONDecoder()
                if let serverInfo = try? decoder.decode(JenkinsServerInfo.self, from: data),
                   let jobs = serverInfo.jobs {
                    return .success(jobs)
                } else {
                    return .failure(.decodingError(NSError(domain: "JenkinsAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse jobs data"])))
                }
                
            case 401, 403:
                return .failure(.invalidCredentials)
                
            case 404:
                return .failure(.invalidURL)
                
            default:
                return .failure(.serverError(httpResponse.statusCode))
            }
            
        } catch let error as URLError {
            return .failure(.networkError(error))
        } catch {
            return .failure(.unknown)
        }
    }
}
