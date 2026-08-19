import Foundation
import Supabase

enum SupabaseEnvironment {
    // This is a client-side publishable key by design. Privileged/service-role
    // credentials never belong in the app bundle.
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://bqctetqraszsvknczjjr.supabase.co")!,
        supabaseKey: "sb_publishable_g4PeQGT99Tz2ltwdAzyXrA_NoYDXsP9"
    )

    static let authRedirectURL = URL(string: "de.kamilunavo.familyprototype://login-callback")!
}
