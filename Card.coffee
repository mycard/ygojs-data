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

  ###
  bool ClientCard::deck_sort_lv(code_pointer p1, code_pointer p2) {
    if((p1->second.type & 0x7) != (p2->second.type & 0x7))
      return (p1->second.type & 0x7) < (p2->second.type & 0x7);
    if((p1->second.type & 0x7) == 1) {
      int type1 = (p1->second.type & 0x48020c0) ? (p1->second.type & 0x48020c1) : (p1->second.type & 0x31);
      int type2 = (p2->second.type & 0x48020c0) ? (p2->second.type & 0x48020c1) : (p2->second.type & 0x31);
      if(type1 != type2)
        return type1 < type2;
      if(p1->second.level != p2->second.level)
        return p1->second.level > p2->second.level;
      if(p1->second.attack != p2->second.attack)
        return p1->second.attack > p2->second.attack;
      if(p1->second.defense != p2->second.defense)
        return p1->second.defense > p2->second.defense;
      return p1->first < p2->first;
    }
    if((p1->second.type & 0xfffffff8) != (p2->second.type & 0xfffffff8))
      return (p1->second.type & 0xfffffff8) < (p2->second.type & 0xfffffff8);
    return p1->first < p2->first;
  }
  ###
  @deckSortLevel: (p1, p2) ->
    return (p1.type & 0x7) - (p2.type & 0x7) if (p1.type & 0x7) != (p2.type & 0x7)
    if (p1.type & 0x7) == 1
      type1 = if (p1.type & 0x48020c0) then (p1.type & 0x48020c1) else (p1.type & 0x31)
      type2 = if (p2.type & 0x48020c0) then (p2.type & 0x48020c1) else (p2.type & 0x31)
      return type1 - type2 if type1 != type2
      return p1.level - p2.level if p1.level != p2.level
      return p1.atk - p2.atk if p1.atk != p2.atk
      return p1.def - p2.def if p1.def != p2.def
      return 0
    return (p1.type & 0xfffffff8) - (p2.type & 0xfffffff8) if (p1.type & 0xfffffff8) != (p2.type & 0xfffffff8)
    return 0

  attributeText: (env) ->
    return null unless @isTypeMonster
    env.attributes.filter((attribute) => attribute.value & @attribute).map((attribute) => attribute.text).join("/")

  raceText: (env) ->
    return null unless @isTypeMonster
    env.races.filter((race) => race.value & @race).map((race) => race.text).join("/")

  typeText: (env) ->
    types = {}
    env.types.forEach (type) => types[type.name] = type
    monster = ['fusion', 'ritual', 'synchro', 'xyz', 'link', 'pendulum', 'normal', 'dual', 'spirit', 'union', 'tuner', 'flip', 'toon', 'spsummon', 'effect']
    spell = ['normal', 'ritual', 'quickplay', 'continuous', 'field', 'equip']
    trap = ['normal', 'continuous', 'counter']
    type = @type
    prefix = (names) => types[names.filter((name) => types[name].value & type)[0]]?.text
    if @isTypeMonster then monster.map((name) => types[name]).filter((type) => type.value & @type).map((type) => type.text).join("/")
    else if @isTypeSpell then (prefix(spell) ? types.normal.text) + types.spell.text
    else if @isTypeTrap then (prefix(trap) ? types.normal.text) + types.trap.text
    else ''

  @numText: (num) ->
    switch(num)
      when undefined then ""
      when -1 then "?"
      when -2 then "∞"
      else num.toString()

  atkText: -> Card.numText @atk
  defText: -> Card.numText @def 

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