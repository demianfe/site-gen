# default actions for embeded ui components

import tables, json, strutils
import uielement

proc loadDefaultActions*(app: var App) =
  app.ctxt.actions.add "close_message",
     proc(payload: JsonNode) =
       if payload.haskey("objid"):
         let id = parseInt(payload["objid"].getStr)
         app.ctxt.messages.delete(id)
       app.ctxt.render()
