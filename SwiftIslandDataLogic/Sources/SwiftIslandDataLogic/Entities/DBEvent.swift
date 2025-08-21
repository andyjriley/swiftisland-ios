//
// Created by Paul Peelen for the use in the Swift Island app
// Copyright © 2023 AppTrix AB. All rights reserved.
//

import Foundation

internal struct DBEvent: Response {
    public let id: String
    public let activity: String
    public let startDate: Date

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.activity = try container.decode(String.self, forKey: .activity)

        let timeInterval = try container.decode(Int.self, forKey: .startDate)
        let date = Date(timeIntervalSince1970: Double(timeInterval))
        self.startDate = date
    }

    public init(id: String, activity: String, startDate: Date) {
        self.id = id
        self.activity = activity
        self.startDate = startDate
    }
}
