koa = require 'koa'
router = require 'koa-router'
parser = require 'koa-bodyparser'
Environment = require './Environment'

server = new koa()
router = new router()

server.use parser()

router.all '/:locale/:id', (ctx, next) ->
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

server
  .use router.routes()
  .use router.allowedMethods()

module.exports.startServer = (port) ->
  server.listen port