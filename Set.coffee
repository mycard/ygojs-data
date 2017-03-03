`'use strict'`

sqlite = require 'sqlite3'
sqliteSync = require 'better-sqlite3'
fs = require 'fs'

class Set
  constructor: (number, name, parent) ->
    @number = number
    @name = name
    @parent = parent
    @ids = null

  includes: (card) ->
    id = (Number.isInteger(card)) ? card : card.id
    @ids = @parent.searchSetByNumber @number unless @ids
    @ids.includes id

  includesAsync: (card, callback) ->
    id = (Number.isInteger(card)) ? card : card.id
    callback(@ids.includes id) if @ids
    set = this
    @parent.searchSetByNumberAsync @number, (ids) ->
      set.ids = ids
      callback(set.ids.includes(id))

class Sets

  @SqlQuerySet    = 'select id from datas where (setcode & 0x0000000000000FFF == (?) or setcode & 0x000000000FFF0000 == (?) or setcode & 0x00000FFF00000000 == (?) or setcode & 0x0FFF000000000000 == (?))'
  @SqlQuerySubset = 'select id from datas where (setcode & 0x000000000000FFFF == (?) or setcode & 0x00000000FFFF0000 == (?) or setcode & 0x0000FFFF00000000 == (?) or setcode & 0xFFFF000000000000 == (?))'
  @localePath = "./ygopro-database/locales/"

  constructor: (locale) ->
    db = Sets.localePath + locale + "/cards.cdb"
    strings = Sets.localePath + locale + "/strings.conf"

    @db = new sqlite.Database(db)
    @dbSync = new sqliteSync(db)
    @sets = []

    @loadStringsFile strings

    Sets[locale] = this

  loadStringsFile: (filePath) ->
    @loadStrings fs.readFileSync(filePath).toString()

  loadStrings: (stringFile)->
    lines = stringFile.split "\n"
    for line in lines
      continue unless line.startsWith '!setname '
      [number, name] = @loadStringLines line
      @sets.push new Set number, name, this if number > 0
    0

  loadStringLines: (line) ->
    reg = /!setname 0x([0-9a-fA-F]+) (.+)/
    answer = line.match reg
    return [0, '', ''] if answer == null
    [parseInt(answer[1], 16), answer[2]]

  @sqlForNum: (number) ->
    if number > 255
      Sets.SqlQuerySubset
    else
      Sets.SqlQuerySet

  searchSetByNumber: (number) ->
    stmt = @dbSync.prepare Sets.sqlForNum number
    console.log number
    rows = stmt.all number, number, number, number
    if rows
      ids = []
      console.log rows
      ids.push row.id for row in rows
      ids
    else
      console.log "no card with set number [#{number}]"
      []

  searchSetByNumberAsync: (number, callback) ->
    stmt = @db.prepare Sets.sqlForNum number
    stmt.run number, number, number, number
    stmt.all @onSqlRead.bind
      callback: callback,
      stmt: stmt,
      number: number

  onSqlRead: (err, rows) ->
    if (err)
      console.log "sql query failed: #{err}"
      @callback(null)
    else if rows.length == 0
      console.log "no card with set number [#{@number}]"
      @callback []
    else
      ids = []
      ids.push row.id for row in rows
      @callback(ids)
    @stmt.finalize()

module.exports = Sets