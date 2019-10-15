
import ../uielement
import karax / [vdom, karaxdsl]


# TODO:
proc buildMenuItem(el: UiElement): Vnode =
  result = buildHtml():
    li(class="menu-item"):
      a:
        text el.value
  
  
proc buildMenu*(wb: WebBuilder, menu: UiElement): VNode =
  result = buildHtml():
    ul(class="menu"):
      li(class="divider", data-content=menu.value)
      for menuItem in menu.children:
        if menuItem.kind == kMenuItem:
          buildMenuItem(menuItem)


proc MenuItem*(label: string): UiElement =
  result = newUiElement(UiElementKind.kMenuItem, label=label, events = @[UiEventKind.click])

  
proc Menu*(label="", menuItems: seq[UiElement]): UiElement =
  result = newUiElement(UiElementKind.kMenu)
  if label != "":
    result.value = label
  result.children = menuItems

  result.builder = buildMenu
