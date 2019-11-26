
import tables
import karax / [vdom, karaxdsl]

import ../uielement

type
  LoadingSize* = enum
    small, large

proc builder*(el: UiElement): Vnode =
  result = buildHtml tdiv(class="loading loading-lg")
  result.addAttributes el

  
proc Loading*(size = LoadingSize.small): UiElement =
  result = newUiElement(UiElementKind.kLoading)
  if size == LoadingSize.large:
    result.setAttribute("class", "loading loading-lg")
  else:
    result.setAttribute("class", "loading")

  result.builder = builder
