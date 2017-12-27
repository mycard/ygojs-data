Config = require './Variables.json'
fs = require 'fs'
path = require 'path'
sqlite = require 'better-sqlite3'
Card = require './Card'
Set = require './Set'

String.prototype.toCamelCase = ->
  this[0].toUpperCase() + this.substring(1).toLowerCase()

class Environment
  @attributeConstants = []
  @raceConstants = []
  @typeConstants = []
  @environments = {}

  @loadLuaFile = ->
    constantString = fs.readFileSync(path.join __dirname, Config.luaPath).toString()
    constantLines = constantString.split "\n"
    for constantLine in constantLines
      [name, value] = @loadLuaLines constantLine
      @checkAndAddConstant name, value, 'ATTRIBUTE_', @attributeConstants
      @checkAndAddConstant name, value, 'RACE_', @raceConstants
      @checkAndAddConstant name, value, 'TYPE_', @typeConstants

  @loadLuaLines: (line) ->
    answer = line.match /([A-Z_]+)\s*=\s*0x(\d+)/
    return ['', 0] if answer == null
    [answer[1], parseInt(answer[2], 16)]

  @checkAndAddConstant: (name, value, prefix, target) ->
    return unless name.startsWith prefix
    target.push {name: name.substring(prefix.length).toLowerCase(), value: value}

  @loadLuaFile()

  @registerMethods: ->
    @registerTypedMethods "attribute", @attributeConstants
    @registerTypedMethods "race", @raceConstants
    @registerTypedMethods "type", @typeConstants

  @registerTypedMethods: (prefix, items) ->
    for i in [0..items.length - 1]
       `let item = items[i]`
       name = "is" + prefix.toCamelCase() + item.name.toCamelCase()
       Card[name + "?"] = -> return (this[prefix] & item.value) > 0
       Object.defineProperty Card.prototype, name, { get: Card[name + "?"], configurable: true }

  @registerMethods()
  
  @setConfig: (config) ->
    Config[key] = value for key, value of config

  # SQL 卡片查询指令
  @READ_DATA_SQL = 'select * from datas join texts on datas.id == texts.id where datas.id == (?)'
  @READ_ALL_DATA_SQL = 'select * from datas join texts on datas.id == texts.id'
  # SQL 系列查询指令
  @QUERY_SET_SQL = 'select id from datas where (setcode & 0x0000000000000FFF == (?) or setcode & 0x000000000FFF0000 == (?) or setcode & 0x00000FFF00000000 == (?) or setcode & 0x0FFF000000000000 == (?))'
  @QUERY_SUBSET_SQL = 'select id from datas where (setcode & 0x000000000000FFFF == (?) or setcode & 0x00000000FFFF0000 == (?) or setcode & 0x0000FFFF00000000 == (?) or setcode & 0xFFFF000000000000 == (?))'
  # SQL 卡片查询指令
  @SEARCH_NAME_SQL = 'select id from texts where name like (?)'
  @STRICTLY_SEARCH_NAME_SQL = 'select id from texts where name == (?)'

  constructor: (locale) ->
    return Environment[locale] if Environment[locale]

    @attributes = []
    @races = []
    @types = []
    @sets = []
    @locale = locale
    @cards = {}

    @dbs = @searchCdb locale

    @attributeNames = []
    @typeNames = []
    @raceNames = []
    @setNames = []

    @loadStringFile()
    @linkStringAndConstants()
    @linkSetnameToSql()
    Environment[locale] = this

    proxy = new Proxy this, get: (target, name) ->
      id = parseInt name if typeof name == 'string'
      if id and id > 0 then return target.getCardById id else return target[name]
    return proxy

  searchCdb: ->
    locale = @locale
    db_all_files = fs.readdirSync path.join Config.databasePath, "/#{locale}"
    db_files = []
    for db_file in db_all_files
      db_files.push db_file if db_file.endsWith(".cdb")
    db_files.map (db_file) -> new sqlite(path.join Config.databasePath, "/#{locale}", db_file)

  loadStringFile: ->
    stringsFileString = fs.readFileSync(path.join Config.databasePath, "#{@locale}/strings.conf").toString()
    stringLines = stringsFileString.split "\n"
    for stringLine in stringLines
      if stringLine.startsWith? '!system 10'
        [systemNumber, text] = @loadStringLinePattern stringLine
        @attributeNames.push text if @isAttributeName systemNumber
        @raceNames.push text if @isRaceName systemNumber
        @typeNames.push text if @isTypeName systemNumber
      else if stringLine.startsWith? '!setname'
        [setCode, setName] = @loadSetnameLinePattern stringLine
        @sets.push new Set setCode, setName, @locale


  loadStringLinePattern: (line) ->
    reg = /!system (\d+) (.+)/
    answer = line.match reg
    return [0, ''] if answer == null
    [parseInt(answer[1]), answer[2]]


  loadSetnameLinePattern: (line) ->
    reg = /!setname 0x([0-9a-fA-F]+) (.+)/
    answer = line.match reg
    return [0, ''] if !answer
    [parseInt(answer[1], 16), answer[2]]

  linkStringAndConstants: ->
    @linkStringAndConstantsPattern @attributeNames, Environment.attributeConstants, @attributes
    @linkStringAndConstantsPattern @raceNames, Environment.raceConstants, @races
    @linkStringAndConstantsPattern @typeNames, Environment.typeConstants, @types

  linkStringAndConstantsPattern: (strings, constants, target) ->
    target.length = 0
    for i in [0..(strings.length - 1)]
      constant = constants[i]
      continue unless constant
      target.push
        name: constant.name
        value: constant.value
        text: strings[i]

  isAttributeName: (systemNumber) -> systemNumber >= 1010 and systemNumber < 1020
  isRaceName: (systemNumber) -> systemNumber >= 1020 and systemNumber < 1050
  isTypeName: (systemNumber) -> systemNumber >= 1050 and systemNumber < 1080 and systemNumber != 1053 and systemNumber != 1065

  linkSetnameToSql: ->
    for set in @sets
      ids = []
      for db in @dbs
        ids += Environment.getIdsBySetCode db, set.code
      set.ids = ids

  @getIdsBySetCode: (db, code) ->
    stmt = db.prepare(if code < 0xFF then Environment.QUERY_SET_SQL else Environment.QUERY_SUBSET_SQL)
    rows = stmt.all code, code, code, code
    if rows
      return rows.map (row) -> row.id
    else
      return []

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

  typeName: (card) ->
    typeNames = []
    for type in @types
      if (card.type & type.value) > 0
        typeNames.push attribute.text
    typeNames

  getCardById: (id) ->
    card = @cards[id]
    return if card then card else @generateCardById(id)

  generateCardById: (id) ->
    for db in @dbs
      card = @tryGenerateCardById db, id
      return card if card
    null

  tryGenerateCardById: (database, id) ->
    stmt = database.prepare Environment.READ_DATA_SQL
    row = stmt.get id
    return null if !row
    card = new Card row
    card.locale = @locale
    @cards[id] = card
    card

  loadAllCards: ->
    @cards.clear
    @loadAllCardFromDatabase db for db in @dbs

  loadAllCardFromDatabase: (database) ->
    rows = database.prepare(Environment.READ_ALL_DATA_SQL).all()
    for row in rows
      card = new Card row
      card.locale = @locale
      @cards[card.id] = card
    @cards

  clearCards: ->
    @cards = {}

  searchCardByName: (name) ->
    ids = []
    for db in @dbs
      ids += @searchCardByNameFromDatabase(db, name)
    ids

  searchCardByNameFromDatabase: (database, name) ->
    stmt = database.prepare(Environment.SEARCH_NAME_SQL)
    rows = stmt.all("%#{name}%")
    return [] unless rows
    rows.map (row) -> row.id

  getCardByName: (name) ->
    for db in @dbs
      id = @getCardByNameFromDatabase(db, name)
      return @getCardById(id) if id and id > 0
    for db in @dbs
      ids = @searchCardByNameFromDatabase(db, name)
      return @getCardById(ids[0]) if ids and ids.length > 0
    null

  getCardByNameFromDatabase: (database, name) ->
    stmt = database.prepare(Environment.STRICTLY_SEARCH_NAME_SQL)
    rows = stmt.get name
    if !rows or rows.length == 0 then null else rows[0].id

module.exports = Environment