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
  get: -> @isTypeSynchro or @isTypeXyz or @isTypeFusion or @isTypeLink

Object.defineProperty Card.prototype, 'level',
  get: -> @originLevel % 65536

Object.defineProperty Card.prototype, 'pendulumScale',
  get: ->
    if @isTypePendulum
      (@originLevel - (@originLevel % 65536)) / 65536 / 257
    else
      -1

Object.defineProperty Card.prototype, 'linkMarkers',
  get: ->
    if @isTypeLink
      str = @def.toString(2)
      str = '0' * (9 - str.length) + str
      return [0..8].map (i) -> str[8 - i] == '1'
    else
      null

Object.defineProperty Card.prototype, 'linkNumber',
  get: -> if @isTypeLink then @level else -1

module.exports = Card