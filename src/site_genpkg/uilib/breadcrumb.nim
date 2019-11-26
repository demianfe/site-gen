
import karax / [vdom, karaxdsl]
import ../uielement


proc buildBreadcrumb(el: UiElement): Vnode =
  result = buildHtml tdiv():
    ul(class="breadcrumb"):
      for child in el.children:
        li(class="breadcrumb-item"):
          a(href="#"): text child.label
          

proc Breadcrumb*(ctxt: AppContext): UiElement =
  result = newUiElement(ctxt, UiElementKind.kBreadcrum)
  result.builder = buildBreadcrumb
