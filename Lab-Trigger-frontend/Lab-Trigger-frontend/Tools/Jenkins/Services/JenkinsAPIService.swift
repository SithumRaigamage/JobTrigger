//
//  JenkinsAPIService.swift
//  Lab-Trigger-frontend
//
//  Created on 2026-02-08.
//

import Foundation
import SwiftUI

// MARK: - API Response Structs for Logs
struct LogResponse {
  let text: String
  let nextOffset: Int
  let hasMoreData: Bool
}

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

    print("🔍 [JenkinsAPIService] Testing connection to: \(urlString)")
    print(
      "🔍 [JenkinsAPIService] Using credentials - Username: \(username), Token: \(paramToken ?? "None")"
    )

    guard let apiURL = URL(string: urlString) else {
      print("❌ [JenkinsAPIService] Invalid URL: \(urlString)")
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
      print("🔍 [JenkinsAPIService] Sending request...")
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ [JenkinsAPIService] Failed to cast response to HTTPURLResponse")
        return .failure(.unknown)
      }

      print("✅ [JenkinsAPIService] Received response with status code: \(httpResponse.statusCode)")

      switch httpResponse.statusCode {
      case 200:
        // Parse server info
        let decoder = JSONDecoder()
        if let serverInfo = try? decoder.decode(JenkinsServerInfo.self, from: data) {
          let jobCount = serverInfo.jobs?.count ?? 0
          return .success(
            ConnectionResult(
              isSuccess: true,
              serverVersion: serverInfo.mode,
              message: "Connected successfully! Found \(jobCount) jobs."
            ))
        } else {
          return .success(
            ConnectionResult(
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

    // Build API endpoint with a very deep recursive tree query (6 levels)
    // This ensures almost all nested structures are captured with full metadata
    let fields =
      "name,url,color,description,lastBuild[number,url,result,building,estimatedDuration,timestamp]"
    let level6 = fields
    let level5 = "\(fields),jobs[\(level6)]"
    let level4 = "\(fields),jobs[\(level5)]"
    let level3 = "\(fields),jobs[\(level4)]"
    let level2 = "\(fields),jobs[\(level3)]"
    let treeQuery = "jobs[\(level2)]"

    var urlString = "\(normalizedURL)/api/json?tree=\(treeQuery)"
    if let token = paramToken, !token.isEmpty {
      urlString += "&token=\(token)"
    }

    print("🔍 [JenkinsAPIService] Fetching jobs from: \(urlString)")

    guard let apiURL = URL(string: urlString) else {
      print("❌ [JenkinsAPIService] Invalid URL for fetchJobs: \(urlString)")
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
      print("🔍 [JenkinsAPIService] Sending fetchJobs request...")
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ [JenkinsAPIService] Failed to cast fetchJobs response")
        return .failure(.unknown)
      }

      print("✅ [JenkinsAPIService] fetchJobs response: \(httpResponse.statusCode)")

      switch httpResponse.statusCode {
      case 200:
        // Parse server info with jobs
        let decoder = JSONDecoder()
        if let serverInfo = try? decoder.decode(JenkinsServerInfo.self, from: data),
          let jobs = serverInfo.jobs
        {
          return .success(jobs)
        } else {
          return .failure(
            .decodingError(
              NSError(
                domain: "JenkinsAPI", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse jobs data"])))
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

  /// Fetch detailed information for a specific job (US-09)
  func fetchJobDetails(
    url: String,
    username: String,
    password: String,
    paramToken: String? = nil
  ) async -> Result<JenkinsJob, JenkinsAPIError> {

    var normalizedURL = url
    if !normalizedURL.hasSuffix("/") {
      normalizedURL += "/"
    }

    // Detailed tree query for parameters and health reports
    let detailsTree =
      "name,url,color,description,lastBuild[number,url,result,timestamp,duration,building,estimatedDuration],healthReport[description,iconClassName,score],property[parameterDefinitions[name,type,description,defaultParameterValue[value],choices]]"
    let urlString = "\(normalizedURL)api/json?tree=\(detailsTree)"

    print("🔍 [JenkinsAPIService] Fetching detailed job info at: \(urlString)")

    guard let apiURL = URL(string: urlString) else {
      return .failure(.invalidURL)
    }

    var request = URLRequest(url: apiURL)
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

      if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
        return .failure(.invalidCredentials)
      }

      if httpResponse.statusCode != 200 {
        return .failure(.serverError(httpResponse.statusCode))
      }

      let jobDetails = try JSONDecoder().decode(JenkinsJob.self, from: data)
      return .success(jobDetails)
    } catch let error as URLError {
      return .failure(.networkError(error))
    } catch {
      print("❌ [JenkinsAPIService] Decoding error: \(error)")
      return .failure(.decodingError(error))
    }
  }

  /// Fetch build history for a job (US-11)
  func fetchBuildHistory(
    url: String,
    username: String,
    password: String,
    paramToken: String? = nil
  ) async -> Result<[JenkinsBuild], JenkinsAPIError> {

    var normalizedURL = url
    if !normalizedURL.hasSuffix("/") {
      normalizedURL += "/"
    }

    // Fetch last 20 builds with details
    let historyTree =
      "builds[number,url,result,timestamp,duration,displayName,building,estimatedDuration]{0,20}"
    let urlString = "\(normalizedURL)api/json?tree=\(historyTree)"

    print("🔍 [JenkinsAPIService] Fetching build history at: \(urlString)")

    guard let apiURL = URL(string: urlString) else {
      return .failure(.invalidURL)
    }

    var request = URLRequest(url: apiURL)
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

      if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
        return .failure(.invalidCredentials)
      }

      if httpResponse.statusCode != 200 {
        return .failure(.serverError(httpResponse.statusCode))
      }

      // We decode it into a wrapper because the response is { builds: [...] }
      struct BuildsWrapper: Codable {
        let builds: [JenkinsBuild]?
      }

      let wrapper = try JSONDecoder().decode(BuildsWrapper.self, from: data)
      return .success(wrapper.builds ?? [])
    } catch let error as URLError {
      return .failure(.networkError(error))
    } catch {
      print("❌ [JenkinsAPIService] History decoding error: \(error)")
      return .failure(.decodingError(error))
    }
  }

  /// Fetch builds across ALL jobs on the server (Global History)
  func fetchGlobalBuildHistory(
    baseURL: String,
    username: String,
    password: String
  ) async -> Result<[GlobalBuild], JenkinsAPIError> {

    var normalizedURL = baseURL
    if !normalizedURL.hasSuffix("/") {
      normalizedURL += "/"
    }

    // Fetch builds for every job to construct a global history
    // We traverse folders up to 3 levels deep
    let buildFields = "number,url,result,timestamp,duration,displayName,building,estimatedDuration"
    let jobFields = "name,url,builds[\(buildFields)]{0,10}"
    let globalTree = "jobs[\(jobFields),jobs[\(jobFields),jobs[\(jobFields)]]]"
    let urlString = "\(normalizedURL)api/json?tree=\(globalTree)"

    print("🔍 [JenkinsAPIService] Fetching global history at: \(urlString)")

    guard let apiURL = URL(string: urlString) else {
      return .failure(.invalidURL)
    }

    var request = URLRequest(url: apiURL)
    let authString = "\(username):\(password)"
    if let authData = authString.data(using: .utf8) {
      let base64Auth = authData.base64EncodedString()
      request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
    }

    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        return .failure(.serverError((response as? HTTPURLResponse)?.statusCode ?? 500))
      }

      let serverInfo = try JSONDecoder().decode(JenkinsServerInfo.self, from: data)
      var allGlobalBuilds: [GlobalBuild] = []

      print(
        "📦 [JenkinsAPIService] Root serverInfo has \(serverInfo.jobs?.count ?? 0) top-level jobs")

      func collectBuilds(from jobs: [JenkinsJob]?, depth: Int = 0) {
        guard let jobs = jobs else { return }
        for job in jobs {
          let buildCount = job.builds?.count ?? 0
          if buildCount > 0 {
            print("  - [Depth \(depth)] Found \(buildCount) builds for job: \(job.name)")
            for build in job.builds ?? [] {
              allGlobalBuilds.append(GlobalBuild(jobName: job.name, build: build))
            }
          }
          // Recurse into sub-jobs (folders)
          if let subJobs = job.jobs, !subJobs.isEmpty {
            print("  - [Depth \(depth)] Entering folder: \(job.name) (\(subJobs.count) sub-jobs)")
            collectBuilds(from: subJobs, depth: depth + 1)
          }
        }
      }

      collectBuilds(from: serverInfo.jobs)

      print("📊 [JenkinsAPIService] Total global builds collected: \(allGlobalBuilds.count)")

      // Sort by timestamp descending
      let sortedBuilds = allGlobalBuilds.sorted {
        ($0.build.timestamp ?? 0) > ($1.build.timestamp ?? 0)
      }
      return .success(Array(sortedBuilds.prefix(50)))  // Return top 50

    } catch {
      print("❌ [JenkinsAPIService] Global history error: \(error)")
      return .failure(.decodingError(error))
    }
  }

  /// Normalizes a job URL by replacing its host with the current active base URL.
  /// This ensures that even if Jenkins returns absolute URLs with a different host (e.g. ngrok tunnel change),
  /// the app uses the URL specifically configured in Settings/AppStorage.
  func normalizeURL(jobURL: String, baseURL: String) -> String {
    guard let jobComponents = URLComponents(string: jobURL),
      let baseComponents = URLComponents(string: baseURL)
    else {
      return jobURL
    }

    var normalized = jobComponents
    normalized.scheme = baseComponents.scheme
    normalized.host = baseComponents.host
    normalized.port = baseComponents.port

    return normalized.string ?? jobURL
  }

  /// Trigger a Jenkins job build
  func triggerJob(
    job: JenkinsJob,
    username: String,
    password: String,
    paramToken: String? = nil,
    parameters: [String: String]? = nil
  ) async -> Result<Bool, JenkinsAPIError> {

    var endpoint = job.url
    if !endpoint.hasSuffix("/") {
      endpoint += "/"
    }

    // Determine correct endpoint: /build or /buildWithParameters
    // If we have parameters, we must use buildWithParameters
    let hasParams = !(parameters?.isEmpty ?? true)
    let buildAction = (job.isParameterized || hasParams) ? "buildWithParameters" : "build"
    let buildURLString = "\(endpoint)\(buildAction)"

    print("🚀 [JenkinsAPIService] Triggering \(buildAction) with params: \(parameters ?? [:])")

    guard var components = URLComponents(string: buildURLString) else {
      return .failure(.invalidURL)
    }

    // Add token if provided
    if let token = paramToken, !token.isEmpty {
      components.queryItems = [URLQueryItem(name: "token", value: token)]
    }

    guard let apiURL = components.url else {
      return .failure(.invalidURL)
    }

    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"

    // Authentication
    let authString = "\(username):\(password)"
    if let authData = authString.data(using: .utf8) {
      let base64Auth = authData.base64EncodedString()
      request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
    }

    // Parameters Encoding
    if let parameters = parameters, !parameters.isEmpty {
      request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

      let parameterString = parameters.map { key, value in
        let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
        let escapedValue =
          value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
        return "\(escapedKey)=\(escapedValue)"
      }.joined(separator: "&")

      request.httpBody = parameterString.data(using: .utf8)
    }

    do {
      let (_, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(.unknown)
      }

      print("✅ [JenkinsAPIService] Trigger response code: \(httpResponse.statusCode)")

      // Jenkins returns 201 Created for successful build triggering
      if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
        return .success(true)
      } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
        return .failure(.invalidCredentials)
      } else {
        return .failure(.serverError(httpResponse.statusCode))
      }
    } catch let error as URLError {
      print("❌ [JenkinsAPIService] Trigger URLError: \(error.localizedDescription)")
      return .failure(.networkError(error))
    } catch {
      print("❌ [JenkinsAPIService] Trigger Unexpected error: \(error.localizedDescription)")
      return .failure(.unknown)
    }
  }

  /// Cancel a running Jenkins job build
  func cancelBuild(
    jobURL: String,
    buildNumber: Int,
    username: String,
    password: String,
    paramToken: String? = nil
  ) async -> Result<Bool, JenkinsAPIError> {

    var endpoint = jobURL
    if !endpoint.hasSuffix("/") {
      endpoint += "/"
    }

    // Hit the /stop API for the running build
    let buildURLString = "\(endpoint)\(buildNumber)/stop"

    print("🚀 [JenkinsAPIService] Canceling build #\(buildNumber) at: \(buildURLString)")

    guard var components = URLComponents(string: buildURLString) else {
      return .failure(.invalidURL)
    }

    // Add token if provided
    if let token = paramToken, !token.isEmpty {
      components.queryItems = [URLQueryItem(name: "token", value: token)]
    }

    guard let apiURL = components.url else {
      return .failure(.invalidURL)
    }

    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"  // Jenkins exposes /stop as POST only

    // Authentication
    let authString = "\(username):\(password)"
    if let authData = authString.data(using: .utf8) {
      let base64Auth = authData.base64EncodedString()
      request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
    }

    do {
      let (_, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(.unknown)
      }

      print("✅ [JenkinsAPIService] Cancel response code: \(httpResponse.statusCode)")

      // Jenkins returns 302 Found (Redirect) or 200 OK after successfully stopping
      if [200, 201, 302].contains(httpResponse.statusCode) {
        return .success(true)
      } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
        return .failure(.invalidCredentials)
      } else {
        return .failure(.serverError(httpResponse.statusCode))
      }
    } catch let error as URLError {
      print("❌ [JenkinsAPIService] Cancel URLError: \(error.localizedDescription)")
      return .failure(.networkError(error))
    } catch {
      print("❌ [JenkinsAPIService] Cancel Unexpected error: \(error.localizedDescription)")
      return .failure(.unknown)
    }
  }

  /// Fetch build logs incrementally using Progressive Text API
  func fetchBuildLogs(
    buildURL: String,
    startOffset: Int = 0,
    username: String,
    password: String
  ) async -> Result<LogResponse, JenkinsAPIError> {

    var endpoint = buildURL
    if !endpoint.hasSuffix("/") {
      endpoint += "/"
    }

    let urlString = "\(endpoint)logText/progressiveText?start=\(startOffset)"

    guard let url = URL(string: urlString) else {
      return .failure(.invalidURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    // Authentication
    let authString = "\(username):\(password)"
    if let authData = authString.data(using: .utf8) {
      let base64Auth = authData.base64EncodedString()
      request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
    }

    print("📄 [JenkinsAPIService] Fetching build logs from: \(urlString)")

    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(.unknown)
      }

      print("📄 [JenkinsAPIService] Log response code: \(httpResponse.statusCode)")

      if httpResponse.statusCode != 200 {
        return .failure(.serverError(httpResponse.statusCode))
      }

      let logText = String(data: data, encoding: .utf8) ?? ""
      let nextOffsetStr = httpResponse.value(forHTTPHeaderField: "X-Text-Size") ?? "0"
      let hasMoreStr = httpResponse.value(forHTTPHeaderField: "X-More-Data") ?? "false"

      let nextOffset = Int(nextOffsetStr) ?? startOffset + data.count
      let hasMore = hasMoreStr.lowercased() == "true"

      return .success(
        LogResponse(
          text: logText,
          nextOffset: nextOffset,
          hasMoreData: hasMore
        ))

    } catch {
      return .failure(.networkError(error))
    }
  }
}
