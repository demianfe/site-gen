
import json, tables, jsffi, strutils, times

include karax / prelude
import karax / prelude
import karax / [vdom, karaxdsl, kdom]

import uuidjs

import builder, ui_utils, ui_def_gen, listeners, navigation, appcontext
export builder, ui_utils

import uielement, uibuild, uiactions

import components / components
export components

var console {. importc, nodecl .}: JsObject

var
  initialized = false
  prevHashPart: cstring
  ctxt: AppContext
  app: App
      
          
proc setHashRoute(rd: RouterData) =
  if prevHashPart != $rd.hashPart:
    ctxt.route = $rd.hashPart
    ctxt.state["route"] = %($rd.hashPart)
    prevHashPart = $rd.hashPart
  elif $prevHashPart != ctxt.route:
    window.location.href = cstring(ctxt.route)
    prevHashPart = window.location.hash  


proc showError(): VNode =
  result = buildHtml(tdiv(class="container")):
    tdiv(class="alert alert-danger",role="alert"):
      h3:
        text "Error:"
      p:
        text ctxt.state["error"].getStr
      a(href="#/home"):
        text "Go back home."
  ctxt.state.delete("error")
  reRender()


proc initNavigation() =
  ctxt.route = $window.location.hash
  ctxt.state["route"] = %($window.location.hash)
  prevHashPart = window.location.hash
  # init history
  let vid = genUUID()
  ctxt.state{"history", vid} = %*{"id": %vid, "action": ctxt.state["route"]}
  ctxt.state["view"] = %*{"id": %vid}


proc handleCreateDomException(): Vnode =
  let e = getCurrentException()
  var msg: string
  if not e.isNil:
    msg = e.getStackTrace()
    echo("===================================== ERROR ===================================")
    echo getCurrentExceptionMsg()
    echo(msg)
    echo("================================================================================")
  else:
    echo getCurrentExceptionMsg()
    msg = "Builder Error: Something went wrong."
    ctxt.state["error"] = %msg
    result = showError()


# uses app instead of ctxt
proc createAppDOM(rd: RouterData): VNode =
  setHashRoute(rd)
  try:
    if ctxt.state.hasKey("error"):
      result = showError()
      
    elif app.state == "ready":
      result = updateUI(app)
            
    elif app.state == "loading":
      echo "Loading..."
      result = buildHtml(tdiv()):
        p:
          text "Loading Site..."

      result = initApp(app)
      app.state = "ready"
      
    else:
      # TODO: show invalid state error
      echo "App invalid state."
      
  except:
    result = handleCreateDomException()


proc createApp*(a: var App) =
  app = a
  ctxt = app.ctxt 
  initNavigation()
  `kxi` = setRenderer(createAppDOM)
  # embeded actions
  loadDefaultActions(app)

