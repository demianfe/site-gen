
import sequtils, tables, json
import karax / vdom
#import appcontext

when defined(js):
  import karax / kdom

type
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
    
  WebBuilder* = object
   eventsMap*: Table[uielement.UiEventKind, EventKind]
   handler*: proc(uiev: uielement.UiEvent, el: UiElement, viewid: string): proc(ev: Event, n: VNode)
   builder*: proc(wb: WebBuilder, el: UiElement): VNode
    
  UiElementObj* = object
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
    builder*: proc(wb: WebBuilder, el: UiElement): Vnode
    #builder*: proc(el: UiElement): Vnode
    # builder*: proc(ctxt: AppContext, el: UiElement): Vnode
    
proc addChild*(parent: var UiElement, child: UiElement) =
  parent.children.add child


proc add*(parent: var UiElement, child: UiElement) =
  parent.children.add child


proc build*(wb: WebBuilder, el: UiElement): VNode =
  result = wb.builder(wb, el)

  
proc `$`*(el: UiElement): string =
  result = "id: " & el.id
  result.add "\nkind: " & $el.kind
  result.add "\nlabel: " & el.label
  result.add "\nvalue: " & el.value
  result.add "\nAttributes:" & $el.attributes
  result.add "\nEvents:" & $el.events
  result.add "\nChildren:"
  for c in el.children:
    result.add " " & $c.kind

proc newWebBuilder*(handler: proc(uiev: uielement.UiEvent,
                                  el: UiElement, viewid: string): proc(ev: Event, n: VNode)): WebBuilder =
  result = WebBuilder()
  result.handler = handler  
  for uievk in uielement.UiEventKind:
    for kev in EventKind:
      if $kev == ("on" & $uievk):
        result.eventsMap.add(uievk, kev)
        break

  
proc addEvents*(n: var Vnode, wb: WebBuilder, el: UiElement) = 
  for ev in el.events:
    let targetKind = wb.eventsMap[ev.kind]
    n.setAttr("eventhandler", ev.handler)
    n.addEventListener(targetKind, wb.handler(ev, el, el.viewid))


proc addAttributes*(n: var Vnode, el: UiElement) =
  if el.id!="": n.id = el.id
  if el.value != "":
    n.setAttr "value", el.value
#   if el.field != "":
#     n.setAttr "field", el.field
#   for k, v in el.attributes.pairs:
#     n.setAttr(k, v)

    
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
  

proc addEvent*(e: var UiElement, evk: UiEventKind) =
  var ev = UiEvent()
  ev.kind = evk
  e.events.add ev  


proc newUiElement*(): UiElement =
   result = UiElement()


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
    
    
proc newUiElement*(kind: UiElementKind, id, label="", events: seq[UiEventKind]): UiElement =
  result = newUiElement(kind)
  if label != "":
    result.label = label

  if id != "":
    result.id = id
  for evk in events:
    var ev = UiEvent()
    ev.kind = evk
    result.events.add ev

      
proc newUiElement*(kind: UiElementKind, label="",
                   attributes:Table[string, string], events: seq[UiEventKind]): UiElement =    
  result = newUiElement(kind, label = label, events = events)
  result.kind = kind
  result.attributes = attributes    


proc newUiEvent*(k: UiEventKind, handler: string):UiEvent =
  result = UiEvent()
  result.kind = k
  result.handler = handler
