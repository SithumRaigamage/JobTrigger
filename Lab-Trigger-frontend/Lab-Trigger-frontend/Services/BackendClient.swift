import Foundation

/// Configuration for backend API endpoints
enum APIConfig {
  static let rootURL = URL(string: "http://127.0.0.1:5001")!
  static let baseURL = rootURL.appendingPathComponent("api")

  enum Auth {
    static let signup = baseURL.appendingPathComponent("auth/signup")
    static let login = baseURL.appendingPathComponent("auth/login")
  }

  enum Credentials {
    static let base = baseURL.appendingPathComponent("credentials")
    static func forId(_ id: String) -> URL {
      return base.appendingPathComponent(id)
    }
  }

  static let appInfo = baseURL.appendingPathComponent("appinfo")
}

/// Base client for communicating with the Node.js backend
final class BackendClient {
  static let shared = BackendClient()

  private let session = URLSession.shared
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  private init() {}

  /// Sends a request to the backend and decodes the response
  func request<T: Decodable>(
    _ url: URL,
    method: String = "GET",
    body: Data? = nil,
    requiresAuth: Bool = true
  ) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body

    // Inject JWT if required
    if requiresAuth {
      if let token = KeychainHelper.shared.retrieve(for: "jwt_token") {
        request.setValue(token, forHTTPHeaderField: "x-auth-token")
      }
    }

    print("🔍 [BackendClient] Request: \(method) \(url.absoluteString)")
    if requiresAuth {
      print("🔍 [BackendClient] Request requires auth")
    }

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      print("❌ [BackendClient] Failed to cast response")
      throw BackendError.invalidResponse
    }

    print("✅ [BackendClient] Response Status: \(httpResponse.statusCode)")

    if !(200...299).contains(httpResponse.statusCode) {
      // Try to parse error message from backend
      let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
      let msg = errorResponse?.message ?? "Request failed with status \(httpResponse.statusCode)"
      print("❌ [BackendClient] API Error: \(msg)")
      throw BackendError.apiError(message: msg)
    }

    return try decoder.decode(T.self, from: data)
  }
}

// MARK: - Models & Errors

struct ErrorResponse: Decodable {
  let message: String
}

struct EmptyResponse: Decodable {}

enum BackendError: LocalizedError {
  case invalidResponse
  case apiError(message: String)

  var errorDescription: String? {
    switch self {
    case .invalidResponse: return "Received an invalid response from the server."
    case .apiError(let message): return message
    }
  }
}
