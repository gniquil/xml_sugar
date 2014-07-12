
defmodule XmlSugar.Element do
  alias XmlSugar.Attribute
  alias XmlSugar.Text
  alias XmlSugar.Declaration
  alias XmlSugar.ProcessingInstruction
  alias XmlSugar.Comment

  defstruct(
    name: :div, #atom
    expanded_name: [], # string() | {URI,Local} | {"xmlns",Local}
    # nsinfo: [],          # {Prefix, Local} | []
    # namespace: %{}, #xmlNamespace{},
    parents: [],   # [{atom(),integer()}]
    pos: 0,      # integer()
    attributes: [],  # [#xmlAttribute()]
    content: [], # [#xmlElement()|#xmlText()|#xmlPI()|#xmlComment()|#xmlDecl()]
    # language: "",  # string()
    # xmlbase: "",           # string() XML Base path, for relative URI:s
    # elementdef: :undeclared, # atom(), one of [undeclared | prolog | external | element]
    entity_type: :xmlElement,
    text: ''
  )

  def parse(xml_node) do
    attributes_list = elem(xml_node, 7) |> Enum.map &(Attribute.parse(&1))
    children_list = elem(xml_node, 8)
      |> Enum.map fn (child) ->
        case elem(child, 0) do
          :xmlElement -> parse(child)
          :xmlText -> Text.parse(child)
          :xmlComment -> Comment.parse(child)
          :xmlPI -> ProcessingInstruction.parse(child)
          :xmlDecl -> Declaration.parse(child)
          _ -> raise "parse error"
        end
      end
    text = ''
    first_child = hd(children_list)
    if length(children_list) == 1 and first_child.entity_type == :xmlText do
      text = first_child.value
    end

    %XmlSugar.Element{
      name: elem(xml_node, 1),
      expanded_name: elem(xml_node, 2),
      # nsinfo: elem(xml_node, 3),
      # namespace: elem(xml_node, 4),
      parents: elem(xml_node, 5),
      pos: elem(xml_node, 6),
      attributes: attributes_list,
      content: children_list,
      # language: elem(xml_node, 9),
      # xmlbase: elem(xml_node, 10),
      # elementdef: elem(xml_node, 11)
      text: text
    }
  end
end
