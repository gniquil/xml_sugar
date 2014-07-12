defmodule XmlSugar.ProcessingInstruction do
  defstruct(
    name: :processing_instruction,   # atom()
    parents: [], # [{atom(),integer()}]
    pos: 0,    # integer()
    value: '',   # IOlist()
    entity_type: :xmlPI
  )

  def parse(xml_node) do
    %XmlSugar.ProcessingInstruction{
      name: elem(xml_node, 1),
      parents: elem(xml_node, 2), # [{atom(),integer()}]
      pos: elem(xml_node, 3),    # integer()
      value: elem(xml_node, 4)  # IOlist()
    }
  end
end
