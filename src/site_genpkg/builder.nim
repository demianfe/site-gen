
import strutils, unicode

import json, tables, jsffi, sequtils
include karax / prelude 
import karax / prelude
import karax / [errors, kdom, vstyles]

import uuidjs


var defaultEvent: proc(name, id: string): proc(ev: Event, n: VNode)

# global variable that holds all components
var appState, data, components: JsonNode

type
  Sections = enum
    header, menu, body, footer


proc toJson*(component: VNode): JsonNode =
  ## returns a JsonNode from a VNode
  result = %*{ "ui-type": $component.kind }
             
  # if component.getAttr("compnent_id") != nil:
  #   result["component_id"] = %($component.getAttr("compnent_id"))
  # else:
  #   result["component_id"] = %genUUID()
  
  if component.class != nil: result["class"] = %($component.class)
  if component.text != nil or component.value != nil:
    if component.kind == VNodeKind.input:
      # `value` and `text` overlap on input componets
      result["value"] = %($component.value)
    else:
      result["text"] = %($component.text)

  var attributes = %*{}
  for k,v in component.attrs:
    attributes.add($k,%($v))
  if attributes.len > 0: result["attributes"] = attributes
                           
  var children = newJArray()
  for c in component.items:
    children.add(toJson(c))
  if children.len > 0: result["children"] = children
    
  var events = newJArray()
  for ev in component.events:
    events.add(%($ev[0]))
  if events.len > 0: result["events"] = events

    
proc updateValue(vn: var VNode) =
  # TODO: handle exceptions when de name of the model is not an object
  var value: string
  if not data.isNil:
    let
      modelName = vn.getAttr("model")
      field = vn.getAttr("name")
      
    if not modelName.isNil and not field.isNil:
      if data.hasKey($modelName) and data[$modelName].hasKey("current"):
        let current = data[$modelName]["current"]
        if $field != "id" and current.haskey($field):
          if vn.kind == VnodeKind.input:
            setInputText(vn, current[$field].getStr)
          
          
proc buildComponent*(params: JsonNode): VNode =
  ## builds a component based on a json definition
  var nodeKind: VNodeKind

  for vnk in VNodeKind:
    if params.hasKey("ui-type"):
      if $vnk == params["ui-type"].getStr:
        nodeKind = vnk
        break
    else:
      # TODO raise error.
      echo "Error: component not found"
      break
    
  if nodeKind == VNodeKind.text:
    # text kind has its own constructor
    result = text(params["text"].getStr)
  else:
    result = newVNode(nodeKind)

  if params.hasKey("id"):
    result.setAttr("id", params["id"].getStr)
  # else:
  #   result.setAttr("id", genUUID())
  
  if nodeKind == VNodeKind.label and params.hasKey("text"):
    result.add text(params["text"].getStr)
  if nodeKind == VNodeKind.form:
    result.addEventListener(EventKind.onsubmit,
                              proc(ev: Event, n: Vnode) =
                                ev.preventDefault())
  if params.hasKey("class"):
    result.class = params["class"].getStr

  if params.hasKey("attributes"):
    for k, v in params["attributes"].fields:
      result.setAttr(k, v.getStr)

  if params.hasKey("model"):
    result.setAttr("model", params["model"].getStr)

  if params.hasKey("name"):
    result.setAttr("name", params["name"].getStr)

  if params.hasKey("dataListener"):
    result.setAttr("dataListener", params["dataListener"].getStr)
  
  if params.hasKey("events"):
    # TODO: improve
    # if the component does not have a name quit with a message
    let events = params["events"]
      
    for evk in EventKind:
      if events.contains(%($evk)):
        # FIXME: the way events are named and referenced is too simple
        # it will colide if the same model is used in another part of
        let actionName = "$1_$2_$3" % [$result.getAttr("model"), $result.getAttr("name"), $evk]
        var id = result.getAttr("id")
        if id.isNil: id = ""
        result.addEventListener(evk, defaultEvent(actionName, $id))
      #else:
      #  echo "WARNING: event ", $evk, " does not exists." 
  updateValue(result)
  if params.hasKey("children"):
    for child in params["children"].getElems:
      result.add(buildComponent(child))
  

proc formGroup(def: JsonNode): JsonNode =
  result = copy components["formGroup"]  
  var component: JsonNode
  let uiType = $def["ui-type"].getStr  
  if components.haskey(uiType):
    component = copy components[uiType]
  else:    
    if uiType == "check":
      component = copy components["checkbox"]
    elif uiType == "text":
      component = copy components["textarea"]
    elif uiType == "input":
      component = copy components["input"]
    else:
      # TODO: raise error
      echo "Error: ui-type ", uiType, "not found."

  #component["component_id"] = %genUUID()

  if def.hasKey("events"):
    # add events to component we are preparing
    component["events"] = copy def["events"]    
  if def.hasKey("name"):
    component["name"] = copy def["name"]
  if def.hasKey("model"):
    component["model"] = copy def["model"]

  result["children"][0]["text"] = %(def["label"].getStr & ":")
  result["children"][0]{"attributes","for"} = component["name"]
  result["children"].add(component)

  
proc edit(formDef: JsonNode): JsonNode =  
  var form = %*{
    "ui-type": "form",
    "name": formDef["name"],
    "model": formDef["model"]
  }
  
  form["children"] = newJArray()  
  
  for k1, v1 in formDef.getFields:
    if k1 == "children":
      for item in v1.getElems:
        var child: JsonNode
        item["model"] = formDef["model"]
        if item["ui-type"].getStr == "button":
          # just build it
          child = copy components["button"]
          # add the label or text as child so it can be displayed on the button
          child["model"] = formDef["model"]
          child["name"] = copy item["name"]
          child["events"] = copy item["events"]
          child["children"][0]["text"] = item["label"]
        else:
          # if item is input use formGroup
          child = formGroup(item)
        form["children"].add(child)
  form

          
proc list(def: JsonNode): JsonNode =
  # TODO: inform when theres no data
  # use data to create the list
  
  let modelName = def["model"].getStr
  if appState.haskey("store") and appState["store"]["objects"][modelName].hasKey("list"):
    var modelList = %[]
    for objId in appState["store"]["objects"][modelName]["list"]:
      modelList.add appState["store"]["data"][objId.getStr]

    #echo modelList.pretty
    result = %{"ui-type": %"div",
                "attributes": %*{"class": %"container"},
                "children": %[]}
    result = %*{
      "ui-type": "table",
      "attributes": %*{"class": %"table"},
      "children": %[]
    }
    
    var row = %*{
        "ui-type": %"tr",
        "children": %[]
      }  
    # TODO: extract field names and use it as column headers
    # Header
    var tr = copy row
    
    for k, v in modelList[0].getFields:
      # create header
      var th = %*{
          "ui-type": %"th",
          "attributes": %*{"scope": %"col"},
          "children": %[
            %*{
              "ui-type": "#text",
              "text": %(capitalize k)
            }
          ]
        }

      tr["children"].add th
    result["children"].add %{"ui-type": %"thead", "children": %[tr]}
    var tbody = %*{"ui-type": %"tbody", "children": %[]}
    
    for elem in modelList.getElems:
      # each item in one row
      var tr = copy row
      for k, v in elem.getFields:
      # each row will contain: fields values and buttons of edit/delete
      # iterte over fields  
        var cellVal = v.getStr
        var cell = %*{
          "ui-type": %"td",
          "children": %[
            %*{
              "ui-type": "#text",
              "text": %cellVal
            }
          ]
        }

        if k == "id":
          cell["ui-type"] = %"th"
          cell["attributes"] = %*{"scope":"row"}
                                 
        tr["children"].add cell

      var editButton = copy components["button"]
      editButton["children"][0]["text"] = %"Edit"
      editButton["events"] = %["onclick"]
      editButton["id"] = elem["id"]
      editButton["attributes"]= %*{
        "model": %modelName,
        "name": %("edit")
      }
      tr["children"].add(editButton)
      
      var deleteButton = copy components["button"]
      deleteButton["children"][0]["text"] = %"Delete"
      deleteButton["events"] = %["onclick"]
      deleteButton["id"] = elem["id"]
      deleteButton["attributes"]= %*{
        "model": %modelName,
        "name": %("delete")
      }
      tr["children"].add deleteButton
      tbody["children"].add tr
      
    result["children"].add tbody

  
proc buildHeader(def: JsonNode): VNode =
  var h = copy components["header"]
  # WARNING: hardcoded
  h["children"][0]["children"][0]["children"][0]["children"][0]["children"][0]["text"] = def["alternative"]
  result = buildComponent(h)


proc buildBody(action: string, bodyDefinition: var JsonNode): VNode =
  # builds the initial ui based on the definition and the components library
  # this part should understand and comply with the component definition specification  
  var def = bodyDefinition
  result = newVNode(VnodeKind.tdiv)
  result.class = "container"

  case action
  of "edit":
    var
      editForm = buildComponent(edit(def))
      h3 = newVNode(VNodeKind.h3) # default heading file should come from configuration
      label = ""
      
    if def.hasKey "label": label = def["label"].getStr
    else: label = "Edit " & capitalize(def["model"].getStr)
    
    h3.add text(label)
    editForm.insert(h3, 0)
    # preventing default submision
    editForm.addEventListener(EventKind.onsubmit,
                              proc(ev: Event, n: Vnode) =
                                ev.preventDefault())
    #elem["component_id"] = %($editForm.getAttr("component_id"))
    result.add(editForm)
  of "list":
    result.add buildComponent(list(def))
  of "gird":
    #TODO:
    echo "TODO: create a grid"
  else:
    # look up in the components table and try to build it
    discard
    # var compDef = copy components[k]
    # let c = buildComponent(compDef)
    # result.add(c)

  
proc updateUIRaw*(state: JsonNode): VNode =
  # builds the vdom tree using the ui attribute
  if state.hasKey("data"):
    data = state["data"]
  result = buildComponent(state["ui"])

  
proc updateUI*(state: var JsonNode): VNode =
  var
    uiDef = state["definition"]
    definition = uiDef

  if state.hasKey("data"):
    data = state["store"]

  var route, action: string
  if appState.hasKey("route") and appState["route"].getStr != "":
    let splitRoute = appState["route"].getStr.split("/")
    # just asume first item is `#`.
    # use `#` in the ui definition to know it is a route.
    route = splitRoute[0..1].join("/")
    if splitRoute.len > 2: action = splitRoute[2]

  result = newVNode(VnodeKind.tdiv)
  for section in Sections:
    var sectionDef = uiDef[$section]
    case $section
    of "body":
      var routeSec: JsonNode
      if action == "": routeSec = sectionDef[route]
      else: routeSec = sectionDef[route][action]
      result.add buildBody(action, routeSec)
    of "header":
      result.add buildHeader(sectionDef)
    of "menu":
      var uiType = sectionDef["ui-type"].getStr
      if not components.hasKey(uiType):
        uiType = "menu"
      result.add buildComponent(components[uiType])
    else:
      if components.hasKey($section):
        result.add buildComponent(components[$section])

    
proc initApp*(state: var JsonNode,
              event: proc(name, id: string): proc(ev: Event, n: VNode)): VNode =    
  let definition = state["definition"]
  appState = state
  components = state["components"]
  defaultEvent = event  
  result = updateUI state
