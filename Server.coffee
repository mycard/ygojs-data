Environment = require './Environment'

module.exports.koaResponse = (ctx, next) ->
  locale = ctx.params.locale
  id = ctx.params.id
  environment = new Environment locale
  return ctx.throw 404, "Can't find environment #{locale}" unless environment
  card = environment[id]
  return ctx.throw 404, "Can't find card #{id} in environment #{locale}" unless card
  body = ctx.request.body
  body = JSON.parse body if typeof body == 'string'
  if body
    card.attribute = environment.attributeName card if body.translateAttribute
    card.race = environment.raceName card if body.translateRace
    card.type = environment.prettyTypeName card if body.translateType
  ctx.response.statusCode = 200
  ctx.body = card

module.exports.expressResponse = (req, res) ->
  locale = req.params.locale
  id = req.params.id
  environment = new Environment locale
  return res.status(404).end "Can't find environment #{locale}" unless environment
  card = environment[id]
  return res.status(404).end "Can't find card #{id} in environment #{locale}" unless card
  body = req.body
  console.log req.body
  body = JSON.parse body if typeof body == 'string'
  if body
    card.attribute = environment.attributeName card if body.translateAttribute
    card.race = environment.raceName card if body.translateRace
    card.type = environment.prettyTypeName card if body.translateType
  res.json card