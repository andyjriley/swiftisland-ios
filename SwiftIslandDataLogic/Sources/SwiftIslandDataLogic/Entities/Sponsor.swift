//
//  File.swift
//  
//
//  Created by Niels van Hoorn on 2023-08-31.
//

import Foundation

public enum SponsorType: String, Decodable {
    case app = "App"
    case book = "Book"
}

public struct Sponsor: Decodable {
    public let name: String
    public let link: URL
    public let icon: [RemoteImage]
    public let type: SponsorType
    
    public var primaryImageUrl: String? {
        return icon.first?.url
    }
}

enum CodingKeys: String, CodingKey {
    case name, link, icon, type
}

extension Sponsor: Hashable, Identifiable {
    public var id: String {
        return name
    }
}

extension Sponsor {
    public static func forPreview(title: String = "", url: URL = URL(string: "http://example.com")!) -> Sponsor {
        Sponsor(
            name: title,
            link: url,
            icon: [RemoteImage.forPreview()],
            type: .app
        )
    }
}
