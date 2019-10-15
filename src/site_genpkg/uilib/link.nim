
import karax / [kdom, vdom, karaxdsl]

import baseui
import site_genpkg / uielement


proc buildLink(wb: WebBuilder, el: UiElement): Vnode =
  let action = el.getAttribute("action")
  var link = "#/" & el.value
  if action != "":
    link = link & "/" & action
  result = buildHtml a(href=link, class="btn btn-link"): text el.label
  
  result.addAttributes el
  result.addEvents wb, el


proc Link*(label: string, value: string = ""): UiElement =
  result = newUiElement(UiElementKind.kLink, label=label, events = @[UiEventKind.click])
  result.value = value
  result.builder = buildLink
  

proc Link*(): UiElement =
  result = newUiElement(UiElementKind.kLink)
  result.builder = buildLink
