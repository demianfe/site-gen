
import site_genpkg / uielement
import karax / [vdom, karaxdsl]


proc builder(el: UiElement): Vnode =
  result = buildHtml p: text el.value
  result.addAttributes el
  result.addEvents el
  

proc Paragraph*(id, value = ""): UiElement =
  result = newUiElement(UiElementKind.kParagraph)
  result.value = value
  result.builder = builder
  
