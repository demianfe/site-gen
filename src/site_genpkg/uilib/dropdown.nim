
import karax / [kdom, vdom, karaxdsl]
import ../uielement


proc buildDropdown(wb: WebBuilder, el: UiElement): VNode =
  result = buildHtml():
    tdiv(class="form-group"):
      select(class="form-select"):
        for child in el.children:
          if child.kind == kDropdownItem:
            option(value = child.value):
              text child.label


# proc buildDropdown(el: UiElement): VNode =
#   result = buildHtml():
#     tdiv(class="form-group"):
#       select(class="form-select"):
#         for child in el.children:
#           if child.kind == kDropdownItem:
#             option(value = child.value):
#               text child.label

proc DropdownItem*(label: string): UiElement =
  result = newUiElement(UiElementKind.kDropdownItem, label=label, events = @[UiEventKind.click])
  result.builder = buildDropdown

  
proc Dropdown*(): UiElement =
  result = newUiElement(UiElementKind.kDropdown)
  result.builder = buildDropdown


proc Dropdown*(dropdownItems: seq[UiElement]): UiElement =
  result = newUiElement(UiElementKind.kDropdown)
  result.children = dropdownItems
  result.builder = buildDropdown
