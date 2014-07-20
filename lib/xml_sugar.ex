defmodule XmlSugar do
  @moduledoc """
  `XmlSugar` is a thin wrapper around `:xmerl`. It allows users to converts a string or xmlElement
  record as defined in :xmerl to a map specified as an argment.
  """

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


  @doc """
  `doc` can be a char_list or string, but ultimately converts to char_list as it is required by :xmerl_scan

  Return an `xmlElement` record
  """
  def parse(doc) when is_bitstring(doc) do
    doc |> String.to_char_list |> parse
  end
  def parse(doc) do
    {parsed_doc, _} = :xmerl_scan.string(doc)
    parsed_doc
  end

  def sigil_x(path, modifier \\ '') do
    {:xpath, path, Enum.sort(modifier)}
  end

  @doc """
  `label` has to be "&...", "...[]", "&...[]", or "..."
  `&`: get the value of the node (only works when the node is `xmlText`, `xmlComment`, `xmlPI`, or `xmlAttribute`)
  `[]`: returns a list of records for the given label

  `path` is an xpath string. If it is nested, you can use the "./" or "../" syntax.

  `subspec` is repeat of the same keyword list to allow nesting
  """
  def process_spec([{label, [path | subspec]}]) do
    subspec = [
      children: Enum.reduce(subspec, [], fn (spec, result) ->
        result ++ process_spec([spec])
      end)
    ]
    _process_spec(label, path, subspec)
  end

  def process_spec([{label, path}]) do
    subspec = [children: []]
    _process_spec(label, path, subspec)
  end

  def process_spec(spec) do
    Enum.reduce(spec, [], fn (item, result) -> result ++ process_spec([item]) end)
  end

  defp _process_spec(label, path, processed_subspec) do
    # label_str = Atom.to_string(label)
    {:xpath, p, m} = path
    if ?e in m do
      # if String.match?(label_str, ~r/^\&/) do
      processed_subspec = [{:is_value, false} | processed_subspec]
      # label_str = String.replace(label_str, ~r/^\&/, "")
    else
      processed_subspec = [{:is_value, true} | processed_subspec]
    end
    if ?l in m do
      # if String.match?(label_str, ~r/\[\]$/) do
      processed_subspec = [{:is_list, true} | processed_subspec]
      # label_str = String.replace(label_str, ~r/\[\]$/, "")
    else
      processed_subspec = [{:is_list, false} | processed_subspec]
    end

    # processed_label = String.to_atom(label_str)

    # [{processed_label, [{:path, String.to_char_list(path)} | processed_subspec]}]
    [{label, [{:path, String.to_char_list(p)} | processed_subspec]}]
  end

  @doc """
  converts doc to a map, defined by spec
  """
  def to_map(doc, spec) when is_bitstring(doc) do
    doc |> parse |> to_map(spec)
  end

  def to_map(parent, spec) do
    _to_map(parent, process_spec(spec))
  end

  defp _to_map(parent, [{label, spec}]) do
    current_node = :xmerl_xpath.string(spec[:path], parent)

    if spec[:is_list] do
      if spec[:is_value] do
        # Dict.put(%{}, label, Enum.map(current_node, fn(item) -> _get_value(item) end))
        if length(spec[:children]) == 0 do
          Dict.put(%{}, label, Enum.map(current_node, fn(item) -> _get_value(item) end))
        else
          # raise "Can't return value and get children"
          Dict.put(%{}, label, Enum.map(current_node, fn(node) -> _to_map(node, spec[:children]) end))
        end
      else
        if length(spec[:children]) == 0 do
          Dict.put(%{}, label, current_node)
        else
          Dict.put(%{}, label, Enum.map(current_node, fn(node) -> _to_map(node, spec[:children]) end))
        end
      end
    else
      current_node = List.first(current_node)
      if spec[:is_value] do
        # Dict.put(%{}, label, _get_value(current_node))
        if length(spec[:children]) == 0 do
          Dict.put(%{}, label, _get_value(current_node))
        else
          # raise "Can't return value and get children"
          Dict.put(%{}, label, _to_map(current_node, spec[:children]))
        end
      else
        if length(spec[:children]) == 0 do
          Dict.put(%{}, label, current_node)
        else
          Dict.put(%{}, label, _to_map(current_node, spec[:children]))
        end
      end
    end
  end

  defp _to_map(parent, spec) do
    Enum.reduce(spec, %{}, fn (s, result) -> Dict.merge(result, _to_map(parent, [s])) end)
  end

  defp _get_value(node) do
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

  def get(parent, path, subspec) do
    spec = [path | subspec]
    parent |> to_map(temp: spec) |> Map.get(:temp)
  end

  def get(parent, path) do
    parent |> to_map(temp: path) |> Map.get(:temp)
  end
end
