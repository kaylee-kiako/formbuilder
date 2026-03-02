#set page(paper: "us-letter", margin: 0.5in)
#set text(font: "Public Sans")

#import "./formbuilder/lib.typ" as formbuilder

#formbuilder.from-kdl(read(sys.inputs.kdl-source))
