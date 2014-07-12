defmodule XmlSugar.Attribute do
  defstruct(
    name: :class,      # atom()
    expanded_name: [],# atom() | {string(),atom()}
    nsinfo: [],     # {Prefix, Local} | []
    namespace: [],  # inherits the element's namespace
    parents: [],    # [{atom(),integer()}]
    pos: 0,       # integer()
    language: [],   # inherits the element's language
    value: '',     # IOlist() | atom() | integer()
    normalized: true,       # atom() one of (true | false)
    entity_type: :xmlAttribute,
  )

  def parse(xml_node) do
    %XmlSugar.Attribute{
      name: elem(xml_node, 1),      # atom()
      expanded_name: elem(xml_node, 2),# atom() | {string(),atom()}
      nsinfo: elem(xml_node, 3),     # {Prefix, Local} | []
      namespace: elem(xml_node, 4),  # inherits the element's namespace
      parents: elem(xml_node, 5),    # [{atom(),integer()}]
      pos: elem(xml_node, 6),       # integer()
      language: elem(xml_node, 7),   # inherits the element's language
      value: elem(xml_node, 8),     # IOlist() | atom() | integer()
      normalized: elem(xml_node, 9)       # atom() one of (true | false)
    }
  end
end
