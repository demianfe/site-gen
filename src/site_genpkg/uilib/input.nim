
import tables
import karax / [kdom, vdom, karaxdsl, karax]

import ../uielement


proc buildInputText*(wb: WebBuilder, el: UiElement): Vnode =
  result = buildHtml tdiv(class="form-group")
  var
    label = buildHtml label(class = "form-label", `for`= el.id): text el.label
    input = buildHtml input(`type`= "text", class = "form-input", objid = el.id, placeholder = el.label)

  setInputText input, el.value
  input.addAttributes el
  input.addEvents wb, el
  
  result.add label
  result.add input


proc InputText*(id, label = ""): UiElement =
  result = newUiElement(UiElementKind.kInputText, events = @[UiEventKind.keyup])
  result.setAttribute("type", "text")
  result.label = label
  result.id = id
  result.builder = buildInputText
