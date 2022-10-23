import Foundation
import NIO
import NIOExtras
import Dispatch

extension FixedWidthInteger {
    init<I>(littleEndianBytes iterator: inout I)
    where I: IteratorProtocol, I.Element == UInt8 {
        self = stride(from: 0, to: Self.bitWidth, by: 8).reduce(into: 0) {
            $0 |= Self(truncatingIfNeeded: iterator.next()!) &<< $1
        }
    }
    
    init<C>(littleEndianBytes bytes: C) where C: Collection, C.Element == UInt8 {
        precondition(bytes.count == (Self.bitWidth+7)/8)
        var iter = bytes.makeIterator()
        self.init(littleEndianBytes: &iter)
    }

    static var byteWidth: Int {
        self.bitWidth / 8
    }
}

extension ByteBuffer {
    static func from(packet: ServerToClientPacket, with allocator: ByteBufferAllocator) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: HeaderSize + packet.estimatedSize)
        buffer.moveWriterIndex(forwardBy: HeaderSize)

        let beforePos = buffer.writerIndex
        packet.writeBody(to: &buffer)
        let afterPos = buffer.writerIndex

        buffer.moveWriterIndex(to: 0)
        buffer.writeInteger(UInt16(afterPos - beforePos), endianness: .little)
        buffer.writeInteger(packet.type, endianness: .little)

        return buffer
    }
}

extension Channel {
    func send(packet: ServerToClientPacket) {
        self.writeAndFlush(ByteBuffer.from(packet: packet, with: self.allocator), promise: nil)
    }
}



protocol ByteSized {
    static var byteWidth: Int { get }
}

extension ByteSized {
    var byteWidth: Int { Self.byteWidth }
}

protocol AutoByteSized: ByteSized {
    init()
}

extension AutoByteSized {
    static var byteWidth: Int {
        let mirror = Mirror(reflecting: Self())
        var size = 0
        for child in mirror.children {
            if let sizeable = child.value as? ByteSized {
                size += sizeable.byteWidth
            }
        }
        return size
    }
}

extension UInt8: ByteSized { }
extension UInt16: ByteSized { }
extension Color: AutoByteSized { }

protocol TerrariaReadable {
    static func read(from: inout ByteBuffer) -> Self?
}

extension ByteBuffer {
    mutating func read<T: TerrariaReadable>() -> T? {
        T.read(from: &self)
    }
}

extension UInt8: TerrariaReadable {
    static func read(from buffer: inout ByteBuffer) -> UInt8? {
        buffer.readInteger(endianness: .little)
    }
}

extension UInt16: TerrariaReadable {
    static func read(from buffer: inout ByteBuffer) -> UInt16? {
        buffer.readInteger(endianness: .little)
    }
}

extension Int8: TerrariaReadable {
    static func read(from buffer: inout ByteBuffer) -> Int8? {
        buffer.readInteger(endianness: .little)
    }
}

extension Int16: TerrariaReadable {
    static func read(from buffer: inout ByteBuffer) -> Int16? {
        buffer.readInteger(endianness: .little)
    }
}

extension Color: TerrariaReadable {
    static func read(from buffer: inout ByteBuffer) -> Color? {
        Color(from: &buffer)
    }
}



protocol TerrariaWritable {
    func write(to: inout ByteBuffer)
}

extension ByteBuffer {
    mutating func write(_ value: TerrariaWritable) {
        value.write(to: &self)
    }
}

extension UInt8: TerrariaWritable {
    func write(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self, endianness: .little)
    }
}

extension UInt16: TerrariaWritable {
    func write(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self, endianness: .little)
    }
}

extension Int8: TerrariaWritable {
    func write(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self, endianness: .little)
    }
}

extension Int16: TerrariaWritable {
    func write(to buffer: inout ByteBuffer) {
        buffer.writeInteger(self, endianness: .little)
    }
}

extension Color: TerrariaWritable {
}

extension String: TerrariaWritable {
    func write(to buffer: inout ByteBuffer) {
        buffer.writeString(self)
    }
}
