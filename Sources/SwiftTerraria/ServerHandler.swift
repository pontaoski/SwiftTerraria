import Foundation
import NIO
import NIOExtras
import Dispatch

final class ServerHandler: ChannelInboundHandler {
    typealias InboundIn = ClientToServerPacket
    typealias InboundOut = ByteBuffer

    private let channelsSyncQueue = DispatchQueue(label: "handlesSyncQueue")
    private var slots: [UInt8: Channel] = [:]
    private var channelsToSlots: [ObjectIdentifier: UInt8] = [:]
    private var handlers: [UInt8: (ChannelHandlerContext, ClientToServerPacket) -> Void]

    init() {
        func handler<T: ClientToServerPacket>(
            from method: @escaping (ChannelHandlerContext, T) -> Void
        ) -> ((ChannelHandlerContext, ClientToServerPacket) -> Void) {
            return { ctx, pack in
                method(ctx, pack as! T)
            }
        }
        handlers = [:]
        handlers = [
            Connect.type : handler(from: self.handleConnect),
            PlayerInfo.type : handler(from: self.handlePlayerInfo),
            ClientUUID.type : handler(from: self.handleClientUUID),
            PlayerHP.type : handler(from: self.handlePlayerHP),
            PlayerMP.type : handler(from: self.handlePlayerMP),
            UpdatePlayerBuff.type : handler(from: self.handleUpdatePlayerBuff),
            PlayerInventorySlot.type : handler(from: self.handlePlayerInventorySlot),
            RequestWorldData.type : handler(from: self.handleRequestWorldData),
        ]
    }
    public func channelActive(context: ChannelHandlerContext) {
        print("new connection!")
    }
    
    public func channelInactive(context: ChannelHandlerContext) {
        print("dead connection!")

        let channel = context.channel
        let id = ObjectIdentifier(channel)
        guard let slot = channelsToSlots[id] else {
            return
        }
        self.channelsSyncQueue.async {
            self.slots.removeValue(forKey: slot)
            self.channelsToSlots.removeValue(forKey: id)
        }
    }

    public func handleConnect(context: ChannelHandlerContext, _ connect: Connect) {
        let channel = context.channel
        self.channelsSyncQueue.async {
            for i in 0...255 {
                if self.slots.keys.contains(UInt8(i)) {
                    continue
                }

                self.slots[UInt8(i)] = channel
                self.channelsToSlots[ObjectIdentifier(channel)] = UInt8(i)
                channel.send(packet: SetUserSlot(slot: UInt8(i)))
            }
        }
    }

    public func handlePlayerInfo(context: ChannelHandlerContext, _ playerInfo: PlayerInfo) {
        print("they're called \(playerInfo)")
    }

    public func handleClientUUID(context: ChannelHandlerContext, _ uuid: ClientUUID) {
        print("they're called \(uuid)")
    }

    public func handlePlayerHP(context: ChannelHandlerContext, _ playerHP: PlayerHP) {
        print("they're gay \(playerHP)")
    }

    public func handlePlayerMP(context: ChannelHandlerContext, _ playerMP: PlayerMP) {
        print("they're lesbian \(playerMP)")
    }

    public func handleUpdatePlayerBuff(context: ChannelHandlerContext, _ updatePlayerBuff: UpdatePlayerBuff) {
        print("heterosexuality \(updatePlayerBuff)")
    }

    public func handlePlayerInventorySlot(context: ChannelHandlerContext, _ playerInventorySlot: PlayerInventorySlot) {
        print("asexuality \(playerInventorySlot)")
    }

    public func handleRequestWorldData(context: ChannelHandlerContext, _ requestWorldData: RequestWorldData) {
        print("they want to know where the nearest gay bar is \(requestWorldData)")
    }

    // TODO: pretty with a Disconnect
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        _ = context.close()
        print("error! \(error)")
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)
        guard let handler = handlers[data.type] else {
            fatalError("unhandled packet kind")
        }
        handler(context, data)
    }
}