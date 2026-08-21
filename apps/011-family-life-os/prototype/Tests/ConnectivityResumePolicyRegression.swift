import Foundation

@main
struct ConnectivityResumePolicyRegression {
    static func main() {
        var policy = ConnectivityResumePolicy()

        precondition(
            !policy.shouldResumeSync(isNetworkAvailable: true),
            "initial online state must not trigger a duplicate startup sync"
        )
        precondition(
            !policy.shouldResumeSync(isNetworkAvailable: true),
            "repeated online updates must not trigger sync"
        )
        precondition(
            !policy.shouldResumeSync(isNetworkAvailable: false),
            "going offline must not trigger sync"
        )
        precondition(
            policy.shouldResumeSync(isNetworkAvailable: true),
            "offline to online must trigger exactly one resume"
        )
        precondition(
            !policy.shouldResumeSync(isNetworkAvailable: true),
            "remaining online after a resume must not trigger again"
        )
        precondition(
            !policy.shouldResumeSync(isNetworkAvailable: false),
            "a second offline transition must remain passive"
        )
        precondition(
            policy.shouldResumeSync(isNetworkAvailable: true),
            "a later offline to online transition must resume again"
        )

        var initiallyOffline = ConnectivityResumePolicy()
        precondition(
            !initiallyOffline.shouldResumeSync(isNetworkAvailable: false),
            "initial offline observation must only establish state"
        )
        precondition(
            initiallyOffline.shouldResumeSync(isNetworkAvailable: true),
            "first reachable state after an offline launch must resume the queue"
        )

        print("Connectivity resume policy regression passed")
    }
}
