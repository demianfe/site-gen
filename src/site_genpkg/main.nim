
import json, tables, jsffi, strutils, times

include karax / prelude 
import karax / prelude
import karax / [vdom, karaxdsl, errors, kdom, vstyles]

import requestjs, uuidjs

import builder, ui_utils, ui_def_gen, listeners
export builder, ui_utils


var console {.importcpp, noDecl.}: JsObject 

# global variables
const
  HEADERS        = [(cstring"Content-Type", cstring"application/json")]
  COMPONENTS_URL ="/components.json"
  DEFINITION_URL = "/definition.json"
  MODEL_URL      = "/auto/schema" #"/model.json"
  

var
  initialized = false
  `kxi`: KaraxInstance
  appState: JsonNode
  actions: Table[cstring, proc(payload: JsonNode){.closure.}]
  dataListeners: Table[cstring, cstring]
  prevHashPart: cstring


# # TODO: move all loading
# proc parseJsonDefintion(resp: string): JsonNode = 
#   try:
#     result = parseJson($resp)
#   except:
#     # TODO: Show error component
#     let msg = getCurrentExceptionMsg()
#     appState["error"] = %msg
#     echo "Error with message \n", msg

# proc loadDefinition(appState: JsonNode) =
#   ajaxGet(DEFINITION_URL,
#           HEADERS,
#           proc(stat:int, resp:cstring) =
#             appState["definition"] = parseJsonDefintion($resp)
#             # update the definition using the model
#             updateDefinition(appState)
#             # finally we redraw when we have everything loaded
#             `kxi`.redraw()
#   )
# proc processSchema(schema: JsonNode) =
#   ## Adapts the schema to the ui data model
#   var model = %*{}
#   for tab in schema.getElems:
#     let tableName = tab["name"].getStr
#     model[tableName] = %*{"columns": %[]}
#     for c in tab["columns"].getElems:
#       # use column["type"]
#       let columnName = c["name"].getStr
#       model[tableName][columnName] = %"string"
#       appState["model"] = model
# proc loadModel(appState: JsonNode) =
#   ajaxGet(MODEL_URL,
#           HEADERS,
#           proc(stat:int, resp:cstring) =            
#             if stat == 200:
#               processSchema(parseJsonDefintion($resp))
#             loadDefinition(appState)            
#   )  
# proc loadComponents(appState: JsonNode) =
#   ajaxGet(COMPONENTS_URL,
#           HEADERS,
#           proc(stat:int, resp:cstring) =
#             let components = parseJsonDefintion($resp)
#             if appState.hasKey("components"):
#               # merge components
#               for k, v in components.getFields:
#                 if not appState["components"].hasKey(k):
#                   # use components defined by the user if names colide
#                   appState{"components", k}= v
#             else:
#               appState["components"] = components
#             loadModel(appState))


proc updateData(n: VNode) =
  if not n.value.isNil:
    let 
      model = $n.getAttr "model"
      field = $n.getAttr "name"

    if not appState.hasKey("data"):
      appState.add("data", %*{})
    if not appState["data"].hasKey(model):
      appState["data"].add(model, %*{})
    # update the value
    appState["data"][model].add($field, %($n.value))

  
proc reRender*()=
  # wrap and expose redraw
  `kxi`.redraw()

    
proc eventGen*(eventKind: string, id: string = ""): proc(ev: Event, n: VNode) =  
  result = proc (ev: Event, n: VNode) =
    ev.preventDefault()
    var payload = %*{}
    #payload["ui"] = appState["ui"] # pass the ui status, should be cached
    # FIXME: the way events are named and referenced is too simple
    # it will colide if the same model is used in another part of
    payload["model"] = %($n.getAttr "model")
    payload["node_name"] = %($n.getAttr "name")
    payload["node_kind"] = %($n.kind)
    payload["event_kind"] = %eventKind
    # ignoring the id of the vnode, use component_id for internal reference
    if id != "": payload["id"] = %id # the id of the component
    if n.value != nil:
      payload["value"] = %($n.value)
    
    callEventListener(payload, actions)
    #appState["ui"] = payload["ui"]
    updateData(n)  
    reRender()
  

proc bindDataListeners() =
  # binds a ui component id to a proc  
  appState.add("dataListeners", %*{})
  for component in findElementsByAttrKey(appState["ui"], "dataListener"):
    let dl = component["attributes"]["dataListener"]
    appState["dataListeners"].add(dl.getStr, component["id"])


proc navigate(rd: RouterData) =
  if prevHashPart != $rd.hashPart:
    appState["route"] = %($rd.hashPart)
    prevHashPart = $rd.hashPart
  elif $prevHashPart != appState["route"].getStr:
    window.location.href = cstring(appState["route"].getStr)
    prevHashPart = window.location.hash

    
proc initNavigation() =
  appState["route"] = %($window.location.hash)
  prevHashPart = window.location.hash

    
proc createDOM(rd: RouterData): VNode =
  navigate(rd)
  
  if appState.hasKey("error"):
    result = buildHtml(tdiv()):
      p:
        text appState["error"].getStr
    appState.delete("error")
    
  elif initialized:
    result = updateUI(appState)
    appState["ui"] = result.toJson
    
  elif not appState.hasKey("definition"):
    #loadComponents(appState)
    result = buildHtml(tdiv()):
      p:
        text "Loading Site..."

  else:
    let started = now()
    echo " -- Initializing $1 --" % $started.nanosecond
    result = initApp(appState, eventGen)
    appState["ui"] = result.toJson
    bindDataListeners()
    let ended = now()
    echo " -- Initialized $1 --" % $ended.nanosecond
    echo "Initialization time: $1 " % $(ended - started)
    initialized = true


proc createApp*(state: JsonNode,
                a: Table[cstring, proc(payload: JsonNode){.closure.}]) =  
  actions = a
  appState = state
  initNavigation()
  `kxi` = setRenderer(createDOM)
