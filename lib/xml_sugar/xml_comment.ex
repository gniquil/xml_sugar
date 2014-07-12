defmodule XmlSugar.Comment do
  defstruct(
    parents: [],  # [{atom(),integer()}]
    pos: 0,           # integer()
    # language: [], # inherits the element's language
    value: '',          # IOlist()
    entity_type: :xmlComment
  )

  def parse(xml_node) do
    %XmlSugar.Comment{
      parents: elem(xml_node, 1), # [{atom(),integer()}]
      pos: elem(xml_node, 2),    # integer()
      # language: elem(xml_node, 3),# inherits the element's language
      value: elem(xml_node, 4)  # IOlist()
    }
  end
end
