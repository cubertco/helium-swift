import XCTest
@testable import Helium

private final class AuthorizationPurchaseDelegate: HeliumPaywallDelegate {
    var purchases = 0
    func makePurchase(productId: String) async -> HeliumPaywallTransactionStatus {
        purchases += 1
        return .cancelled
    }
}

final class PurchaseAuthorizationTests: HeliumTestCase {
    override func tearDown() {
        Helium.config.purchaseAuthorization = nil
        super.tearDown()
    }

    private func purchase(_ key: String) async -> HeliumPaywallTransactionStatus {
        await HeliumPaywallDelegateWrapper.shared.handlePurchase(
            productKey: key, triggerName: "test", paywallTemplateName: "test",
            paywallSession: makeTestSession(trigger: "test")
        )
    }

    func testDeniedAuthorizationStopsAllPaymentProcessors() async {
        let delegate = AuthorizationPurchaseDelegate()
        Helium.config.purchaseDelegate = delegate
        var checks = 0
        Helium.config.purchaseAuthorization = { checks += 1; return false }
        for key in ["premium_monthly", "pro_test:pri_test", "prod_test:price_test"] {
            let result = await purchase(key)
            guard case .cancelled = result else { return XCTFail("Denied purchase must be cancelled") }
        }
        XCTAssertEqual(checks, 3)
        XCTAssertEqual(delegate.purchases, 0)
    }

    func testAllowedAuthorizationPreservesThePurchaseDelegate() async {
        let delegate = AuthorizationPurchaseDelegate()
        Helium.config.purchaseDelegate = delegate
        Helium.config.purchaseAuthorization = { true }
        _ = await purchase("premium_monthly")
        XCTAssertEqual(delegate.purchases, 1)
    }

    func testAbsentAuthorizationPreservesExistingBehavior() async {
        let delegate = AuthorizationPurchaseDelegate()
        Helium.config.purchaseDelegate = delegate
        Helium.config.purchaseAuthorization = nil
        _ = await purchase("premium_monthly")
        XCTAssertEqual(delegate.purchases, 1)
    }
}
