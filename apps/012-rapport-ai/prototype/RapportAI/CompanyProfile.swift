import Foundation
import PhotosUI
import SwiftUI

struct CompanyProfile: Codable, Equatable {
    var companyName = ""
    var ownerName = ""
    var address = ""
    var phone = ""
    var email = ""
    var logoData: Data?

    var hasIdentity: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@MainActor
final class CompanyProfileStore: ObservableObject {
    @Published var profile: CompanyProfile {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private let key = "rapport.company.profile.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode(CompanyProfile.self, from: data) {
            profile = saved
        } else {
            profile = CompanyProfile()
        }
    }

    func importLogo(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self), data.count <= 8_000_000 else { return }
        profile.logoData = data
    }

    func removeLogo() {
        profile.logoData = nil
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: key)
        }
    }
}

