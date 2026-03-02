#import "internal.typ" as internal: mk-metadata

/* HEADINGS */

#let meta(typ, id, revision, title, owner) = grid.cell(
  stroke: (bottom: 0.5pt + black),
  colspan: 6,
  grid(
    columns: (1fr,) * 6,
    grid.cell(align: bottom, inset: (right: 3pt, bottom: 3pt), [
      #set text(size: 6.75pt)
      #typ #text(size: 24pt, weight: "extrabold", id) \
      (Rev. #revision) \
    ]),
    grid.cell(
      colspan: 4,
      align: center + horizon,
      inset: (x: 3pt, bottom: 3pt),
      stroke: (x: 1pt + black),
      text(
        weight: "bold",
        size: 14pt,
        title,
      ),
    ),
    grid.cell(align: center + horizon, text(
      size: 6.75pt,
      owner,
    )),
  ),
)

#let part(body, note: none) = grid.cell(
  colspan: 6,
  stroke: (top: 1pt + black, bottom: 0.5pt + black),
  context {
    set text(weight: "bold", size: 11pt)
    counter(heading).step()
    box(
      fill: black,
      inset: (y: 3pt),
      width: 1fr,
      text(
        fill: white,
        align(
          center,
        )[Part #context numbering("I", counter(heading).get().first())],
      ),
    )
    box(
      width: 11fr,
      inset: (x: 4.54545%, y: 3pt),
      body + [ ] + if note != none { "(" + note + ")" },
    )
  },
)

#let section(body) = grid.cell(
  colspan: 6,
  inset: 3pt,
  stroke: (y: 0.5pt + black),
  align: center,
  {
    set text(size: 10pt)
    counter(heading).step(level: 2)
    [Section #context numbering("A", counter(heading).get().at(1))#sym.dash.em#body]
  },
)

/* MISCELLANEOUS DIVIDERS & INFORMATIONAL BITS */

#let info(body, span: 6) = grid.cell(
  colspan: span,
  inset: (x: 3pt, y: 6pt),
  text(size: 9pt, body),
)

#let fence(body) = grid.cell(
  colspan: 6,
  inset: 3pt,
  stroke: (y: 0.5pt + black),
  fill: black,
  align: center,
  text(size: 11pt, fill: white, weight: "bold", body),
)

#let unused(span: 1) = grid.cell(colspan: span, fill: gray.lighten(70%), {})

/* TEXT RESPONSES */

#let short(label, body, span: 6) = grid.cell(
  colspan: span,
  inset: 3pt,
  {
    set text(size: 9pt)
    counter("form").step()
    grid(
      columns: (1em, 1fr),
      rows: (auto, 1.5em),
      internal.item-number(2),
      grid.cell(inset: (left: 1em), body),
      grid.cell(mk-metadata("short", label, dy: 2pt)),
    )
  },
)

#let long(label, body, rows: 3) = grid.cell(
  colspan: 6,
  inset: 3pt,
  {
    set text(size: 9pt)
    counter("form").step()
    grid(
      stroke: (x, y) => if x == 1 and y > 0 {
        (bottom: (dash: "dotted", thickness: 0.5pt, paint: black))
      },
      columns: (1em, 1fr),
      rows: (auto,) + (2em,) * rows,
      internal.item-number(1 + rows),
      grid.cell(inset: (left: 1em), body),
      ..(
        grid.cell(inset: (left: 1em, bottom: 3pt), {
          counter("form").step(level: 2)
          mk-metadata("long", label, dy: 3pt)
        }),
      )
        * rows,
    )
  },
)

/* NUMERICAL RESPONSES */

#let number(label, body, span: 6) = grid.cell(
  colspan: span,
  inset: (left: 3pt),
  {
    counter("form").step()
    set text(size: 9pt)
    grid(
      columns: (1em, 1fr, 2em, 1in),
      rows: (auto,),
      inset: 3pt,
      internal.item-number(1),
      grid.cell(
        stroke: (right: 0.5pt + black),
        inset: (left: 1em, rest: 3pt),
        body,
      ),
      internal.item-number(1, align: center + bottom),
      grid.cell(align: bottom, stroke: (left: 0.5pt + black), box(
        width: 1fr,
        place(
          bottom,
          dy: 0.3em,
          box(
            width: 1fr,
            height: 1.3em,
            mk-metadata("number", label),
          ),
        ),
      )),
    )
  },
)

/* RADIO RESPONSES */

#let radio(label, body, span: 6, cols: 1, items) = grid.cell(
  colspan: span,
  inset: 3pt,
  {
    counter("form").step()
    set text(size: 9pt)
    grid(
      columns: (1em,) + (14pt, 1fr) * cols,
      rows: (auto,),
      internal.item-number(1 + calc.ceil(items.len() / cols)),
      grid.cell(inset: (left: 1em, bottom: 3pt), colspan: cols * 2, body),
      ..for item in items {
        (
          grid.cell(align: top, inset: 3pt, box(
            width: 8pt,
            height: 8pt,
            circle(
              radius: 4pt,
              stroke: 1pt + black,
              inset: -1pt,
              mk-metadata(
                "radio",
                label,
                extras: (radioLabel: item.label),
              ),
            ),
          )),
          grid.cell(
            inset: 3pt,
            item.body
              + if item.at("specify", default: false) {
                (
                  h(1em)
                    + box(width: 1fr, place(dy: -1.3em, box(
                      width: 1fr,
                      height: 1.5em,
                      stroke: (
                        bottom: (
                          dash: "dotted",
                          thickness: 0.5pt,
                          paint: black,
                        ),
                      ),
                      mk-metadata("short", label, extras: (
                        radioLabel: item.label,
                        isSpecify: true,
                      )),
                    )))
                )
              },
            colspan: item.at("span", default: 1) * 2 - 1,
          ),
        )
      }
    )
  },
)

#let yesno(label, body, span: 6) = grid.cell(
  colspan: span,
  inset: (x: 3pt),
  {
    counter("form").step()
    set text(size: 9pt)
    grid(
      columns: (1em, 1fr, auto, 4em, auto, 4em),
      rows: (auto,),
      inset: 3pt,
      internal.item-number(1),
      grid.cell(
        inset: (left: 1em, rest: 3pt),
        body,
      ),
      grid.cell(align: bottom + right, inset: 3pt, box(
        width: 8pt,
        height: 8pt,
        {
          circle(
            radius: 4pt,
            stroke: 1pt + black,
            inset: -1pt,
            mk-metadata(
              "radio",
              label,
              extras: (radioLabel: "yes"),
            ),
          )
        },
      )),
      grid.cell(align: bottom)[Yes],
      grid.cell(align: bottom + right, inset: 3pt, box(
        width: 8pt,
        height: 8pt,
        {
          circle(
            radius: 4pt,
            stroke: 1pt + black,
            inset: -1pt,
            mk-metadata(
              "radio",
              label,
              extras: (radioLabel: "no"),
            ),
          )
        },
      )),
      grid.cell(align: bottom)[No],
    )
  },
)

/* MULTIPLE-SELECT RESPONSES */

#let multi(body, span: 6, cols: 1, items) = grid.cell(
  colspan: span,
  inset: 3pt,
  {
    counter("form").step()
    set text(size: 9pt)
    grid(
      columns: (1em,) + (1em, auto, 1fr) * cols,
      rows: (auto,),
      inset: 3pt,
      internal.item-number(1 + calc.ceil(items.len() / cols)),
      grid.cell(inset: (left: 1em, bottom: 3pt), colspan: cols * 3, body),
      ..for item in items {
        (
          internal.item-number(
            1,
            level: 2,
            step: true,
          ),
          grid.cell(align: top + right, box(
            stroke: 1pt + black,
            width: 8pt,
            height: 8pt,
            mk-metadata(
              "checkbox",
              item.label,
            ),
          )),
          grid.cell(
            item.body
              + if item.at("specify", default: false) {
                (
                  h(1em)
                    + box(width: 1fr, place(dy: -1.3em, box(
                      width: 1fr,
                      height: 1.5em,
                      stroke: (
                        bottom: (
                          dash: "dotted",
                          thickness: 0.5pt,
                          paint: black,
                        ),
                      ),
                      mk-metadata("short", item.label, extras: (
                        isSpecify: true,
                      )),
                    )))
                )
              },
            colspan: item.at("span", default: 1) * 3 - 2,
          ),
        )
      }
    )
  },
)

/* SPECIALIZED */

#let signature(
  signature-label,
  date-label,
  sign-me-body: "Please Sign Here",
  signature-body: "Signature",
  date-body: "Date",
  body,
) = grid.cell(
  colspan: 6,
  stroke: (y: 1pt + black),
  {
    grid(
      columns: (1fr, 0.5fr, 6fr, 1fr, 3fr, 0.5fr),
      rows: (auto, 2.5em, auto),
      grid.cell(
        rowspan: 3,
        inset: (y: 3pt),
        align: horizon,
        stroke: (right: 0.5pt + black),
        text(
          size: 11pt,
          weight: "bold",
          sign-me-body,
        ),
      ),
      grid.cell(
        inset: 3pt,
        colspan: 5,
        text(size: 9pt, body),
      ),
      grid.cell(x: 2, y: 1, inset: 3pt, {
        counter("form").step()
        mk-metadata(
          "short",
          signature-label,
          dy: 3pt,
        )
      }),
      grid.cell(x: 4, y: 1, inset: 3pt, {
        counter("form").step()
        mk-metadata(
          "short",
          date-label,
          dy: 3pt,
        )
      }),
      grid.cell(x: 2, y: 2, inset: 3pt, stroke: (top: 0.5pt + black), text(
        size: 9pt,
        signature-body,
      )),
      grid.cell(x: 4, y: 2, inset: 3pt, stroke: (top: 0.5pt + black), text(
        size: 9pt,
        date-body,
      )),
    )
  },
)
