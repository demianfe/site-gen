
# base ui element used for composition

import ../uielement


proc Component*(): UiElement =
  result = newUiElement(UiElementKind.kComponent)


proc Component*(ctxt: AppContext): UiElement =
  result = newUiElement(ctxt, UiElementKind.kComponent)


proc Footer*(ctxt: AppContext): UiElement =
  result = newUiElement(ctxt, UiElementKind.kFooter)

  
proc Header*(ctxt: AppContext): UiElement =
  result = newUiElement(ctxt, UiElementKind.kHeader)

  
proc Body*(ctxt: AppContext): UiElement =
  result = newUiElement(ctxt, UiElementKind.kBody)


proc Column*(ctxt: AppContext, id: string): UiElement =
  result = newUiElement(ctxt, UiElementKind.kColumn)
  result.id = id


proc Row*(ctxt: AppContext,id: string): UiElement =
  result = newUiElement(ctxt, UiElementKind.kRow)
  result.id = id


proc Item*(ctxt: AppContext, label: string, value: string): UiElement =
  result = newUiElement(ctxt, UiElementKind.kItem)
  result.label = label
  result.value = value
