defmodule XmlSugar do
  require Record
  Record.defrecord :xmlDecl, Record.extract(:xmlDecl, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlNamespace, Record.extract(:xmlNamespace, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlNsNode, Record.extract(:xmlNsNode, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlComment, Record.extract(:xmlComment, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlPI, Record.extract(:xmlPI, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlDocument, Record.extract(:xmlDocument, from_lib: "xmerl/include/xmerl.hrl")

  import List, only: [first: 1]

  def parse(doc) when is_bitstring(doc) do
    doc |> String.to_char_list |> parse
  end

  def parse(doc) do
    {parsed_doc, _} = :xmerl_scan.string(doc)
    parsed_doc
  end

  def xpath(node, path) when is_bitstring(path) do
    xpath(node, String.to_char_list(path))
  end

  def xpath(collection, path) when is_list(collection) do
    Enum.map(collection, fn (item) -> xpath(item, path) end)
  end

  def xpath(node, path) do
    :xmerl_xpath.string(path, node)
  end

  def at_xpath(node, path) do
    xpath(node, path) |> first
  end

  def value(nodes) when is_list(nodes) do
    Enum.map nodes, &value/1
  end

  def value(node) do
    cond do
      Record.record? node, :xmlText ->
        xmlText(node, :value)
      Record.record? node, :xmlComment ->
        xmlComment(node, :value)
      Record.record? node, :xmlPI ->
        xmlPI(node, :value)
      Record.record? node, :xmlAttribute ->
        xmlAttribute(node, :value)
      true ->
        node
    end
  end

  def value(nodes, mappings) when is_list(nodes) do
    Enum.map nodes, &(value(&1, mappings))
  end

  def value(node, mappings) do
    mappings
    |> Enum.reverse
    |> Enum.reduce([], fn({label, path}, result) ->
      temp = node |> xpath(path) |> value
      case length(temp) do
        1 -> [{label, hd(temp)} | result]
        0 -> [{label, nil} | result]
        _ -> [{label, temp} | result]
      end
    end)
  end

  def update(collection, mappings) do
    Enum.map(collection, fn (item) ->
      _update(item, mappings)
    end)
  end

  defp _update(item, mappings) do
    Enum.reduce(mappings, item, fn ({label, specs}, item) ->
      {_, item} = get_and_update_in(item[label], fn (i) -> {i, i |> value(specs)} end)
      item
    end)
  end
end
