defmodule XmlSugar.Declaration do
  alias XmlSugar.Attribute

  defstruct(
    vsn: "1.0",        # string() XML version
    encoding: "utf8",   # string() Character encoding
    standalone: :yes, # (yes | no)
    attributes: [],  # [#xmlAttribute()] Other attributes than above
    entity_type: :xmlDecl
  )

  def parse(xml_node) do
    attributes_list = elem(xml_node, 4) |> Enum.map &(Attribute.parse(&1))

    %XmlSugar.Declaration{
      vsn: elem(xml_node, 1),
      encoding: elem(xml_node, 2),
      standalone: elem(xml_node, 3),
      attributes: attributes_list
    }
  end
end
