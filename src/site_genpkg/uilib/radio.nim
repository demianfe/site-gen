
import site_genpkg / uielement
import karax / [vdom, karaxdsl]


proc buildRadio*(el: UiElement): Vnode =
  result = buildHtml tdiv(class="form-group"):
    label(class = "form-label"):
      text el.label    
  
  for kid in el.children:
    if kid.kind == UiElementKind.kRadio:
      var
        formRadio = buildHtml label(class = "form-radio form-inline"):
          text kid.label
        input = buildHtml():
          input(`type`="radio", id = kid.id, value = kid.value)
        i = buildHtml italic(class="form-icon")
        
      input.addAttributes kid
      input.addEvents kid

      formRadio.add input
      formRadio.add i
      result.add formRadio
      
  
proc Radio*(ctxt: AppContext, id, label = "", value=""): UiElement =
  result = newUiElement(ctxt, UiElementKind.kRadio, events = @[UiEventKind.click])
  result.label = label
  result.id = id
  

proc RadioGroup*(ctxt: AppContext, id, label = ""): UiElement =
  result = newUiElement(ctxt, UiElementKind.kRadioGroup)
  result.label = label
  result.id = id 
  result.builder = buildRadio
