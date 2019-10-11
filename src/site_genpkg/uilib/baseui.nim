
# base ui element used for composition

import ../uielement


proc Component*(): UiElement =
  result = newUiElement(UiElementKind.kComponent)


proc Footer*(): UiElement =
  result = newUiElement(UiElementKind.kFooter)

  
proc Header*(): UiElement =
  result = newUiElement(UiElementKind.kHeader)

  
proc Body*(): UiElement =
  result = newUiElement(UiElementKind.kBody)


proc Column*(id: string): UiElement =
  result = newUiElement(UiElementKind.kColumn)
  result.id = id


proc Row*(id: string): UiElement =
  result = newUiElement(UiElementKind.kRow)
  result.id = id


proc Item*(label: string, value: string): UiElement =
  result = newUiElement(UiElementKind.kItem)
  result.label = label
  result.value = value
