
import karax / [vdom, karaxdsl]
import ../uielement


proc builder(el: UiElement): Vnode =
  result = buildHtml tdiv(class="hero")
  var b = buildHtml tdiv(class="hero-body")
  for c in el.children:
    b.add builder(c)


proc Hero*(): UiElement =
  result = newUiElement(UiElementKind.kHero)
  result.builder = builder
