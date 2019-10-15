
import karax / [vdom, karaxdsl]
import ../uielement


proc buildBreadcrumb(wb: WebBuilder, el: UiElement): Vnode =
  result = buildHtml tdiv():
    ul(class="breadcrumb"):
      for child in el.children:
        li(class="breadcrumb-item"):
          a(href="#"): text child.label
          

proc Breadcrumb*(): UiElement =
  result = newUiElement(UiElementKind.kBreadcrum)
  result.builder = buildBreadcrumb
