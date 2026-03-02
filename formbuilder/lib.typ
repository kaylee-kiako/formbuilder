#import "elements.typ" as elements

#let form(..rest) = grid(
  columns: (1fr,) * 6,
  stroke: (x, y) => {
    if x == 0 { (bottom: 0.5pt + black) } else {
      (left: 0.5pt + black, bottom: 0.5pt + black)
    }
  },
  ..rest
)

#let from-kdl(kdl) = {
  import "@preview/kuddle:0.1.0" as kuddle
  let find-entry(node, name, default: none) = {
    let entry = node.entries.find(n => n.name == name)
    if entry == none { default } else {
      let ty = entry.at("type", default: "string")
      let value = entry.at("value", default: default)
      if ty == "content" { eval(value, mode: "markup") } else { value }
    }
  }
  let find-child(node, name, default: none) = node.children.find(n => (
    n.name == name
  ))
  let into-item(node) = if node.name == "option" {
    (body: find-entry(node, none), label: find-entry(node, "tag"))
  } else { none }
  let processor = (
    meta: node => elements.meta(
      find-entry(node, "type", default: "Form"),
      find-entry(node, "id"),
      find-entry(node, "revision"),
      find-entry(node, "title"),
      find-entry(node, "owner"),
    ),
    part: node => elements.part(
      find-entry(node, none),
      note: find-entry(node, "hint"),
    ),
    section: node => elements.section(find-entry(node, none)),
    info: node => elements.info(
      find-entry(node, none),
      span: find-entry(node, "span", default: 6),
    ),
    fence: node => elements.fence(find-entry(node, none)),
    short: node => elements.short(
      find-entry(node, "tag"),
      find-entry(node, none),
      span: find-entry(node, "span", default: 6),
    ),
    long: node => elements.long(
      find-entry(node, "tag"),
      find-entry(node, none),
      rows: find-entry(node, "rows", default: 3),
    ),
    number: node => elements.number(
      find-entry(node, "tag"),
      find-entry(node, none),
      span: find-entry(node, "span", default: 6),
    ),
    radio: node => elements.radio(
      find-entry(node, "tag"),
      find-entry(node, none),
      span: find-entry(node, "span", default: 6),
      cols: find-entry(node, "cols", default: 1),
      node.children.map(option => (
        body: find-entry(option, none),
        label: find-entry(option, "tag"),
        specify: find-entry(option, "specify", default: false),
        span: find-entry(option, "span", default: 1),
      )),
    ),
    multi: node => elements.multi(
      find-entry(node, none),
      span: find-entry(node, "span", default: 6),
      cols: find-entry(node, "cols", default: 1),
      node.children.map(option => (
        body: find-entry(option, none),
        label: find-entry(option, "tag"),
        specify: find-entry(option, "specify", default: false),
        span: find-entry(option, "span", default: 1),
      )),
    ),
    yesno: node => elements.yesno(
      find-entry(node, "tag"),
      find-entry(node, none),
      span: find-entry(node, "span", default: 6),
    ),
    signature: node => {
      let signature = find-child(node, "signature")
      let date = find-child(node, "date")
      let hint = find-child(node, "hint")
      let args = (:)
      if hint != none { args += (sign-me-body: (find-entry(hint, none))) }
      if signature != none {
        let entry = find-entry(signature, none)
        if entry != none {
          args += (signature-body: entry)
        }
      }
      if date != none {
        let entry = find-entry(date, none)
        if entry != none {
          args += (date-body: entry)
        }
      }
      elements.signature(
        find-entry(signature, "tag"),
        find-entry(date, "tag"),
        find-entry(node, none),
        ..args,
      )
    },
  )

  form(
    ..(kuddle.parse-kdl(kdl).map(node => processor.at(node.name)(node))),
  )
}
