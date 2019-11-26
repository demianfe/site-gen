
import karax / [vdom, karaxdsl]
import ../uielement, ../ui_utils


proc buildForm(el: UiElement): VNode =
  result = buildHtml(form())


proc Form*(): UiElement =
  result = newUiElement(UiElementKind.kForm)
  result.builder = buildForm
