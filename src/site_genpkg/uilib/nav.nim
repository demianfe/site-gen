
import ../uielement
import baseui
import karax / [vdom, karaxdsl]


proc NavItem*(ctxt: AppContext, label, value: string): UiElement =
  result = Item(ctxt, "Users", "show_users")
  result.builder = proc(el: UiElement): VNode =
                       buildHtml():
                         if el.hasAttribute("active"):
                           li(class="nav-item active"):
                             a(href=el.value): text el.label
                         else:
                           li(class="nav-item"):
                             a(href=el.value): text el.label
  

proc buildNav(el: UiElement): VNode =
  # TODO: if nav var has more complex children(for ex: acordion), process them
  result = buildHtml(ul(class="navbar"))
    # for c in el.children:
    #   if c.kind == UiElementKind.kItem:
    #     if c.hasAttribute("active"):
    #       li(class="nav-item active"):
    #         a(href=c.value): text c.label
    #     else:
    #       li(class="nav-item"):
    #         a(href=c.value): text c.label
            

proc NavSection*(navItems: seq[UiElement] = @[]): UiElement =
  result = newUiElement(UiElementKind.kNavSection)
  for ni in navItems:
    if not ni.hasAttribute "action":
      var item =  ni
      item.setAttribute("action", ni.value)
    if not ni.hasAttribute "action":
      var item =  ni
      item.setAttribute("action", ni.value)      
  result.children = navItems


proc NavBar*(): UiElement =
  result = newUiElement(UiElementKind.kNavBar)
  result.builder = buildNav
  
