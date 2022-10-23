import Foundation
import NIO
import NIOExtras
import Dispatch

let HeaderSize = UInt16.byteWidth + UInt8.byteWidth

protocol Packet {
    static var type: UInt8 { get }
    static var estimatedSize: Int { get }
}

extension Packet {
    var type: UInt8 { Self.type }
    var estimatedSize: Int { Self.estimatedSize }
}

protocol ClientToServerPacket: Packet {
    init?(size: Int, data: inout ByteBuffer)
}

protocol ServerToClientPacket: Packet {
    func writeBody(to: inout ByteBuffer)
}

protocol BidirectionalPacket: ClientToServerPacket, ServerToClientPacket {
}

enum PacketError {
    case UnsupportedPacketKind(kind: UInt8)
    case Failed
}

extension PacketError: LocalizedError {
}



struct Connect: ClientToServerPacket {
    let version: String
}

extension Connect {
    static let type: UInt8 = 1
    static let estimatedSize: Int = 11

    init?(size: Int, data: inout ByteBuffer) {
        guard let version = data.readString(length: size) else {
            return nil
        }
        self.version = String(version.dropFirst())
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.writeString(version)
    }
}



struct ClientUUID: ClientToServerPacket {
    let uuid: String
}

extension ClientUUID {
    static let type: UInt8 = 68
    static let estimatedSize: Int = 32

    init?(size: Int, data: inout ByteBuffer) {
        guard let uuid = data.readString(length: size) else {
            return nil
        }
        self.uuid = String(uuid.dropFirst())
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.writeString(uuid)
    }
}



struct SetUserSlot: ServerToClientPacket {
    let slot: UInt8
}

extension SetUserSlot {
    static let type: UInt8 = 3
    static let estimatedSize: Int = 1

    init?(size: Int, data: inout ByteBuffer) {
        guard let slot: UInt8 = data.read() else { return nil }
        self.slot = slot
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.writeInteger(slot, endianness: .little)
    }
}



struct PlayerHP: BidirectionalPacket {
    let forPlayer: UInt8
    let hp: Int16
    let maxHP: Int16
}

extension PlayerHP {
    static let type: UInt8 = 16
    static let estimatedSize: Int = 5

    init?(size: Int, data: inout ByteBuffer) {
        guard let forPlayer: UInt8 = data.read() else { return nil }
        self.forPlayer = forPlayer
        guard let hp: Int16 = data.read() else { return nil }
        self.hp = hp
        guard let maxHP: Int16 = data.read() else { return nil }
        self.maxHP = maxHP
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.write(self.forPlayer)
        buffer.write(self.hp)
        buffer.write(self.maxHP)
    }
}



struct PlayerMP: BidirectionalPacket {
    let forPlayer: UInt8
    let mp: Int16
    let maxMP: Int16
}

extension PlayerMP {
    static let type: UInt8 = 42
    static let estimatedSize: Int = 5

    init?(size: Int, data: inout ByteBuffer) {
        guard let forPlayer: UInt8 = data.read() else { return nil }
        self.forPlayer = forPlayer
        guard let hp: Int16 = data.read() else { return nil }
        self.mp = hp
        guard let maxHP: Int16 = data.read() else { return nil }
        self.maxMP = maxHP
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.write(self.forPlayer)
        buffer.write(self.mp)
        buffer.write(self.maxMP)
    }
}



struct UpdatePlayerBuff: BidirectionalPacket {
    let forPlayer: UInt8
    let buffs: [UInt16]
}

extension UpdatePlayerBuff {
    static let type: UInt8 = 50
    static let estimatedSize: Int = 45

    init?(size: Int, data: inout ByteBuffer) {
        guard let forPlayer: UInt8 = data.read() else { return nil }
        self.forPlayer = forPlayer
        var buffs: [UInt16] = []
        buffs.reserveCapacity(22)
        for _ in 0...21 {
            guard let buff: UInt16 = data.read() else { return nil }
            buffs.append(buff)
        }
        self.buffs = buffs
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.write(self.forPlayer)
        for buff in buffs {
            buffer.write(buff)
        }
    }
}



struct PlayerInventorySlot: BidirectionalPacket {
    let forPlayer: UInt8
    let slotID: Int16
    let stack: Int16
    let prefix: UInt8
    let netID: UInt16
}

extension PlayerInventorySlot {
    static let type: UInt8 = 5
    static let estimatedSize: Int = 8

    init?(size: Int, data: inout ByteBuffer) {
        guard let forPlayer: UInt8 = data.read() else { return nil }
        self.forPlayer = forPlayer
        guard let slotID: Int16 = data.read() else { return nil }
        self.slotID = slotID
        guard let stack: Int16 = data.read() else { return nil }
        self.stack = stack
        guard let prefix: UInt8 = data.read() else { return nil }
        self.prefix = prefix
        guard let netID: UInt16 = data.read() else { return nil }
        self.netID = netID
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.write(forPlayer)
        buffer.write(slotID)
        buffer.write(stack)
        buffer.write(prefix)
        buffer.write(netID)
    }
}




struct RequestWorldData: ClientToServerPacket {

}

extension RequestWorldData {
    static let type: UInt8 = 6
    static let estimatedSize: Int = 0

    init?(size: Int, data: inout ByteBuffer) {

    }
    func writeBody(to buffer: inout ByteBuffer) {

    }
}



struct PlayerInfo: BidirectionalPacket {
    let forPlayer: UInt8
    let skinVariant: UInt8
    let hair: UInt8
    let name: String
    let hairDye: UInt8
    let hideVisuals: UInt8
    let hideVisuals2: UInt8
    let hideMisc: UInt8
    let hairColor: Color
    let skinColor: Color
    let eyeColor: Color
    let shirtColor: Color
    let underShirtColor: Color
    let pantsColor: Color
    let shoeColor: Color
    let difficultyFlags: UInt8
    let torchFlags: UInt8
}

extension PlayerInfo {
    static let type: UInt8 = 4
    static let estimatedSize: Int = MemoryLayout<PlayerInfo>.size

    static var otherWidth: Int {
        var a = 0
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        a += Color.byteWidth
        a += Color.byteWidth
        a += Color.byteWidth
        a += Color.byteWidth
        a += Color.byteWidth
        a += Color.byteWidth
        a += Color.byteWidth
        a += UInt8.byteWidth
        a += UInt8.byteWidth
        return a
    }
    init?(size: Int, data: inout ByteBuffer) {
        guard let forPlayer: UInt8 = data.read() else { return nil }
        self.forPlayer = forPlayer
        guard let skinVariant: UInt8 = data.read() else { return nil }
        self.skinVariant = skinVariant
        guard let hair: UInt8 = data.read() else { return nil }
        self.hair = hair

        guard let name = data.readString(length: size - PlayerInfo.otherWidth) else {
            return nil
        }
        self.name = String(name.dropFirst())

        guard let hairDye: UInt8 = data.read() else { return nil }
        self.hairDye = hairDye
        guard let hideVisuals: UInt8 = data.read() else { return nil }
        self.hideVisuals = hideVisuals
        guard let hideVisuals2: UInt8 = data.read() else { return nil }
        self.hideVisuals2 = hideVisuals2
        guard let hideMisc: UInt8 = data.read() else { return nil }
        self.hideMisc = hideMisc
        guard let hairColor: Color = data.read() else { return nil }
        self.hairColor = hairColor
        guard let skinColor: Color = data.read() else { return nil }
        self.skinColor = skinColor
        guard let eyeColor: Color = data.read() else { return nil }
        self.eyeColor = eyeColor
        guard let shirtColor: Color = data.read() else { return nil }
        self.shirtColor = shirtColor
        guard let underShirtColor: Color = data.read() else { return nil }
        self.underShirtColor = underShirtColor
        guard let pantsColor: Color = data.read() else { return nil }
        self.pantsColor = pantsColor
        guard let shoeColor: Color = data.read() else { return nil }
        self.shoeColor = shoeColor
        guard let difficultyFlags: UInt8 = data.read() else { return nil }
        self.difficultyFlags = difficultyFlags
        guard let torchFlags: UInt8 = data.read() else { return nil }
        self.torchFlags = torchFlags
    }
    func writeBody(to buffer: inout ByteBuffer) {
        buffer.write(self.forPlayer)
        buffer.write(self.skinVariant)
        buffer.write(self.hair)
        buffer.write(self.name)
        buffer.write(self.hairDye)
        buffer.write(self.hideVisuals)
        buffer.write(self.hideVisuals2)
        buffer.write(self.hideMisc)
        buffer.write(self.hairColor)
        buffer.write(self.skinColor)
        buffer.write(self.eyeColor)
        buffer.write(self.shirtColor)
        buffer.write(self.underShirtColor)
        buffer.write(self.pantsColor)
        buffer.write(self.shoeColor)
        buffer.write(self.difficultyFlags)
        buffer.write(self.torchFlags)
    }
}


struct Color {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
}

extension Color {
    init() {
        self.red = 0
        self.green = 0
        self.blue = 0
    }
    init?(from buffer: inout ByteBuffer) {
        guard let red: UInt8 = buffer.readInteger(endianness: .little) else { return nil }
        guard let green: UInt8 = buffer.readInteger(endianness: .little) else { return nil }
        guard let blue: UInt8 = buffer.readInteger(endianness: .little) else { return nil }

        self.red = red
        self.green = green
        self.blue = blue
    }
    func write(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self.red, endianness: .little)
        buffer.writeInteger(self.green, endianness: .little)
        buffer.writeInteger(self.blue, endianness: .little)
    }
}
