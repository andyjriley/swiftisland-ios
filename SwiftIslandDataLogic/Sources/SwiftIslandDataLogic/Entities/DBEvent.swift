//
// Created by Paul Peelen for the use in the Swift Island app
// Copyright © 2023 AppTrix AB. All rights reserved.
//

import Foundation

struct DateRange: Codable {
    let start: Date
    let end: Date?
    
    private enum CodingKeys: String, CodingKey {
        case start, end
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let startTimestamp = try container.decode(Int.self, forKey: .start)
        self.start = Date(timeIntervalSince1970: Double(startTimestamp))
        
        if let endTimestamp = try container.decodeIfPresent(Int.self, forKey: .end) {
            self.end = Date(timeIntervalSince1970: Double(endTimestamp))
        } else {
            self.end = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(start.timeIntervalSince1970), forKey: .start)
        if let end = end {
            try container.encode(Int(end.timeIntervalSince1970), forKey: .end)
        }
    }
}

internal struct DBEvent: Response {
    public let id: String
    public let activity: String
    public let startDate: DateRange

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.activity = try container.decode(String.self, forKey: .activity)
        self.startDate = try container.decode(DateRange.self, forKey: .startDate)
    }

    public init(id: String, activity: String, startDate: DateRange) {
        self.id = id
        self.activity = activity
        self.startDate = startDate
    }
}
