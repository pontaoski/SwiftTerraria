import Foundation
import NIO
import NIOExtras
import Dispatch

final class TerrariaServer {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let host: String
    let port: Int
    let bootstrap: ServerBootstrap
    var handler: ServerHandler

    init(host: String, port: Int) {
        let handler = ServerHandler()
        self.handler = handler
        self.host = host
        self.port = port
        self.bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(BackPressureHandler()).flatMap {
                    channel.pipeline.addHandler(ByteToMessageHandler(PacketDecoder())).flatMap {
                        channel.pipeline.addHandler(handler)
                    }
                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    func bind() throws -> Channel {
        return try bootstrap.bind(host: self.host, port: self.port).wait()
    }
}

let server = TerrariaServer(host: CommandLine.arguments[1], port: Int(CommandLine.arguments[2])!)
let channel = try server.bind()
try channel.closeFuture.wait()
