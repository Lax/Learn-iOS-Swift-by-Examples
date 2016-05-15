/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ServerConnection class. The ServerConnection class encapsulates and decapsulates a stream of network data in the server side of the SimpleTunnel tunneling protocol.
*/

import Foundation

/// An object representing the server side of a logical flow of TCP network data in the SimpleTunnel tunneling protocol.
class ServerConnection: Connection, NSStreamDelegate {

	// MARK: Properties

	/// The stream used to read network data from the connection.
	var readStream: NSInputStream?

	/// The stream used to write network data to the connection.
	var writeStream: NSOutputStream?

	// MARK: Interface

	/// Open the connection to a host and port.
	func open(host: String, port: Int) -> Bool {
		simpleTunnelLog("Connection \(identifier) connecting to \(host):\(port)")
		
		NSStream.getStreamsToHostWithName(host, port: port, inputStream: &readStream, outputStream: &writeStream)

		guard let newReadStream = readStream, newWriteStream = writeStream else {
			return false
		}

		for stream in [newReadStream, newWriteStream] {
			stream.delegate = self
			stream.open()
			stream.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		}

		return true
	}

	// MARK: Connection

	/// Close the connection.
	override func closeConnection(direction: TunnelConnectionCloseDirection) {
		super.closeConnection(direction)
		
		if let stream = writeStream where isClosedForWrite && savedData.isEmpty {
			if let error = stream.streamError {
				simpleTunnelLog("Connection \(identifier) write stream error: \(error)")
			}

			stream.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
			stream.close()
			stream.delegate = nil
			writeStream = nil
		}

		if let stream = readStream where isClosedForRead {
			if let error = stream.streamError {
				simpleTunnelLog("Connection \(identifier) read stream error: \(error)")
			}

			stream.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
			stream.close()
			stream.delegate = nil
			readStream = nil
		}
	}

	/// Abort the connection.
	override func abort(error: Int = 0) {
		super.abort(error)
		closeConnection(.All)
	}

	/// Stop reading from the connection.
	override func suspend() {
		if let stream = readStream {
			stream.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		}
	}

	/// Start reading from the connection.
	override func resume() {
		if let stream = readStream {
			stream.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
		}
	}

	/// Send data over the connection.
	override func sendData(data: NSData) {
		guard let stream = writeStream else { return }
		var written = 0

		if savedData.isEmpty {
			written = writeData(data, toStream: stream, startingAtOffset: 0)

			if written < data.length {
				// We could not write all of the data to the connection. Tell the client to stop reading data for this connection.
				stream.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
				tunnel?.sendSuspendForConnection(identifier)
			}
		}

		if written < data.length {
			savedData.append(data, offset: written)
		}
	}

	// MARK: NSStreamDelegate

	/// Handle an event on a stream.
	func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
		switch aStream {

			case writeStream!:
				switch eventCode {
					case [.HasSpaceAvailable]:
						if !savedData.isEmpty {
							guard savedData.writeToStream(writeStream!) else {
								tunnel?.sendCloseType(.All, forConnection: identifier)
								abort()
								break
							}

							if savedData.isEmpty {
								writeStream?.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
								if isClosedForWrite {
									closeConnection(.Write)
								}
								else {
									tunnel?.sendResumeForConnection(identifier)
								}
							}
						}
						else {
							writeStream?.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
						}

					case [.EndEncountered]:
						tunnel?.sendCloseType(.Read, forConnection: identifier)
						closeConnection(.Write)

					case [.ErrorOccurred]:
						tunnel?.sendCloseType(.All, forConnection: identifier)
						abort()

					default:
						break
				}

			case readStream!:
				switch eventCode {
					case [.HasBytesAvailable]:
						if let stream = readStream {
							while stream.hasBytesAvailable {
								var readBuffer = [UInt8](count: 8192, repeatedValue: 0)
								let bytesRead = stream.read(&readBuffer, maxLength: readBuffer.count)

								if bytesRead < 0 {
									abort()
									break
								}

								if bytesRead == 0 {
									simpleTunnelLog("\(identifier): got EOF, sending close")
									tunnel?.sendCloseType(.Write, forConnection: identifier)
									closeConnection(.Read)
									break
								}

								let readData = NSData(bytes: readBuffer, length: bytesRead)
								tunnel?.sendData(readData, forConnection: identifier)
							}
						}

					case [.EndEncountered]:
						tunnel?.sendCloseType(.Write, forConnection: identifier)
						closeConnection(.Read)

					case [.ErrorOccurred]:
						if let serverTunnel = tunnel as? ServerTunnel {
							serverTunnel.sendOpenResultForConnection(identifier, resultCode: .Timeout)
							serverTunnel.sendCloseType(.All, forConnection: identifier)
							abort()
						}

					case [.OpenCompleted]:
						if let serverTunnel = tunnel as? ServerTunnel {
							serverTunnel.sendOpenResultForConnection(identifier, resultCode: .Success)
						}

					default:
						break
				}
			default:
				break
		}
	}
}
