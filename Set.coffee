
class Set
  constructor: (code, name, parent) ->
    @code = code
    @name = name
    @parent = parent
    @originName = null
    @ids = null
    @separateOriginNameFromName()

  separateOriginNameFromName: ->
    names = @name.split "\t"
    return false if names.length <= 1
    @originName = names[1]
    @name = names[0]
    true

  includes: (card) ->
    id = (Number.isInteger(card)) ? card : card.id
    @ids = @parent.searchSetByNumber @number unless @ids
    @ids.includes id