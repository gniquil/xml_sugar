defmodule XmlSugar.Text do
  defstruct(
    parents: [], # [{atom(),integer()}]
    pos: 0,    # integer()
    # language: [],# inherits the element's language
    value: '',  # IOlist()
    type: :text,  # atom() one of (text|cdata)
    entity_type: :xmlText
  )

  def parse(xml_node) do
    %XmlSugar.Text{
      parents: elem(xml_node, 1), # [{atom(),integer()}]
      pos: elem(xml_node, 2),    # integer()
      # language: elem(xml_node, 3),# inherits the element's language
      value: elem(xml_node, 4),  # IOlist()
      type: elem(xml_node, 5)  # atom() one of (text|cdata)
    }
  end
end
