
import json, strutils
import  ../uielement, ../uilib, ../tstore


# TODO: call label gen

proc UiEdit*(ctxt: AppContext, viewid, route: string): UiElement =
  let entity = route.replace("#/", "")
  result = newUiElement()
  result.kind = UiElementkind.kComponent

  var
    current = ctxt.store.getCurrent entity
    form = Form()
  
  # add form and inputs for  each field
  for k,v in current.data:
    if v.kind == JString:
      # add input text
      var inputTxt = InputText(ctxt, label = k)
      inputTxt.setAttribute("model", current.`type`)
      inputTxt.setAttribute("name", k)
      inputTxt.value = v.getStr
      inputTxt.id = current.id   
      form.addChild inputTxt
  
  form.addChild Button(ctxt, "Save")
  result.addChild form
  
