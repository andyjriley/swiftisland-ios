//
// Created by Claude for the use in the Swift Island app
// Copyright © 2025 AppTrix AB. All rights reserved.
//

import Foundation

public struct RemoteImage: Codable {
    public let url: String
    public let name: String
    public let type: String
    public let originalUrl: String?
    public let urlExpiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case url
        case name
        case type
        case originalUrl = "original_url"
        case urlExpiresAt = "url_expires_at"
    }
    
    public init(url: String, name: String, type: String, originalUrl: String? = nil, urlExpiresAt: String? = nil) {
        self.url = url
        self.name = name
        self.type = type
        self.originalUrl = originalUrl
        self.urlExpiresAt = urlExpiresAt
    }
}

extension RemoteImage: Identifiable, Hashable {
    public var id: String { url }
}

extension RemoteImage {
    public static func forPreview(
        url: String = "images/preview_image.jpg",
        name: String = "Preview Image",
        type: String = "file",
        originalUrl: String? = nil,
        urlExpiresAt: String? = nil
    ) -> RemoteImage {
        RemoteImage(
            url: url,
            name: name,
            type: type,
            originalUrl: originalUrl,
            urlExpiresAt: urlExpiresAt
        )
    }
}