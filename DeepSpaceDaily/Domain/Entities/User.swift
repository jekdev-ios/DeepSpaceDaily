//
//  User.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import JWTDecode

struct User {
    let id: String?
    let name: String
    let email: String?
    let emailVerified: String?
    let picture: URL?
    let updatedAt: String?
    
    static let guest = User(id: "guest", name: "Guest", email: nil, emailVerified: nil, picture: nil, updatedAt: nil)
}

extension User {
    init?(from idToken: String) {
        guard let jwt = try? decode(jwt: idToken),
              let id = jwt.subject,
              let name = jwt["name"].string,
              let email = jwt["email"].string,
              let emailVerified = jwt["email_verified"].boolean,
              let picture = jwt["picture"].string,
              let updatedAt = jwt["updated_at"].string else {
            return nil
        }
        self.id = id
        self.name = name
        self.email = email
        self.emailVerified = String(describing: emailVerified)
        self.picture = URL(string: picture)
        self.updatedAt = updatedAt
    }
}

// MARK: - User Extension for Codable

extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, email, emailVerified, picture, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        emailVerified = try container.decodeIfPresent(String.self, forKey: .emailVerified)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        if let pictureString = try container.decodeIfPresent(String.self, forKey: .picture) {
            picture = URL(string: pictureString)
        } else {
            picture = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(emailVerified, forKey: .emailVerified)
        try container.encodeIfPresent(picture?.absoluteString, forKey: .picture)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
} 