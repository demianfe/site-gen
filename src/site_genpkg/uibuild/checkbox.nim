
# import tables
# include karax / prelude
# import karax / [kbase, kdom, vdom, karaxdsl]



# proc buildCheckBox*(wb: WebBuilder, el: UiElement): Vnode =
#   result = buildHtml tdiv(class="form-group")
#   var
#     label = buildHtml label(class = "form-checkbox")
#     input = buildHtml input(`type`="checkbox", class = "form-input", id = el.id, placeholder = el.label)
#     i = buildHtml():
#       italic(class="form-icon"): # karax node
#         text el.label

#   input.addAttributes el
#   input.addEvents wb, el
  
#   label.add input
#   label.add i
#   result.add label
