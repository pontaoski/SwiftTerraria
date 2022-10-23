import Foundation
import NIO
import NIOExtras
import Dispatch

final class PacketDecoder: ByteToMessageDecoder {
    typealias InboundOut = ClientToServerPacket

    private enum ReadState {
        case waitingForHeader
        case waitingForTag(length: Int)
        case waitingForFrame(length: Int, tag: UInt8)
    }
    private var readState: ReadState = .waitingForHeader
    var packetTypes: [UInt8: (Int, inout ByteBuffer) -> ClientToServerPacket?]

    init() {
        packetTypes = [
            Connect.type : Connect.init,
            PlayerInfo.type : PlayerInfo.init,
            ClientUUID.type : ClientUUID.init,
            PlayerHP.type : PlayerHP.init,
            PlayerMP.type : PlayerMP.init,
            UpdatePlayerBuff.type : UpdatePlayerBuff.init,
            PlayerInventorySlot.type : PlayerInventorySlot.init,
            RequestWorldData.type : RequestWorldData.init,
        ]
    }
    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        if case .waitingForHeader = self.readState {
            guard let len = buffer.readInteger(endianness: .little, as: UInt16.self) else {
                return .needMoreData
            }
            self.readState = .waitingForTag(length: Int(len))
        }
        if case .waitingForTag(let length) = self.readState {
            guard let tag = buffer.readInteger(endianness: .little, as: UInt8.self) else {
                return .needMoreData
            }
            self.readState = .waitingForFrame(length: length, tag: tag)
        }
        guard case .waitingForFrame(let length, let tag) = self.readState else {
            return .needMoreData
        }
        guard var contents = buffer.readSlice(length: length - HeaderSize) else {
            return .needMoreData
        }
        guard let kind = packetTypes[tag] else {
            self.readState = .waitingForHeader
            throw PacketError.UnsupportedPacketKind(kind: tag)
        }
        guard let packet = kind(length - HeaderSize, &contents) else {
            self.readState = .waitingForHeader
            throw PacketError.Failed
        }

        context.fireChannelRead(self.wrapInboundOut(packet))
        self.readState = .waitingForHeader

        return .continue
    }
}
