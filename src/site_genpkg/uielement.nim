
import strutils, sequtils, tables, json, tstore
import karax / [vdom, karaxdsl, kdom]

include karax / prelude
import karax / prelude

import listeners


type
  MessageKind* = enum
    normal, success, warning, error, primary
    
  AppMessage* = ref object
    tilte*, content*: string
    kind*: MessageKind

  AppContext* = ref object of RootObj
    state*: JsonNode
#    components*: Table[string, proc(ctxt: AppContext): UiElement]
    actions*: Table[cstring, proc(payload: JsonNode)]
    ignoreField*: proc(field: string): bool # proc that returns true if the field should be ignored
    labelFormat*: proc(text: string): string
    navigate*: proc(ctxt: var AppContext, payload: JsonNode, viewid: string): JsonNode # returns the new payload
    store*: Store
    queryString*: OrderedTable[string, string]
    route*: string
    messages*: seq[AppMessage]
    eventHandler*: proc(uiev: uielement.UiEvent, el: UiElement, viewid: string): proc(ev: Event, n: VNode)
    eventsMap*: Table[uielement.UiEventKind, EventKind]
    render*: proc()
    
  App* = ref object 
    id*: string
    title*: string
    layout*: proc(ctxt: AppContext): UiElement
    state*: string
    ctxt*: AppContext

  UiElementKind* = enum
    kComponent, kLayout, kHeader, kFooter, kBody, kButton, kDropdopwn, kIcon,
    kLabel, kText, kMenu, kMenuItem, kNavBar, kNavSection, kLink, kInputText,
    kList, kListItem, kForm, kCheckBox, kDropdown, kDropdownItem, kPanel, kTile,
    kTable, kColumn, kRow, kRadio, kRadioGroup, kParagraph, kTitle,kBreadcrum,
    kItem, kHero, kMessage, kLoading

  UiElement* = ref UiElementObj

  UiEventKind* = enum
    click, keydown, keyup

  UiEvent* = object
    kind*: UiEventKind
    targetKind*: EventKind
    handler*: string # a key in the actions table
    
  UiElementObj = object
    elid: string
    parentid: string
    id*: string
    viewid*: string
    kind*: UiElementKind
    label*: string # what is to be shown as label
    value*: string # the value of the field
    objectType*: string # the object type, normaly an entity
    field*: string # the field of the entity
    attributes*: Table[string, string]
    children*: seq[UiElement]
    events*: seq[UiEvent]
    builder*: proc(el: UiElement): Vnode
    ctxt*: AppContext
    preventDefault*: bool

var pid = 0
template genId*: untyped =
  inc(pid)
  pid


proc setElid*(el: var UiElement, parent: UiElement = nil) =
  # get parent id
  # concatenate and and
  if parent != nil:
    el.elid = $parent.elid & "." & $parent.children.len
  else:
    el.elid = $0


proc add*(parent: var UiElement, child: UiElement) =
  var c = child
  c.setElid(parent)
  parent.children.add c
  
  
proc addChild*(parent: var UiElement, child: UiElement) =
  parent.add child

  
proc `$`*(el: UiElement): string =
  result = ""
  result.add "\nelid: " & el.elid
  result.add "\nparentid: " & el.parentid
  result.add "\nid: " & el.id
  result.add "\nkind: " & $el.kind
  result.add "\nlabel: " & el.label
  result.add "\nvalue: " & el.value
  result.add "\nAttributes:" & $el.attributes
  result.add "\nEvents:" & $el.events
  result.add "\nChildren:"
  for c in el.children:
    result.add " " & $c.kind


proc `$`*(ctxt: AppContext): string =
  result = ""
  result.add "\nstate" & $ctxt.state
  result.add "\nqueryString " & $ctxt.queryString
  result.add "\nroute" & $ctxt.route
  result.add "\neventsMap " & $ctxt.eventsMap

  
proc elid*(el: UiElement): string =
  el.elid  


proc addEvents*(n: var Vnode, el: UiElement) =
  let ctxt = el.ctxt
  if not ctxt.isNil:
    for ev in el.events:
      let targetKind = ctxt.eventsMap[ev.kind]
      n.setAttr("eventhandler", ev.handler)    
      let eh = ctxt.eventHandler(ev, el, el.viewid)
      n.addEventListener(targetKind, eh)


proc addAttributes*(n: var Vnode, el: UiElement) =
  if el.id!="": n.id = el.id
  if el.value != "":
    n.setAttr "value", el.value
  for k, v in el.attributes.pairs:
    n.setAttr(k, v)

    
proc hasAttribute*(el: UiElement, attr: string): bool =
  result = el.attributes.haskey attr
  

proc getAttribute*(el: UiElement, key: string): string =
  if el.hasAttribute key:
    result = el.attributes[key]

  
proc setAttribute*(parent: var UiElement, key, value: string) =
  # TODO: handle basic types
  ## if it does not exist it is added
  parent.attributes[key] = value


proc removeAttribute*(parent: var UiElement, key: string) =
  if parent.attributes.haskey(key):
    parent.attributes.del key
  

proc addEvent*(parent: var UiElement, event: UiEvent) =
  ## if it does not exist it is added
  # remove the event and add it again
  var
    indx = 0
    rm = false
  for e in parent.events:
    if event.kind == e.kind:
      rm = true
      break
    indx += 1
  if rm == true: parent.events.delete indx
  parent.events.add event
  

proc newUiElement*(): UiElement =
  result = UiElement()
  result.elid = $genId()


proc newUiElement*(kind: UiElementKind): UiElement =
  result = newUiElement()
  result.kind = kind


proc newUiElement*(kind: UiElementKind, id, label: string): UiElement =
  result = newUiElement()
  result.kind = kind
  if label != "":
    result.label = label     
  if id != "":
    result.id = id

  
proc addEvent*(e: var UiElement, evk: UiEventKind) =
  var ev = UiEvent()
  ev.kind = evk
  e.events.add ev  

  
proc newUiElement*(ctxt: AppContext): UiElement =
  result = UiElement()
  result.ctxt = ctxt
  result.elid = $genId()


proc newUiElement*(ctxt: AppContext, kind: UiElementKind): UiElement =
  result = newUiElement(ctxt)
  result.kind = kind


proc newUiElement*(ctxt: AppContext, kind: UiElementKind, id, label: string): UiElement =
  result = newUiElement(ctxt)
  result.kind = kind
  if label != "":
    result.label = label     
  if id != "":
    result.id = id
    
    
proc newUiElement*(ctxt: AppContext, kind: UiElementKind, id, label="", events: seq[UiEventKind]): UiElement =
  result = newUiElement(ctxt, kind)
  if label != "":
    result.label = label

  if id != "":
    result.id = id
  for evk in events:
    var ev = UiEvent()
    ev.kind = evk
    result.events.add ev

      
proc newUiElement*(ctxt: AppContext, kind: UiElementKind, label="",
                   attributes:Table[string, string], events: seq[UiEventKind]): UiElement =    
  result = newUiElement(ctxt, kind, label = label, events = events)
  result.kind = kind
  result.attributes = attributes    


proc newUiEvent*(k: UiEventKind, handler: string):UiEvent =
  result = UiEvent()
  result.kind = k
  result.handler = handler


# Messages
proc newMessage*(content: string, kind: MessageKind): AppMessage =
  result = AppMessage()
  result.content = content
  result.kind = kind


proc newMessage*(content: string, title=""): AppMessage =
  result = newMessage(content, MessageKind.normal)

  
proc newSuccessMessage*(content: string, title=""): AppMessage =
  result = newMessage(content, MessageKind.success)

  
proc newWarningMessage*(content: string, title=""): AppMessage =
  result = newMessage(content, MessageKind.warning)

  
proc newErrorMessage*(content: string, title=""): AppMessage =
  result = newMessage(content, MessageKind.error)
  

proc newPrimaryMessage*(content: string, title=""): AppMessage =
  result = newMessage(content, MessageKind.primary)


proc addMessage*(ctxt: AppContext, kind: string, content: string,  title="") =
  var msg: AppMessage  
  case $kind
  of "success":
    msg = newSuccessMessage(content, title)
  of "warning":
    msg = newWarningMessage(content, title)
  of "error":
    msg = newErrorMessage(content, title)
  of "primary":
    msg = newPrimaryMessage(content, title)
  else:
    msg = newMessage(content, title)  
  ctxt.messages.add msg

  
proc addMessage*(ctxt: AppContext, m: AppMessage) =
  ctxt.messages.add m


# Main
proc reRender*()=
  # wrap and expose redraw
  `kxi`.redraw()


proc noEventListener(payload: JsonNode, action: string): proc(payload: JsonNode) =
  result = proc(payload: JsonNode) =
    echo "WARNING: Action $1 not found in the table." % $action

  
proc callEventListener(payload: JsonNode,
                        actions: Table[cstring, proc(payload: JsonNode)]) =

  var eventListener: proc(payload: JsonNode)
  var a, model, sitegen_action: string

  let
    nodeKind = payload["node_kind"].getStr
    eventKind = payload["event_kind"].getStr.replace("on", "")
    defaultNodeAction = "default_action_" & nodeKind & "_" & eventKind
  
  if payload.haskey("eventhandler"):
    sitegen_action = payload["eventhandler"].getStr

  else:
    if payload.haskey("model"):
      model = payload["model"].getStr
    if payload.haskey("action"):
      a = payload["action"].getStr
    elif payload.haskey("field"): # field
      a = payload["field"].getStr
      
    sitegen_action = "$1_$2_$3" % [model, a, eventKind]
    
  if actions.hasKey sitegen_action:
    eventListener = actions[sitegen_action]
  elif actions.hasKey defaultNodeAction:
    eventListener = actions[defaultNodeAction]
  elif actions.hasKey "sitegen_default_action":
    # default action
    eventListener = actions["sitegen_default_action"]
  else:
    eventListener = noEventListener(payload, sitegen_action)
  eventListener payload

  
proc eventHandler(uiev: uielement.UiEvent, el: UiElement, viewid: string): proc(ev: Event, n: VNode) =
  let ctxt = el.ctxt
  
  result = proc(ev: Event, n: VNode) =
    
    if el.preventDefault:
      ev.preventDefault()
    let
      evt = ev.`type`
    
    var
      payload = %*{"value": %""}
      event = %*{"type": %($evt)}

    for k, v in n.attrs:
      if k == "model":
        payload["model"] = %($n.getAttr "model") #%model
      if k == "value":
        payload["value"] = %($n.getAttr "value")
      
    # TODO: improve event data passed.
    if not evt.isNil and evt.contains "key":
      event["keyCode"] = %(cast[KeyboardEvent](ev).keyCode)
      event["key"] = %($cast[KeyboardEvent](ev).key)
 
    payload["event"] = event
    
    if n.kind == VnodeKind.input:
      payload["type"] = %($n.getAttr "type")

    if payload.haskey("type") and (payload["type"].getStr == "date" or
                                   payload["type"].getStr == "checkbox"):
      # let the dom handle the events for the `input date`
      discard
    else:
      ev.preventDefault()
          
    payload["node_kind"] = %($n.kind)
    payload["event_kind"] = %uiev.kind
    
    if n.getAttr("action") != nil:
      payload["action"] = %($n.getAttr "action")
      
    if n.getAttr("mode") != nil:
      payload["mode"] = %($n.getAttr "mode")
    
    if n.getAttr("name") != nil:
      payload["field"] = %($n.getAttr "name")

    if n.getAttr("field") != nil:
      payload["field"] = %($n.getAttr "field")
    
    if el.id != "":
      payload["objid"] = %el.id

    if not n.value.isNil and n.value != "":
      payload["value"] = %($n.value)
    
    if payload.haskey "action":
      #payload = ctxt.navigate(ctxt, payload, viewid)
      callEventListener(payload, ctxt.actions)
      reRender()
      
    elif n.getAttr("eventhandler") != nil:
      payload["eventhandler"] = %($n.getAttr "eventhandler")
      callEventListener(payload, ctxt.actions)
  

proc newAppContext*(): AppContext =
  result = AppContext()
  result.render = reRender
  result.eventHandler = eventHandler
  
  for uievk in uielement.UiEventKind:
    for kev in EventKind:
      if $kev == ("on" & $uievk):
        result.eventsMap.add(uievk, kev)
        break
