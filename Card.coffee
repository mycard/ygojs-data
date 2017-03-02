`'use strict'`

sqlite = require 'sqlite3'
sqliteSync = require 'better-sqlite3'
fs = require 'fs'

class Card
  constructor: (data) ->
    @readData data

  readData: (data) ->
    @id = data.id
    @ot = data.ot
    @alias = data.alias
    @setcode = data.setcode
    @type = data.type
    @category = data.category
    @name = data.name
    @desc = data.desc
    if @isTypeMonster
      @originLevel = data.level
      @race = data.race
      @attribute = data.attribute
      @atk = data.atk
      @def = data.def

Object.defineProperty Card.prototype, 'isAlias',
  get: -> @alias > 0

Object.defineProperty Card.prototype, 'isOcg',
  get: -> @ot & 1 > 0

Object.defineProperty Card.prototype, 'isTcg',
  get: -> @ot & 2 > 0

Object.defineProperty Card.prototype, 'isEx',
  get: -> @isSynchro or @isXyz or @isFusion or @isLink

Object.defineProperty Card.prototype, 'level',
  get: -> @originLevel % 65536

Object.defineProperty Card.prototype, 'pendulumScale',
  get: ->
    if @isTypePendulum
      (@originLevel - (@originLevel % 65536)) / 65536 / 257
    else
      -1

class Cards
  @readDataSQL = "select * from datas join texts on datas.id == texts.id where datas.id = (?)"
  @searchNameSQL = "select id from texts where name like (?)"
  @localePath = "./ygopro-database/locales/"
  @defaultConstants = "./constant.lua"

  constructor: (locale, constants) ->
    @cards = {}

    db = Cards.localePath + locale + "/cards.cdb"
    strings = Cards.localePath + locale + "/strings.conf"
    constants = Cards.defaultConstants unless constants

    @db = new sqlite.Database(db)
    @dbSync = new sqliteSync(db)

    @attributeNames = []
    @raceNames = []
    @typeNames = []

    @attributeConstants = []
    @raceConstants = []
    @typeConstants = []

    @attributes = []
    @races = []
    @types = []

    @loadStringsFile strings
    @loadConstantsFile constants
    @linkStringAndConstants()
    @registerMethods()

    proxy = new Proxy this, get: (target, name) ->
      id = parseInt name
      if id and id > 0
        return target.getCardByID id
      else
        target[name]

    Cards[locale] = proxy
    proxy

  getCardByIDASync: (id, callback) ->
    callback(@cards[id]) if @cards[id]
    @generateCardByIDAsync id, callback

  getCardByID: (id) ->
    callback(@cards[id]) if @cards[id]
    @generateCardByID id

  generateCardByIDAsync: (id, callback) ->
    stmt = @db.prepare Cards.readDataSQL
    stmt.run id
    stmt.all @onSqlRead.bind
      callback: callback,
      stmt: stmt,
      cards: @cards

  generateCardByID: (id) ->
    stmt = @dbSync.prepare Cards.readDataSQL
    row = stmt.get id
    if row
      card = new Card row
      @cards[card.id] = card
      card
    else
      console.log "no card [#{id}]"
      null

  onSqlRead: (err, rows) ->
     if (err)
       console.log "sql query failed: #{err}"
       @callback(null)
     else if rows.length == 0
       console.log "no card [#{id}]"
       @callback(null)
     else
      # as id is the primary key we can assume that rows always has 0 or 1 value.
       card = new Card rows[0]
       @cards[card.id] = card
       @callback(card)
     @stmt.finalize()

  # strings.conf load.
  loadStringsFile: (filePath) ->
    @loadStrings fs.readFileSync(filePath).toString()

  loadStrings: (stringFile)->
    lines = stringFile.split "\n"
    for line in lines
      continue unless line.startsWith '!system 10'
      [systemNumber, text] = @loadStringLines line
      @attributeNames.push text if @isAttributeName systemNumber
      @raceNames.push text if @isRaceName systemNumber
      @typeNames.push text if @isTypeName systemNumber

  loadStringLines: (line) ->
    reg = /!system (\d+) (.+)/
    answer = line.match reg
    return [0, ''] if answer == null
    [parseInt(answer[1]), answer[2]]

  isAttributeName: (systemNumber) ->
    systemNumber >= 1010 and systemNumber < 1020
  isRaceName: (systemNumber) ->
    systemNumber >= 1020 and systemNumber < 1050
  isTypeName: (systemNumber) ->
  # Magic Number: ???
    systemNumber >= 1050 and systemNumber < 1080 and systemNumber != 1053 and systemNumber != 1065

  # constant.lua load.
  loadConstantsFile: (filePath) ->
    @loadConstants fs.readFileSync(filePath).toString()

  loadConstants: (stringFile) ->
    lines = stringFile.split "\n"
    for line in lines
      [name, value] = @loadLuaLines line
      @checkAndAddConstant name, value, 'ATTRIBUTE_', @attributeConstants
      @checkAndAddConstant name, value, 'RACE_', @raceConstants
      @checkAndAddConstant name, value, 'TYPE_', @typeConstants
      # all type race
      @raceConstants = @raceConstants.slice(1)

  loadLuaLines: (line) ->
    answer = line.match /([A-Z_]+)\s*=\s*0x(\d+)/
    return ['', 0] if answer == null
    [answer[1], parseInt(answer[2], 16)]

  checkAndAddConstant: (name, value, prefix, target) ->
    return unless name.startsWith prefix
    target.push {name: name.substring(prefix.length).toLowerCase(), value: value}

  # links.
  linkStringAndConstants: ->
    @linkStringAndConstant @attributeNames, @attributeConstants, @attributes
    @linkStringAndConstant @raceNames, @raceConstants, @races
    @linkStringAndConstant @typeNames, @typeConstants, @types

  linkStringAndConstant: (strings, constants, target) ->
    target.length = 0
    for i in [0..(strings.length - 1)]
      constant = constants[i]
      continue unless constant
      target.push
        name: constant.name
        value: constant.value
        text: strings[i]

  # register
  # !!!WARNING!!!
  # @registerMethods set the Card class.
  # that means registered methods would be mixed in
  # that's because we oppose that constant.lua is always like.
  registerMethods: ->
    @registerTypedMethods "attribute", @attributes
    @registerTypedMethods "race", @races
    @registerTypedMethods "type", @types

  registerTypedMethods: (prefix, items) ->
    `
        for (let i = 0; i < items.length; i++) {
            let item = items[i];
            let name = "is" + prefix.toCamelCase() + item.name.toCamelCase();
            Card.prototype[name + "?"] = function () {
                return (this[prefix] & item.value) > 0
            }
            Object.defineProperty(Card.prototype, name, { get: Card.prototype[name + "?"], configurable: true });
        }
    `
    0
  raceName: (card) ->
    for race in @races
      if (card.race & race.value) > 0
        return race.text
    ''

  attributeName: (card) ->
    for attribute in @attributes
      if (card.attribute & attribute.value) > 0
        return attribute.text
    ''

String.prototype.toCamelCase = ->
  this[0].toUpperCase() + this.substring(1).toLowerCase()

new Cards('zh-CN')
new Cards('en-US')
new Cards('ja-JP')

@Cards = Cards