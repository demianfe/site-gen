
# wrapps around `builder.nim` but uses uielement objects instead of json
import tables, json, strutils
import uuidjs

include karax / prelude
import karax / [kbase, vdom, karaxdsl]

import uielement, builder, ui_utils, uitemplates
import uilib / message

const containersKind = [UiElementKind.kComponent,
                        UiElementKind.kHeader,
                        UiElementKind.kNavBar,
                        UiElementKind.kNavSection]


proc callBuilder(elem: UiElement): VNode =
  var el = elem
  if not el.builder.isNil:
    result = el.builder(elem)
  elif el.kind == UiElementKind.kComponent and el.attributes.len > 0:
    result = buildHtml(tdiv())
    result.addAttributes el

  elif el.kind == UiElementKind.kComponent:
    for kid in el.children:
      result = callBuilder(kid)

  if not result.isNil:
    for elkid in el.children:
      let kid = callBuilder(elkid)
      if not kid.isNil:
        result.add kid


proc buildElement(uiel: UiElement, viewid: string): VNode =
  var el: UiElement = uiel
  try:
    if el.kind in containersKind:
      if not el.builder.isNil:
        result = el.builder(el)
      else:
        result = buildHtml(tdiv())
      result.addAttributes el
      
      for c in el.children:
        let vkid = buildElement(c, viewid)
        if not vkid.isNil:
          result.add vkid
    else:
      if not el.builder.isNil:
        result = callBuilder(el)
        result.addAttributes el
      
  except:
    var msg = ""
    let e = getCurrentException()
    if not e.isNil:
      msg = e.getStackTrace()
    else:
      msg =  getCurrentExceptionMsg()
      
    result = buildHtml(tdiv):
      h4: text "Error -  Element build fail: " & $el.kind
      h6: text getCurrentExceptionMsg()
      p: text msg
    

proc updateUI*(app: var App): VNode =
  var
    state = app.ctxt.state
    view = state["view"]
    viewid = view["id"].getStr
    action: string

  result = newVNode VnodeKind.tdiv
  result.class = "container"
  
  if app.ctxt.messages.len > 0:
    var c = 0
    for m in app.ctxt.messages:
      result.add buildElement(Message(app.ctxt, m.kind, m.content, id= $c), viewid)
      c += 1

  if app.ctxt.route != "":
    let
      sr = app.ctxt.route.split("?")
    if sr.len > 1:
      app.ctxt.route = sr[0]
      let qs = sr[1].split("&")
      for q in qs:
        let kv = q.split("=")
        if kv.len > 1:
          app.ctxt.queryString.add kv[0], kv[1]
        else:
          app.ctxt.queryString.add kv[0], kv[0]
    
    action = app.ctxt.route.replace("#/", "")
    if app.ctxt.actions.haskey action:
      # call action
      var payload = %*{"action": action}   
      app.ctxt.actions[action](payload)

  let h = buildElement(app.layout(app.ctxt), viewid)
  if not h.isNil:
    result.add h

  
proc initApp*(app: var App): VNode =
  result = updateUI(app)
