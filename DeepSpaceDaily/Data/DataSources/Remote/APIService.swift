//
//  APIService.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine
import CommonCrypto

// Remove the duplicate enum definition and use the one from SSLConfigurationManager
// enum SSLValidationMode {
//     /// Strict validation with certificate pinning
//     case strict
//     
//     /// Standard validation using system trust store
//     case standard
//     
//     /// No validation (insecure, use only for development/testing)
//     case disabled
// }

enum APIError: Error {
    case invalidURL
    case requestFailed(URLError)
    case invalidResponse
    case serverError(Int)
    case decodingFailed(Error)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

/// A cached API response with timestamp
class CachedResponse {
    let data: Data
    let timestamp: Date
    
    init(data: Data, timestamp: Date = Date()) {
        self.data = data
        self.timestamp = timestamp
    }
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 300 // 5 minutes TTL
    }
}

class APIService: NSObject, URLSessionDelegate {
    private let baseURL = "https://api.spaceflightnewsapi.net/v4"
    private var session: URLSession
    private let jsonDecoder = JSONDecoder()
    
    // API call counter
    private static var apiCallCount = 0
    
    // Cache for API responses
    private var responseCache: [String: (data: Data, timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutes cache TTL
    
    // Batch request management
    private var pendingBatchRequests: [String: [((Data?, URLResponse?, Error?) -> Void)]] = [:]
    private var batchRequestTimer: Timer?
    private let batchRequestDelay: TimeInterval = 0.1 // 100ms delay for batching
    
    // SSL validation mode - use a string to avoid the enum conflict
    private var sslValidationModeString: String = "strict"
    
    var sslValidationMode: SSLValidationMode {
        get {
            return SSLValidationMode(rawValue: sslValidationModeString) ?? .strict
        }
        set {
            sslValidationModeString = newValue.rawValue
        }
    }
    
    // Method to get the current API call count
    static func getAPICallCount() -> Int {
        return apiCallCount
    }
    
    // Method to reset the API call counter
    static func resetAPICallCount() {
        apiCallCount = 0
        print("🔄 API call counter has been reset")
    }

    override init() {
        // Initialize with strict SSL validation by default
        self.sslValidationModeString = "strict"
        
        // Initialize session with a default value
        self.session = URLSession.shared
        
        // Create self before initializing session with self as delegate
        super.init()
        
        // Now initialize session with self as delegate
        self.session = URLSession(configuration: Self.setupSessionConfiguration(), delegate: self, delegateQueue: nil)
    }
    
    /// Initialize with specific SSL validation mode
    /// - Parameter sslValidationMode: The SSL validation mode to use
    init(sslValidationMode: SSLValidationMode) {
        self.sslValidationModeString = sslValidationMode.rawValue
        
        // Initialize session with a default value
        self.session = URLSession.shared
        
        super.init()
        
        // Configure session based on SSL validation mode
        let configuration = Self.setupSessionConfiguration()
        
        if sslValidationMode == .disabled {
            // For no validation, allow insecure connections
            print("⚠️ WARNING: SSL validation disabled. This is insecure and should only be used for development/testing.")
        }
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    /// Set the SSL validation mode
    /// - Parameter mode: The SSL validation mode to use
    func setSSLValidationMode(_ mode: SSLValidationMode) {
        if mode == .disabled {
            print("⚠️ WARNING: Setting SSL validation to DISABLED. This is insecure and should only be used for development/testing.")
        }
        
        self.sslValidationModeString = mode.rawValue
        
        // Recreate the session with the new validation mode
        let configuration = Self.setupSessionConfiguration()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    // Update SSL validation mode - alias for setSSLValidationMode for consistency with our implementation
    func updateSSLValidationMode(_ mode: SSLValidationMode) {
        setSSLValidationMode(mode)
    }
    
    deinit {
        batchRequestTimer?.invalidate()
    }
    
    /// Fetches data from the given API endpoint and decodes it into the specified type.
    /// - Parameters:
    ///   - endpoint: The API endpoint to request.
    ///   - parameters: Query parameters for the request.
    ///   - callerIdentifier: Identifier for debugging to track which function is calling (default: "Unknown")
    /// - Returns: A publisher that emits the decoded response or an APIError.
    func fetch<T: Decodable>(endpoint: String, parameters: [String: Any] = [:], callerIdentifier: String = "Unknown") -> AnyPublisher<T, APIError> {
        guard let url = constructURL(for: endpoint, with: parameters) else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
        
        // Create a cache key from the URL
        let cacheKey = url.absoluteString
        
        // Check if we have a valid cached response
        if let cachedResponse = responseCache[cacheKey], 
           Date().timeIntervalSince(cachedResponse.timestamp) < cacheTTL {
            print("🔄 Using cached response for: \(cacheKey)")
            print("📱 Called by: \(callerIdentifier)")
            
            return Just(cachedResponse.data)
                .tryMap { data -> T in
                    do {
                        let decoded = try self.jsonDecoder.decode(T.self, from: data)
                        return decoded
                    } catch {
                        throw APIError.decodingFailed(error)
                    }
                }
                .mapError { error -> APIError in
                    if let apiError = error as? APIError {
                        return apiError
                    }
                    return APIError.unknown
                }
                .eraseToAnyPublisher()
        }
        
        // Increment the API call counter
        APIService.apiCallCount += 1
        
        // Print the current count with caller identifier
        print("🌐 API Call #\(APIService.apiCallCount): \(endpoint) - Parameters: \(parameters)")
        print("📱 Called by: \(callerIdentifier)")
        
        // Use batch request for GET requests
        if shouldBatchRequest(for: url) {
            return batchRequest(url: url)
                .tryMap { data, response -> T in
                    // Cache the successful response
                    self.responseCache[cacheKey] = (data: data, timestamp: Date())
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw APIError.serverError(httpResponse.statusCode)
                    }
                    
                    do {
                        let decoded = try self.jsonDecoder.decode(T.self, from: data)
                        return decoded
                    } catch {
                        throw APIError.decodingFailed(error)
                    }
                }
                .mapError { error -> APIError in
                    if let apiError = error as? APIError {
                        return apiError
                    }
                    if let urlError = error as? URLError {
                        return APIError.requestFailed(urlError)
                    }
                    return APIError.unknown
                }
                .handleEvents(receiveOutput: { _ in
                    print("✅ API Call #\(APIService.apiCallCount) completed successfully")
                }, receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("❌ API Call #\(APIService.apiCallCount) failed with error: \(error)")
                    }
                })
                .eraseToAnyPublisher()
        }
        
        // For non-batchable requests, use the standard approach
        return session.dataTaskPublisher(for: url)
            .mapError { APIError.requestFailed($0) }
            .handleEvents(receiveOutput: { data, response in
                // Cache the successful response
                self.responseCache[cacheKey] = (data: data, timestamp: Date())
            })
            .flatMap(handleResponse)
            .handleEvents(receiveOutput: { _ in
                print("✅ API Call #\(APIService.apiCallCount) completed successfully")
            }, receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("❌ API Call #\(APIService.apiCallCount) failed with error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }

    /// Constructs a URL with query parameters.
    private func constructURL(for endpoint: String, with parameters: [String: Any]) -> URL? {
        guard var components = URLComponents(string: baseURL + endpoint) else { return nil }
        if !parameters.isEmpty {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        return components.url
    }

    /// Handles the response, validating and decoding the data.
    private func handleResponse<T: Decodable>(data: Data, response: URLResponse) -> AnyPublisher<T, APIError> {
        guard let httpResponse = response as? HTTPURLResponse else {
            return Fail(error: .invalidResponse).eraseToAnyPublisher()
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            return Fail(error: .serverError(httpResponse.statusCode)).eraseToAnyPublisher()
        }
        
        return Just(data)
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError { APIError.decodingFailed($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Request Batching
    
    /// Determines if a request should be batched
    private func shouldBatchRequest(for url: URL) -> Bool {
        // Only batch GET requests
        return url.absoluteString.contains("/articles") || 
               url.absoluteString.contains("/blogs") || 
               url.absoluteString.contains("/reports")
    }
    
    /// Performs a batch request
    private func batchRequest(url: URL) -> AnyPublisher<(Data, URLResponse), Error> {
        let urlString = url.absoluteString
        
        return Future<(Data, URLResponse), Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(APIError.unknown))
                return
            }
            
            // Add this request to pending batch
            if self.pendingBatchRequests[urlString] == nil {
                self.pendingBatchRequests[urlString] = []
                
                // Schedule the actual request
                self.scheduleBatchRequest(for: urlString)
            }
            
            // Add this promise to the list of callbacks
            self.pendingBatchRequests[urlString]?.append { (data, response, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let data = data, let response = response {
                    promise(.success((data, response)))
                } else {
                    promise(.failure(APIError.unknown))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Schedules a batch request to be executed after a short delay
    private func scheduleBatchRequest(for urlString: String) {
        // Cancel existing timer if any
        batchRequestTimer?.invalidate()
        
        // Create a new timer
        batchRequestTimer = Timer.scheduledTimer(withTimeInterval: batchRequestDelay, repeats: false) { [weak self] _ in
            self?.executePendingBatchRequests()
        }
    }
    
    /// Executes all pending batch requests
    private func executePendingBatchRequests() {
        // Make a copy of pending requests
        let requestsToExecute = pendingBatchRequests
        pendingBatchRequests.removeAll()
        
        // Execute each batch
        for (urlString, callbacks) in requestsToExecute {
            guard let url = URL(string: urlString), !callbacks.isEmpty else { continue }
            
            print("🔄 Executing batch request with \(callbacks.count) callbacks: \(urlString)")
            
            let task = session.dataTask(with: url) { data, response, error in
                // Notify all callbacks with the result
                for callback in callbacks {
                    callback(data, response, error)
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached responses
    func clearCache() {
        responseCache.removeAll()
        print("🧹 API response cache cleared")
    }
    
    /// Clears cached responses for a specific endpoint
    func clearCache(for endpoint: String) {
        let keysToRemove = responseCache.keys.filter { $0.contains(endpoint) }
        keysToRemove.forEach { responseCache.removeValue(forKey: $0) }
        print("🧹 API response cache cleared for endpoint: \(endpoint)")
    }
    
    // MARK: - URLSessionDelegate for SSL Pinning
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Handle SSL validation based on the current mode
        switch sslValidationModeString {
        case "strict":
            // Strict mode: Use certificate pinning
            handleStrictSSLValidation(challenge, completionHandler: completionHandler)
            
        case "standard":
            // Standard mode: Use system trust evaluation
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            
        case "disabled":
            // Disabled mode: Accept any certificate (INSECURE)
            #if DEBUG
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.useCredential, nil)
            }
            #else
            // In production builds, fall back to standard mode for safety
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            #endif
            
        default:
            // Default to standard mode
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
    
    private func handleStrictSSLValidation(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get certificate data
        if let certificateData = loadPinnedCertificateData() {
            // Create certificate from data
            if let pinnedCertificate = SecCertificateCreateWithData(nil, certificateData as CFData) {
                // Set the pinned certificate as the only trusted certificate
                SecTrustSetAnchorCertificates(serverTrust, [pinnedCertificate] as CFArray)
                SecTrustSetAnchorCertificatesOnly(serverTrust, true)
                
                // Evaluate the trust
                var result: SecTrustResultType = .invalid
                SecTrustEvaluate(serverTrust, &result)
                
                // Check if the certificate is trusted
                if result == .proceed || result == .unspecified {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }
        
        // If we get here, validation failed
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    private func loadPinnedCertificateData() -> Data? {
        if let certificatePath = Bundle.main.path(forResource: "spaceflightnewsapi.net", ofType: "pem", inDirectory: "Resources/Certificates") {
            do {
                let certificateData = try Data(contentsOf: URL(fileURLWithPath: certificatePath))
                return certificateData
            } catch {
                print("Error loading certificate: \(error)")
                return nil
            }
        }
        return nil
    }
}

// MARK: - SSL Pinning & Session Configuration
extension APIService {
    private static func setupSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        return configuration
    }
    
    private func validateServerTrust(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        print("🔍 SSL Pinning: Validating certificate for \(host)")
        
        // Get the pinned certificate from the bundle
        guard let pinnedCertificateURL = Bundle.main.url(forResource: "spaceflightnewsapi.net", withExtension: "pem"),
              let pinnedCertificateData = try? Data(contentsOf: pinnedCertificateURL) else {
            print("❌ Failed to load pinned certificate")
            return false
        }
        
        print("📄 SSL Pinning: Loaded certificate from bundle: \(pinnedCertificateURL.lastPathComponent)")
        
        // Create a SecCertificate from the pinned certificate data
        guard let pinnedCertificate = SecCertificateCreateWithData(nil, pinnedCertificateData as CFData) else {
            print("❌ Failed to create SecCertificate from data")
            return false
        }
        
        print("🔐 SSL Pinning: Created SecCertificate from data")
        
        // Set the pinned certificate as the only trusted certificate
        SecTrustSetAnchorCertificates(serverTrust, [pinnedCertificate] as CFArray)
        SecTrustSetAnchorCertificatesOnly(serverTrust, true)
        
        // Evaluate the trust
        var error: CFError?
        let result = SecTrustEvaluateWithError(serverTrust, &error)
        
        if let error = error {
            print("❌ Trust evaluation failed: \(error)")
        }
        
        // Check if the trust is successful
        print(result ? "✅ SSL Pinning: Trust evaluation succeeded" : "❌ SSL Pinning: Trust evaluation failed")
        return result
    }
    
    // Alternative method using public key hash validation
    private func validateUsingPublicKeyHash(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        // The hash we extracted earlier
        let pinnedPublicKeyHash = "0QaROX1BpIov5Vvv71S5HQ/DKRT6wvQ1ez/kwSsj/sA="
        
        // Get the server's certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let serverCertificate = certificateChain.first else {
            return false
        }
        
        // Get the public key from the certificate
        var publicKey: SecKey?
        let policy = SecPolicyCreateBasicX509()
        var tempTrust: SecTrust?
        SecTrustCreateWithCertificates(serverCertificate, policy, &tempTrust)
        
        if let serverTrust = tempTrust {
            publicKey = SecTrustCopyKey(serverTrust)
        }
        
        guard let serverPublicKey = publicKey else {
            return false
        }
        
        // Get the public key data
        let publicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data?
        
        guard let keyData = publicKeyData else {
            return false
        }
        
        // Hash the public key
        let serverPublicKeyHash = keyData.sha256().base64EncodedString()
        
        // Compare with our pinned hash
        return serverPublicKeyHash == pinnedPublicKeyHash
    }
}

// Extension to compute SHA-256 hash
extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}
