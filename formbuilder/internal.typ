#let mk-metadata(form-type, form-label, dy: 0pt, extras: (:)) = box(
  width: 100%,
  height: 100%,
  inset: (top: dy, bottom: -dy),
  layout(
    size => {
      let position = here().position()
      metadata(
        (
          formIndex: counter("form").get(),
          formType: form-type,
          formLabel: form-label,
          width: size.width.pt(),
          height: size.height.pt(),
          page: position.page,
          x: position.x.pt(),
          y: (page.height - position.y - size.height).pt(),
        )
          + extras,
      )
    },
  ),
)

#let item-number(
  rowspan,
  level: 1,
  align: top + center,
  step: false,
) = grid.cell(
  align: align,
  rowspan: rowspan,
  {
    let nfn = ("1", "a")
    set text(weight: "bold")
    if step { counter("form").step(level: level) }
    context numbering(nfn.at(level - 1), counter("form").get().at(level - 1))
  },
)
