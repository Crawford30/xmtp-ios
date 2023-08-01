//
//  ReplyCodec.swift
//
//
//  Created by Naomi Plasterer on 7/26/23.
//

import Foundation

public let ContentTypeReply = ContentTypeID(authorityID: "xmtp.org", typeID: "reply", versionMajor: 1, versionMinor: 0)

public struct Reply {
	public var reference: String
	public var content: Any
	public var contentType: ContentTypeID
}

public struct ReplyCodec: ContentCodec {
	public var contentType = ContentTypeReply

	public init() {}

	public func encode(content reply: Reply) throws -> EncodedContent {
		var encodedContent = EncodedContent()
		let replyCodec = Client.codecRegistry.find(for: reply.contentType)

		encodedContent.type = contentType
		encodedContent.parameters["contentType"] = reply.contentType.description
		encodedContent.parameters["reference"] = reply.reference
		encodedContent.content = try encodeReply(codec: replyCodec, content: reply.content).serializedData()

		return encodedContent
	}

	public func decode(content: EncodedContent) throws -> Reply {
		guard let contentTypeString = content.parameters["contentType"] else {
			throw CodecError.codecNotFound
		}

		guard let reference = content.parameters["reference"] else {
			throw CodecError.invalidContent
		}

		let replyEncodedContent = try EncodedContent(serializedData: content.content)
		let replyCodec = Client.codecRegistry.find(for: contentTypeString)
		let replyContent = try replyCodec.decode(content: replyEncodedContent)

		return Reply(
			reference: reference,
			content: replyContent,
			contentType: replyCodec.contentType
		)
	}

	func encodeReply<Codec: ContentCodec>(codec: Codec, content: Any) throws -> EncodedContent {
		if let content = content as? Codec.T {
			return try codec.encode(content: content)
		} else {
			throw CodecError.invalidContent
		}
	}
}
