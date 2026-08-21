import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
enum FamilyProPolicyRegression {
    static func main() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let future = now.addingTimeInterval(3_600)
        let past = now.addingTimeInterval(-3_600)

        expect(
            FamilyProPolicy.productIDs == [
                "de.kamilunavo.family.familypro.monthly",
                "de.kamilunavo.family.familypro.annual"
            ],
            "Family Pro product IDs changed unexpectedly"
        )
        expect(
            FamilyProPolicy.productRank(FamilyProPolicy.monthlyID) < FamilyProPolicy.productRank(FamilyProPolicy.annualID),
            "monthly should sort before annual"
        )
        expect(
            FamilyProPolicy.isEntitled(
                productID: FamilyProPolicy.monthlyID,
                revocationDate: nil,
                expirationDate: future,
                now: now
            ),
            "active monthly entitlement rejected"
        )
        expect(
            FamilyProPolicy.isEntitled(
                productID: FamilyProPolicy.annualID,
                revocationDate: nil,
                expirationDate: future,
                now: now
            ),
            "active annual entitlement rejected"
        )
        expect(
            !FamilyProPolicy.isEntitled(
                productID: FamilyProPolicy.monthlyID,
                revocationDate: now,
                expirationDate: future,
                now: now
            ),
            "revoked entitlement accepted"
        )
        expect(
            !FamilyProPolicy.isEntitled(
                productID: FamilyProPolicy.annualID,
                revocationDate: nil,
                expirationDate: past,
                now: now
            ),
            "expired entitlement accepted"
        )
        expect(
            !FamilyProPolicy.isEntitled(
                productID: "de.kamilunavo.family.unknown",
                revocationDate: nil,
                expirationDate: future,
                now: now
            ),
            "unknown product accepted"
        )
        expect(
            FamilyProPolicy.isEntitled(
                productID: FamilyProPolicy.monthlyID,
                revocationDate: nil,
                expirationDate: nil,
                now: now
            ),
            "recognized non-expiring entitlement rejected"
        )

        print("Family Pro policy regression: PASS")
    }
}
