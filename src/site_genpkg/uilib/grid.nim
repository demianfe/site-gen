
import karax / [kdom, vdom, karaxdsl]

import site_genpkg / uielement


proc buildGrid*(wb: WebBuilder, el: UiElement): VNode =
  result = buildHtml():
    tdiv(class="container"):
      tdiv(class="columns"):
        tdiv(class="column col-auto"): text "col-auto"
        tdiv(class="column": txt "col"


proc grid*(id = ""): UiElement =
  result = newUiElement(UiElementKind.kInputText)
  result.setAttribute("type", "text")
  if id != "":
    result.id = id
