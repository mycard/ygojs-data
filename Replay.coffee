lzma = require 'lzma'
fs = require 'fs'
Deck = require './Deck.js'

class replayHeader
  @replayCompressedFlag = 0x1
  @replayTagFlag = 0x2
  @replayDecodedFlag = 0x4

  constructor: ->
    @id = 0
    @version = 0
    @flag = 0
    @seed = 0
    @dataSizeRaw = []
    @hash = 0
    @props = []

  getDataSize: ->
    @dataSizeRaw[0] + @dataSizeRaw[1] * 0x100 + @dataSizeRaw[2] * 0x10000 + @dataSizeRaw * 0x1000000

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
  constructor: (buffer) ->
    @pointer = 0
    @buffer = buffer

  readByte: ->
    answer = @buffer.readUInt8(@pointer)
    @pointer += 1
    answer

  readByteArray: (length) ->
    answer = []
    answer.push @readByte() for i in [1..length]
    answer

  readInt8: ->
    answer = @buffer.readInt8LE(@pointer)
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
    full = @buffer.slice(@pointer, @pointer + length).toString('utf-16le')
    answer = full.split("\u0000")[0]
    @pointer += length
    answer

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

  @fromFile: (filePath) ->
    Replay.fromBuffer fs.readFileSync filePath

  @fromBuffer: (buffer) ->
    reader = new ReplayReader buffer
    header = Replay.readHeader reader
    lzmaBuffer = Buffer.concat [header.getLzmaHeader(), reader.readAll()]
    if header.isCompressed
      decompressed = lzmaBuffer
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
    replay.clientName = reader.readString(40)
    replay.startLp = reader.readInt32()
    replay.startHand = reader.readInt32()
    replay.drawCount = reader.readInt32()
    replay.opt = reader.readInt32()
    replay.hostDeck = Replay.readDeck reader
    replay.clientDeck = Replay.readDeck reader
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

module.exports = Replay