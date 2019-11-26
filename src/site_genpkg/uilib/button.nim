
import ../uielement

import tables
import karax / [vdom, karaxdsl]


proc buildButton(el: UiElement): Vnode =
  result = buildHtml button(class="btn"): text el.label  
  result.addAttributes el
  result.addEvents el


proc Button*(ctxt: AppContext, label: string): UiElement =
  result = newUiElement(ctxt, UiElementKind.kButton, label=label, events = @[UiEventKind.click])
  result.builder = buildButton
