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

  let jobs: [JenkinsJob]?
}

struct JenkinsJob: Codable, Identifiable, Hashable {
  let name: String
  var url: String
  let color: String?
  let description: String?
  var jobs: [JenkinsJob]?  // For folders
  let lastBuild: BuildSummary?
  let healthReport: [HealthReport]?
  let property: [JobProperty]?
  var builds: [JenkinsBuild]?  // History list

  var id: String { url }

  var isFolder: Bool {
    return jobs != nil
  }

  var isParameterized: Bool {
    return property?.contains(where: { $0.parameterDefinitions != nil }) ?? false
  }
}

struct BuildSummary: Codable, Hashable {
  let number: Int
  let url: String
  let result: String?
  let timestamp: Double?
  let duration: Double?
  let estimatedDuration: Double?
  let building: Bool?

  init(
    number: Int, url: String, result: String? = nil, timestamp: Double? = nil,
    duration: Double? = nil, estimatedDuration: Double? = nil, building: Bool? = nil
  ) {
    self.number = number
    self.url = url
    self.result = result
    self.timestamp = timestamp
    self.duration = duration
    self.estimatedDuration = estimatedDuration
    self.building = building
  }

  var progress: Double {
    guard let building = building, building,
      let timestamp = timestamp,
      let estimated = estimatedDuration, estimated > 0
    else {
      return 0
    }

    let now = Date().timeIntervalSince1970 * 1000
    let elapsed = now - timestamp
    return min(elapsed / estimated, 0.99)  // Cap at 99% until actually done
  }
}

struct JenkinsBuild: Codable, Identifiable, Hashable {
  let number: Int
  let url: String
  let result: String?  // SUCCESS, FAILURE, ABORTED, etc.
  let timestamp: Double?  // Epoch milliseconds
  let duration: Double?  // Milliseconds
  let estimatedDuration: Double?  // Milliseconds
  let building: Bool?
  let displayName: String?

  var id: Int { number }

  var progress: Double {
    guard let building = building, building,
      let timestamp = timestamp,
      let estimated = estimatedDuration, estimated > 0
    else {
      return 0
    }

    let now = Date().timeIntervalSince1970 * 1000
    let elapsed = now - timestamp
    return min(elapsed / estimated, 0.99)  // Cap at 99% until actually done
  }

  var statusColor: String {
    switch result?.uppercased() {
    case "SUCCESS": return "blue"
    case "FAILURE": return "red"
    case "ABORTED": return "grey"
    case "UNSTABLE": return "yellow"
    default: return "grey"
    }
  }
}

struct GlobalBuild: Codable, Hashable, Identifiable {
  let jobName: String
  let build: JenkinsBuild

  var id: String { "\(jobName)-\(build.number)" }
}

struct HealthReport: Codable, Hashable {
  let description: String
  let iconClassName: String
  let score: Int
}

struct JobProperty: Codable, Hashable {
  let parameterDefinitions: [ParameterDefinition]?
}

struct ParameterDefinition: Codable, Hashable {
  let name: String
  let type: String
  let description: String?
  let defaultParameterValue: ParameterValue?
  let choices: [String]?

  var defaultValue: String {
    if let value = defaultParameterValue?.value {
      switch value {
      case .string(let s): return s
      case .int(let i): return String(i)
      case .double(let d): return String(d)
      case .bool(let b): return String(b)
      default: return ""
      }
    }
    // For choice parameters, the first choice is often the default if not specified
    if let firstChoice = choices?.first {
      return firstChoice
    }
    return ""
  }
}

struct ParameterValue: Codable, Hashable {
  let value: JSONValue?
}

enum JSONValue: Codable, Hashable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case array([JSONValue])
  case object([String: JSONValue])
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let x = try? container.decode(String.self) {
      self = .string(x)
    } else if let x = try? container.decode(Int.self) {
      self = .int(x)
    } else if let x = try? container.decode(Double.self) {
      self = .double(x)
    } else if let x = try? container.decode(Bool.self) {
      self = .bool(x)
    } else if let x = try? container.decode([JSONValue].self) {
      self = .array(x)
    } else if let x = try? container.decode([String: JSONValue].self) {
      self = .object(x)
    } else {
      self = .null
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let x): try container.encode(x)
    case .int(let x): try container.encode(x)
    case .double(let x): try container.encode(x)
    case .bool(let x): try container.encode(x)
    case .array(let x): try container.encode(x)
    case .object(let x): try container.encode(x)
    case .null: try container.encodeNil()
    }
  }
}
