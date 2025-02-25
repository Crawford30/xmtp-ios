//
//  ClientTests.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation

import XCTest
@testable import XMTP
import XMTPRust
import XMTPTestHelpers

@available(iOS 15, *)
class ClientTests: XCTestCase {
	func testTakesAWallet() async throws {
	    try TestConfig.skip(because: "run manually against dev")
		let fakeWallet = try PrivateKey.generate()
		_ = try await Client.create(account: fakeWallet)
	}

	func testCanMessage() async throws {
		let fixtures = await fixtures()
		let notOnNetwork = try PrivateKey.generate()

		let canMessage = try await fixtures.aliceClient.canMessage(fixtures.bobClient.address)
		let cannotMessage = try await fixtures.aliceClient.canMessage(notOnNetwork.address)
		XCTAssertTrue(canMessage)
		XCTAssertFalse(cannotMessage)
	}

	func testHasPrivateKeyBundleV1() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet, apiClient: FakeApiClient())

		XCTAssertEqual(1, client.privateKeyBundleV1.preKeys.count)

		let preKey = client.privateKeyBundleV1.preKeys[0]

		XCTAssert(preKey.publicKey.hasSignature, "prekey not signed")
	}

	func testCanBeCreatedWithBundle() async throws {
        try TestConfig.skip(because: "run manually against dev")
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet)

		let bundle = client.privateKeyBundle
		let clientFromV1Bundle = try await Client.from(bundle: bundle)

		XCTAssertEqual(client.address, clientFromV1Bundle.address)
		XCTAssertEqual(client.privateKeyBundleV1.identityKey, clientFromV1Bundle.privateKeyBundleV1.identityKey)
		XCTAssertEqual(client.privateKeyBundleV1.preKeys, clientFromV1Bundle.privateKeyBundleV1.preKeys)
	}

	func testCanBeCreatedWithV1Bundle() async throws {
        try TestConfig.skip(because: "run manually against dev")
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet)

		let bundleV1 = client.v1keys
		let clientFromV1Bundle = try await Client.from(v1Bundle: bundleV1)

		XCTAssertEqual(client.address, clientFromV1Bundle.address)
		XCTAssertEqual(client.privateKeyBundleV1.identityKey, clientFromV1Bundle.privateKeyBundleV1.identityKey)
		XCTAssertEqual(client.privateKeyBundleV1.preKeys, clientFromV1Bundle.privateKeyBundleV1.preKeys)
	}

	func testCanAccessPublicKeyBundle() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet)

		let publicKeyBundle = client.keys.getPublicKeyBundle()
		XCTAssertEqual(publicKeyBundle, client.publicKeyBundle)
	}

	func testCanSignWithPrivateIdentityKey() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet)

		let digest = Util.keccak256(Data("hello world".utf8))
		let signature = try await client.keys.identityKey.sign(digest)

		let recovered = try KeyUtilx.recoverPublicKeyKeccak256(from: signature.rawData, message: Data("hello world".utf8))

		XCTAssertEqual(recovered, client.keys.identityKey.publicKey.secp256K1Uncompressed.bytes)
	}
}
