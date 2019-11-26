
import karax / [vdom, kdom, karaxdsl]

import site_genpkg / [uielement]
import site_genpkg / uilib / [baseui, button]


proc builder(el: UiElement): VNode =
  result = buildHtml tdiv(class="toast"): text el.value
  result.addAttributes el
  
  
proc Message*(ctxt: AppContext, text: string, title, class, id = ""): UiElement =
  result = newUiElement(UiElementKind.kMessage)
  result.value = text
  result.builder = builder
  
  if class == "":
    result.setAttribute "class", "toast"
  else:
    result.setAttribute "class", "toast " & class
  
  if title != "":
    result.label = title
    
  var b = Button(ctxt, "")
  if id != "": b.id = id
  b.addEvent newUiEvent(UiEventKind.click, "close_message")
  b.setAttribute("class", "btn btn-clear float-right")
  result.add b

  
proc SuccessMessage*(ctxt: AppContext, text: string, title, id=""): UiElement =
  result = Message(ctxt, text, title, "toast-success", id)

  
proc WarningMessage*(ctxt: AppContext, text: string, title, id=""): UiElement =
  result = Message(ctxt, text, title, "toast-warning", id)

  
proc ErrorMessage*(ctxt: AppContext, text: string, title, id=""): UiElement =
  result = Message(ctxt, text, title, "toast-error", id)


proc PrimaryMessage*(ctxt: AppContext, text: string, title, id=""): UiElement =
  result = Message(ctxt, text, title, "toast-primary", id)


proc Message*(ctxt: AppContext, kind: MessageKind, text: string, title, id = ""): UiElement =
  
  case kind
  of MessageKind.success:
    result = SuccessMessage(ctxt, text, title=title, id=id)

  of MessageKind.warning:
    result = WarningMessage(ctxt, text, title=title, id=id)

  of MessageKind.error:
    result = ErrorMessage(ctxt, text, title=title, id=id)
    
  of MessageKind.primary:
    result = PrimaryMessage(ctxt, text, title=title, id=id)
    
  else:
    result = Message(ctxt, text, title, id=id)
  

    
