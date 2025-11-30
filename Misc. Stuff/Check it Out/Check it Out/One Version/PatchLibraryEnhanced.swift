import SwiftUI
import SwiftData
import UniformTypeIdentifiers








// Continue in next message due to length...
// MARK: - Transferable for Drag & Drop
import Foundation

    // A Sendable-friendly, Codable DTO for drag & drop payloads
struct PatchDTO: Codable, Sendable {
    var id: UUID
    var name: String
    var tagIDs: [UUID]
    var category: String
    var author: String
    var dateCreated: Date
    var dateModified: Date
    var notes: String
    var isFavorite: Bool
    var parameters: [String: Double]
}
    // MARK: - Transferable for Drag & Drop

//extension Patch: Transferable {
//    static var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: .json)
//    }
//}

extension Patch: Transferable {
    nonisolated static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .json) { (patch: Patch) throws -> Data in
            // Encode Patch -> PatchDTO -> JSON Data
            let dto = PatchDTO(
                id: patch.id,
                name: patch.name,
                tagIDs: patch.tags.map { $0.id },
                category: patch.category,
                author: patch.author,
                dateCreated: patch.dateCreated,
                dateModified: patch.dateModified,
                notes: patch.notes,
                isFavorite: patch.isFavorite,
                parameters: patch.parameters
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(dto)
        } importing: { data in
            // Decode JSON Data -> PatchDTO -> Patch (tags empty; reconcile later)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let dto = try decoder.decode(PatchDTO.self, from: data)
            return Patch(
                id: dto.id,
                name: dto.name,
                tags: [],
                category: dto.category,
                author: dto.author,
                dateCreated: dto.dateCreated,
                dateModified: dto.dateModified,
                notes: dto.notes,
                isFavorite: dto.isFavorite,
                parameters: dto.parameters
            )
        }
    }
}
