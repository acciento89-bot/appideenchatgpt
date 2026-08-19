import Foundation
import Supabase

actor FamilyRealtimeSyncService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseEnvironment.client) {
        self.client = client
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                let channel = client.channel("family-v1-\(UUID().uuidString)")
                let stream = channel.postgresChange(AnyAction.self, schema: "public")
                await channel.subscribe()

                var lastYield = Date.distantPast
                for await _ in stream {
                    guard !Task.isCancelled else { break }
                    // Coalesce bursts from one logical transaction so the client
                    // refreshes authoritative state once instead of per table row.
                    let now = Date()
                    if now.timeIntervalSince(lastYield) > 0.35 {
                        continuation.yield(())
                        lastYield = now
                    }
                }

                await client.removeChannel(channel)
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
