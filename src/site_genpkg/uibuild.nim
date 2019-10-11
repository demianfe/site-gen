
# wrapps around `builder.nim` but uses uielement objects instead of json
import tables, json, strutils
import uuidjs

include karax / prelude
import karax / [kbase, kdom, vdom, karaxdsl]

import uielement, builder, ui_utils, uitemplates
import uilib / message
# complex components
import components / uiedit
import uibuild / builders


var wb: WebBuilder
const containersKind = [UiElementKind.kComponent, UiElementKind.kHeader,
                        UiElementKind.kNavBar, UiElementKind.kNavSection]


proc toJson(e: UiElement): JsonNode = 
  case e.kind:
    of UiElementKind.kButton:
      result = copy templates["button"]
      result.setAttribute("class", "btn")
      result.setText e.label

    of UiElementKind.kText:
      result = %*{"ui-type": %"#text", "text": %e.label}
    else:
      # TODO:
      echo "Error: Unoknown kind."
  for ev in e.events:
    result.addEvent "on" & $ev
  for c in e.children:
    result.addChild c.toJson()


proc buildElement(uiel: UiElement, viewid: string): VNode =
  var el: UiElement = uiel
  try:
    if el.kind in containersKind:
      if not el.builder.isNil:
        result = el.builder(wb, el)
      else:
        result = buildHtml(tdiv())
      result.addAttributes el
      
      for c in el.children:
        let vkid = buildElement(c, viewid)
        if not vkid.isNil:
          result.add vkid
    else:
      if not el.builder.isNil:
        result = wb.callBuilder(el)
        result.addAttributes el
      
  except:
    # TODO:
    var msg = ""
    let e = getCurrentException()
    if not e.isNil:
      msg = e.getStackTrace() #getCurrentExceptionMsg()
    else:
      msg =  getCurrentExceptionMsg()
      
    echo msg
    result = buildHtml(tdiv):
      h4: text "Error -  Element build fail: " & $el.kind
      h6: text getCurrentExceptionMsg()
      p: text msg
    
  
        
proc buildBody(body: UiElement, viewid, route: string): VNode =    
  result = buildElement(body, viewid)

   
proc updateUI*(app: var App): VNode =
  var
    state = app.ctxt.state
    view = state["view"]
    viewid = view["id"].getStr
    route, action: string
    req = Request()
      
  result = newVNode VnodeKind.tdiv
  result.class = "container"
  
  if app.ctxt.messages.len > 0:
    var c = 0
    for m in app.ctxt.messages:
      result.add buildElement(Message(m.kind, m.content, id= $c), viewid)
      c += 1
  
  if state.hasKey("route") and state["route"].getStr != "":
    let
      sr = state["route"].getStr.split("?")

    if sr.len > 1:
      let qs = sr[1].split("&")
      for q in qs:
        let kv = q.split("=")
        if kv.len > 1:
          req.queryString.add kv[0], kv[1]
        else:
          req.queryString.add kv[0], kv[0]

    app.ctxt.request = req
    # grab the first part of the route
    if sr[0].find("/") == 1:
      let splitRoute = sr[0].split "/"
      echo splitRoute
      # just asume first item is `#`.
      # use `#` in the ui definition to know it is a route.
      route = splitRoute[0..1].join "/"
      if splitRoute.len > 2: action = splitRoute[2]
    else:
      action = sr[0]
      
  for l in app.layout.children:
    var el = l
    el.viewid = viewid    
    case l.kind:
      of UiElementKind.kHeader:
        let h = buildElement(l, viewid)
        if not h.isNil:
          result.add h
        
      of UiElementKind.kBody:
        case action
        of "edit":
          echo route, "/", action
          # uiedit
          let ui = UiEdit(app.ctxt, viewid, route)
          result.add buildBody(ui, viewid, route)
        else:
          let cName = route.replace("#/", "")
          if app.ctxt.uicomponents.haskey cName:
             let ui = app.ctxt.uicomponents[cName](app.ctxt)
             result.add buildBody(ui, viewid, route)
             result.addAttributes el
                       
          elif app.ctxt.actions.haskey cName:
            app.ctxt.actions[cName](%*{"querystring": req.queryString})
          else:
            echo "nothing to build."
            
      else:
        # TODO:
        echo "Error: Invalid Layout section."


proc initApp*(app: var App, event: proc(uiev: uielement.UiEvent, el: UiElement, viewid: string): proc(ev: Event, n: VNode)): VNode =
  wb = initBuilder(event)
  result = updateUI(app)
    
