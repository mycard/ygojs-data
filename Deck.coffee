`'use strict'`

fs = require 'fs'

class Deck
  constructor: ->
    @main = []
    @side = []
    @ex = []
    @classifiedMain = {}
    @classifiedSide = {}
    @classifiedEx = {}
    @form = 'id'

  classify: ->
    @classifyPack @main, @classifiedMain
    @classifyPack @side, @classifiedSide
    @classifyPack @ex, @classifiedEx
    this

  classifyPack: (from, to) ->
    for obj in from
      to[obj] = 0
    for obj in from
      to[obj] += 1

  separateExFromMain: ->
    @transformToCards if @form != 'card'
    newMain = []
    for card in @main
      continue unless card
      if card.isEx
        @ex.push card
      else
        newMain.push card
    @main = newMain
    this

  transformToCards: (environment) ->
    return if @form == 'card'
    @main = @transformPackToCards environment, @main
    @side = @transformPackToCards environment, @side
    @ex = @transformPackToCards environment, @ex
    @form = 'card'
    this

  transformPackToCards: (environment, pack) ->
    answer = []
    answer.push environment[id] for id in pack
    answer

  transformToId: ->
    return if @form == 'id'
    @main = @transformPackToIds environment, @main
    @side = @transformPackToIds environment, @side
    @ex = @transformPackToIds environment, @ex
    @form = 'id'
    this

  transformPackToIds: (pack) ->
    answer = []
    answer.push card.id for card in pack
    answer


  @fromString: (str) ->
    deck = new Deck()
    focus = deck.main
    lines = str.split "\n"
    for line in lines
      line = line.trim()
      if line.endsWith 'main'
        focus = deck.main
      else if line.endsWith 'side'
        focus = deck.side
      else if line.endsWith('ex') or line.endsWith('extra')
        focus = deck.ex
      else
        continue if line.startsWith '#'
        id = parseInt line
        focus.push id if id and id > 0
    deck

  @fromFile: (filePath, callback) ->
    fs.readFile filePath, (buffer) ->
      callback @fromString buffer.toStirng()

  @fromFileSync: (filePath) ->
    @fromString fs.readFileSync(filePath).toString()

module.exports = Deck