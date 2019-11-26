
import karax / [vdom, karaxdsl]
import ../uielement

proc buildPanelNav(el: UiElementKind): Vnode =
  result = buildHtml tdiv(class="panel-nav")


proc buildChildren(parent: Vnode, el: UiElement) =
  for c in el.children:
    var vn = c.builder c
    if not vn.isNil:
      parent.add vn
  
  
proc buildPanel(el: UiElement): Vnode =
  var b, h, f: VNode
  
  for c in el.children:
    if c.kind == UiElementKind.kHeader:
      h = buildHtml tdiv(class="panel-header"):
        if el.label != "":
          tdiv(class="panel-title"): text el.label
      for hkid in c.children:
        if hkid.kind == UiElementKind.kTitle:
          var t = buildHtml tdiv(class="panel-title")
          t.add hkid.builder hkid
          h.add t
        else:
          h.add hkid.builder hkid
        
    if c.kind == UiElementKind.kBody:
      b = buildHtml tdiv(class="panel-body")
      buildChildren(b, c)
      
    elif c.kind == UiElementKind.kFooter:
      f = buildHtml tdiv(class="panel-footer")
      buildChildren(f, c)
  
  result = buildHtml():
    tdiv(class="panel"):
      if not h.isNil: h
      if not b.isNil: b
      if not f.isNil: f


proc Panel*(): UiElement =
  result = newUiElement(UiElementKind.kPanel)
  result.builder = buildPanel
