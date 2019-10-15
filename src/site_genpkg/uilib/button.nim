
import ../uielement

import tables
import karax / [vdom, karaxdsl]


proc buildButton(wb: WebBuilder, el: UiElement): Vnode =
  result = buildHtml button(class="btn"): text el.label  
  result.addAttributes el
  result.addEvents wb, el

# proc buildButton(el: UiElement): Vnode =
#   result = buildHtml button(class="btn"): text el.label  
#   result.addAttributes el
#   result.addEvents el

proc Button*(label: string): UiElement =
  result = newUiElement(UiElementKind.kButton, label=label, events = @[UiEventKind.click])
  result.builder = buildButton
