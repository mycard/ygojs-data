lzma = require 'lzma'
fs = require 'fs'
Deck = require './Deck.js'

class replayHeader
  @replayCompressedFlag = 0x1
  @replayTagFlag = 0x2
  @replayDecodedFlag = 0x4
  @replaySinglMode = 0x8
  @replayUniform = 0x10

  constructor: ->
    @id = 0
    @version = 0
    @flag = 0
    @seed = 0
    @dataSizeRaw = []
    @hash = 0
    @props = []

  getDataSize: ->
    @dataSizeRaw[0] + @dataSizeRaw[1] * 0x100 + @dataSizeRaw[2] * 0x10000 + @dataSizeRaw[3] * 0x1000000

  getIsTag: ->
    @flag & replayHeader.replayTagFlag > 0

  getIsCompressed: ->
    @flag & replayHeader.replayCompressedFlag > 0

  getLzmaHeader: ->
    bytes = [].concat(@props[0..4], @dataSizeRaw, [0, 0, 0, 0])
    Buffer.from(bytes)

  Object.defineProperty replayHeader.prototype, 'dataSize', get: @getDataSize
  Object.defineProperty replayHeader.prototype, 'isTag', get: @getIsTag
  Object.defineProperty replayHeader.prototype, 'isCompressed', get: @getIsCompressed

class ReplayReader
  constructor: (@buffer) ->
    @pointer = 0

  readByte: ->
    answer = @buffer.readUInt8(@pointer)
    @pointer += 1
    answer

  readByteArray: (length) ->
    answer = []
    answer.push @readByte() for i in [1..length]
    answer

  readInt8: ->
    answer = @buffer.readInt8(@pointer)
    @pointer += 1
    answer

  readUInt8: ->
    answer = @buffer.readUInt8(@pointer)
    @pointer += 1
    answer

  readInt16: ->
    answer = @buffer.readInt16LE @pointer
    @pointer += 2
    answer

  readInt32: ->
    answer = @buffer.readInt32LE @pointer
    @pointer += 4
    answer

  readAll: ->
    answer = @buffer.slice(@pointer)
    # @pointer = 0
    answer

  readString: (length) ->
    if @pointer + length > @buffer.length
      return null
    full = @buffer.slice(@pointer, @pointer + length).toString('utf-16le')
    answer = full.split("\u0000")[0]
    @pointer += length
    answer

  readRaw: (length) ->
    if @pointer + length > @buffer.length
      return null
    answer = @buffer.slice(@pointer, @pointer + length)
    @pointer += length
    answer

class ReplayWriter
  constructor: (@buffer) ->
    @pointer = 0

  writeByte: (val) -> @buffer.writeUInt8(val, @pointer); @pointer += 1
  writeByteArray: (vals) -> @writeByte(val) for val from vals
  writeInt8: (val) -> @buffer.writeInt8(val, @pointer); @pointer += 1
  writeUInt8: (val) -> @buffer.writeUInt8(val, @pointer); @pointer += 1
  writeInt16: (val) -> @buffer.writeInt16LE(val, @pointer); @pointer += 2
  writeInt32: (val) -> @buffer.writeInt32LE(val, @pointer); @pointer += 4
  writeAll: (val) -> @buffer = Buffer.concat [@buffer, val]
  writeString: (val, length) -> 
    raw = Buffer.from val, 'utf-16le'
    array = Uint8Array.from raw 
    array = [...array, ...Uint8Array.from({ length: length - array.length })] if length?
    @writeByteArray array

class Replay
  constructor: ->
    @header = null
    @hostName = ""
    @clientName = ""
    @startLp = 0
    @startHand = 0
    @drawCount = 0
    @opt = 0
    @hostDeck = null
    @clientDeck = null

    @tagHostName = null
    @tagClientName = null
    @tagHostDeck = null
    @tagClientDeck = null

    @responses = null

  getDecks: ->
    if @isTag
      [@hostDeck, @clientDeck, @tagHostDeck, @tagClientDeck]
    else
      [@hostDeck, @clientDeck]

  getIsTag: ->
    @header == null ? false : @header.isTag

  @fromFile: (filePath) ->
    Replay.fromBuffer fs.readFileSync filePath

  @fromBuffer: (buffer) ->
    reader = new ReplayReader buffer
    header = Replay.readHeader reader
    raw = reader.readAll()
    lzmaBuffer = Buffer.concat [header.getLzmaHeader(), raw]
    if header.isCompressed
      decompressed = raw 
    else
      decompressed = Buffer.from lzma.decompress lzmaBuffer
    reader = new ReplayReader decompressed
    replay = Replay.readReplay header, reader
    replay

  @readHeader: (reader) ->
    header = new replayHeader()
    header.id = reader.readInt32()
    header.version = reader.readInt32()
    header.flag = reader.readInt32()
    header.seed = reader.readInt32()
    header.dataSizeRaw = reader.readByteArray 4
    header.hash = reader.readInt32()
    header.props = reader.readByteArray 8
    header

  @readReplay: (header, reader) ->
    replay = new Replay()
    replay.header = header
    replay.hostName = reader.readString(40)
    replay.tagHostName = reader.readString(40) if header.isTag
    replay.tagClientName = reader.readString(40) if header.isTag
    replay.clientName = reader.readString(40)
    replay.startLp = reader.readInt32()
    replay.startHand = reader.readInt32()
    replay.drawCount = reader.readInt32()
    replay.opt = reader.readInt32()
    replay.hostDeck = Replay.readDeck reader
    replay.tagHostDeck = Replay.readDeck reader if header.isTag
    replay.tagClientDeck = Replay.readDeck reader if header.isTag
    replay.clientDeck = Replay.readDeck reader
    replay.responses = Replay.readResponses reader
    replay

  @readDeck: (reader) ->
    deck = new Deck
    deck.main = Replay.readDeckPack reader
    deck.ex = Replay.readDeckPack reader
    deck

  @readDeckPack: (reader) ->
    length = reader.readInt32()
    answer = []
    answer.push reader.readInt32() for i in [1..length]
    answer

  @readResponses: (reader) ->
    answer = []
    while true
      try
        length = reader.readUInt8()
        if length > 64
          length = 64
        single = reader.readRaw(length)
        if !single
          break
        answer.push(single)
      catch
        break
    answer

  Object.defineProperty replayHeader.prototype, 'decks', get: @getDecks
  Object.defineProperty replayHeader.prototype, 'isTag', get: @getIsTag

  toBuffer: ->
    # Let's do some math!
    headerWriter = new ReplayWriter Buffer.alloc 32
    @writeHeader headerWriter
    deckSize = (deck) -> (deck.main.length + deck.ex.length) * 4 + 8
    responseSize = @responses.map((r) => r.length + 1).reduce(((a, b) => a + b), 0)
    contentSize = 96 + deckSize(@hostDeck) + deckSize(@clientDeck) + responseSize
    contentSize += deckSize(@tagHostDeck) + deckSize(@tagClientDeck) + 80 if @header.isTag
    contentWriter = new ReplayWriter Buffer.alloc contentSize
    @writeReplayContent contentWriter
    headerBuffer = headerWriter.buffer
    contentBuffer = contentWriter.buffer
    contentBuffer = new Buffer(lzmaBuffer.compress(contentBuffer))[13..] if @header.isCompressed
    Buffer.concat [headerBuffer, contentBuffer]

  writeToFile: (file) ->
    fs.writeFileSync file, @toBuffer()

  writeHeader: (writer) ->
    writer.writeInt32 @header.id
    writer.writeInt32 @header.version
    writer.writeInt32 @header.flag
    writer.writeInt32 @header.seed
    writer.writeByteArray @header.dataSizeRaw
    writer.writeInt32 @header.hash
    writer.writeByteArray @header.props

  writeReplayContent: (writer) ->
    writer.writeString @hostName, 40
    writer.writeString @tagHostName, 40 if @header.isTag
    writer.writeString @tagClientName, 40 if @header.isTag
    writer.writeString @clientName, 40
    writer.writeInt32 @startLp
    writer.writeInt32 @startHand
    writer.writeInt32 @drawCount
    writer.writeInt32 @opt
    Replay.writeDeck writer, @hostDeck
    Replay.writeDeck writer, @tagHostDeck if @header.isTag
    Replay.writeDeck writer, @tagClientDeck if @header.isTag
    Replay.writeDeck writer, @clientDeck
    Replay.writeResponses writer, @responses

  @writeDeck: (writer, deck) ->
    @writeDeckPack writer, deck.main
    @writeDeckPack writer, deck.ex

  @writeDeckPack: (writer, pack) ->
    writer.writeInt32 pack.length
    writer.writeInt32 card for card from pack

  @writeResponses: (writer, responses) ->
    for response from responses
      writer.writeUInt8 response.length
      writer.writeByteArray Uint8Array.from response

module.exports = Replay
