import Foundation
import CloudKit
import PikaCore

/// Thin wrapper around `CKContainer` private DB for syncing `Pet` records.
/// SwiftData's native CloudKit integration handles most of this when the
/// `ModelContainer` is configured with a CloudKit container identifier; this
/// coordinator exists for custom records that don't map cleanly to SwiftData
/// models (e.g., cross-device notification tokens, seasonal event opt-ins).
public final class CloudKitSyncCoordinator: Sendable {

    public enum SyncError: Error, Sendable {
        case accountNotAvailable
        case networkError(String)
        case conflict(CKRecord)
    }

    private let container: CKContainer
    private let database: CKDatabase

    public init(containerIdentifier: String = "iCloud.com.pikapika.app") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    public func accountAvailable() async throws -> Bool {
        let status = try await container.accountStatus()
        return status == .available
    }

    /// Upload a pet record (last-writer-wins on `updatedAt`).
    public func upload(pet: Pet) async throws {
        let id = CKRecord.ID(recordName: pet.id.uuidString)
        let record = CKRecord(recordType: "Pet", recordID: id)
        record["name"]                    = pet.name as CKRecordValue
        record["species"]                 = pet.species as CKRecordValue
        record["bondXP"]                  = pet.bondXP as CKRecordValue
        record["bondLevel"]               = pet.bondLevel as CKRecordValue
        record["personalityTraits"]       = pet.personalityTraits as CKRecordValue
        record["lastInteractedAt"]        = pet.lastInteractedAt as CKRecordValue
        record["streakCount"]             = pet.streakCount as CKRecordValue
        record["longestStreak"]           = pet.longestStreak as CKRecordValue
        record["totalWorkSessionMinutes"] = pet.totalWorkSessionMinutes as CKRecordValue

        do {
            _ = try await database.save(record)
        } catch let err as CKError where err.code == .serverRecordChanged {
            if let server = err.serverRecord {
                throw SyncError.conflict(server)
            }
            throw SyncError.networkError(err.localizedDescription)
        }
    }

    /// Fetch all pet records for the signed-in iCloud user.
    public func fetchAllPets() async throws -> [CKRecord] {
        let query = CKQuery(recordType: "Pet", predicate: NSPredicate(value: true))
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { try? $0.1.get() }
    }
}
