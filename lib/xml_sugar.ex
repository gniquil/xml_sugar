defmodule XmlSugar do
  import XmlSugar.Transformer, only: [transform: 1]

  def xpath(doc, path) do
    _xpath(String.to_char_list(doc), String.to_char_list(path))
  end

  def at_xpath(doc, path) do
    result = _xpath(String.to_char_list(doc), String.to_char_list(path))
    hd(result)
  end

  def css(doc, path) do
    xpath(doc, transform(path))
  end

  def at_css(doc, path) do
    at_xpath(doc, transform(path))
  end

  defp _xpath(data_char_list, path) do
    {parsed_data, _} = :xmerl_scan.string(data_char_list)
    Enum.map :xmerl_xpath.string(path, parsed_data), fn (node) ->
      case elem(node, 0) do
        :xmlElement ->
          XmlSugar.Element.parse(node)
        :xmlText ->
          XmlSugar.Text.parse(node)
        _ ->
          raise "parse error"
      end
    end
  end
end
