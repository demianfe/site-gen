
import karax / [kdom, vdom, karaxdsl]
import ../uielement


proc buildDropdown(el: UiElement): VNode =
  result = buildHtml():
    tdiv(class="form-group"):
      select(class="form-select"):
        for child in el.children:
          if child.kind == kDropdownItem:
            option(value = child.value):
              text child.label


proc DropdownItem*(ctxt: AppContext, label: string): UiElement =
  result = newUiElement(ctxt, UiElementKind.kDropdownItem, label=label, events = @[UiEventKind.click])
  result.builder = buildDropdown

  
proc Dropdown*(ctxt: AppContext): UiElement =
  result = newUiElement(ctxt, UiElementKind.kDropdown)
  result.builder = buildDropdown


proc Dropdown*(ctxt: AppContext, dropdownItems: seq[UiElement]): UiElement =
  result = newUiElement(ctxt, UiElementKind.kDropdown)
  result.children = dropdownItems
  result.builder = buildDropdown
