defmodule XmlSugar.Transformer do
  def transform(input) do
    path = _transform(input)

    if String.match?(path, ~r/^\//) do
      path
    else
      "//" <> path
    end
  end

  def _transform(input) do
    # TODO: :not
    cond do
      result = Regex.run(~r/^([^\s]+)\:first-child$/, input) -> # :first-child
        # IO.puts "first-child #{input}"
        [matched, entity] = result
        "#{_transform(entity)}[1]"
      result = Regex.run(~r/^([^\s]+)\:last-child$/, input) -> # :last-child
        # IO.puts "last-child #{input}"
        [matched, entity] = result
        "#{_transform(entity)}[last()]"
      result = Regex.run(~r/^([^\s]+)\:nth-child\((\d+)\)$/, input) -> # :nth-child
        # IO.puts "nth-child #{input}"
        [matched, entity, n] = result
        "#{_transform(entity)}[#{n}]"
      result = Regex.run(~r/^([^\s]+)\:nth-child\(even\)$/, input) -> # :nth-child, even
        # IO.puts "nth-child even #{input}"
        [matched, entity] = result
        "#{_transform(entity)}[position() mod 2 = 0]"
      result = Regex.run(~r/^([^\s]+)\:nth-child\(odd\)$/, input) -> # :nth-child, odd
        # IO.puts "nth-child odd #{input}"
        [matched, entity] = result
        "#{_transform(entity)}[position() mod 2 = 1]"
      result = Regex.run(~r/^([^\s]+)\:nth-child\((\d+)n\+(\d+)\)$/, input) -> # :nth-child, an + b
        # IO.puts "nth-child an+b #{input}"
        [matched, entity, a, b] = result
        "#{_transform(entity)}[position() mod #{a} = #{b} and position() > #{b}]"
      result = Regex.run(~r/^([^\s]+)\#([_A-Za-z0-9-]+)$/, input) -> # hash id
        # IO.puts "id #{input}"
        [matched, entity, id] = result
        "#{_transform(entity)}[@id=\"#{id}\"]"
      result = Regex.run(~r/^\#([_A-Za-z0-9-]+)$/, input) -> # hash id short cut
        # IO.puts "id shortcut #{input}"
        [matched, id] = result
        _transform("*##{id}")
      result = Regex.run(~r/^([^\s]+)\.([_A-Za-z0-9-]+)$/, input) -> # class
        # IO.puts "class #{input}"
        [matched, entity, class] = result
        "#{_transform(entity)}[contains(concat(' ', @class, ' '), ' #{class} ')]"
      result = Regex.run(~r/^\.([_A-Za-z0-9-]+)$/, input) -> # class short cut
        # IO.puts "class shortcut #{input}"
        [matched, class] = result
        _transform("*.#{class}")
      result = Regex.run(~r/^([^\s]+)\[([_A-Za-z0-9-]+)=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute exact
        # IO.puts "exact #{input}"
        [matched, entity, attr, val] = result
        "#{_transform(entity)}[@#{attr}=\"#{val}\"]"
      result = Regex.run(~r/^\[([_A-Za-z0-9-]+)=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute exact
        # IO.puts "exact #{input}"
        [matched, attr, val] = result
        "*[@#{attr}=\"#{val}\"]"
      result = Regex.run(~r/^([^\s]+)\[([_A-Za-z0-9-]+)\~=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute contains
        [matched, entity, attr, val] = result
        # IO.puts "contains --- #{input} --- #{entity} --- #{attr} --- #{val}"
        "#{_transform(entity)}[contains(concat(' ', @#{attr}, ' '), ' #{val} ')]"
      result = Regex.run(~r/^\[([_A-Za-z0-9-]+)\~=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute contains
        [matched, attr, val] = result
        # IO.puts "contains --- #{input} --- #{entity} --- #{attr} --- #{val}"
        "*[contains(concat(' ', @#{attr}, ' '), ' #{val} ')]"
      result = Regex.run(~r/^([^\s]+)\[([_A-Za-z0-9-]+)\*=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute substring
        # IO.puts "substring #{input}"
        [matched, entity, attr, val] = result
        "#{_transform(entity)}[contains(@#{attr}, '#{val}')]"
      result = Regex.run(~r/^\[([_A-Za-z0-9-]+)\*=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute substring
        # IO.puts "substring #{input}"
        [matched, attr, val] = result
        "*[contains(@#{attr}, '#{val}')]"
      result = Regex.run(~r/^([^\s]+)\[([_A-Za-z0-9-]+)\^=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute starts
        # IO.puts "starts #{input}"
        [matched, entity, attr, val] = result
        "#{_transform(entity)}[starts-with(@#{attr}, '#{val}')]"
      result = Regex.run(~r/^\[([_A-Za-z0-9-]+)\^=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute starts
        # IO.puts "starts #{input}"
        [matched, attr, val] = result
        "*[starts-with(@#{attr}, '#{val}')]"
      result = Regex.run(~r/^([^\s]+)\[([_A-Za-z0-9-]+)\$=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute ends NOT USABLE
        # IO.puts "ends #{input}"
        [matched, entity, attr, val] = result
        "#{_transform(entity)}[ends-with(@#{attr}, '#{val}')]"
      result = Regex.run(~r/^\[([_A-Za-z0-9-]+)\$=[\"\']([_A-Za-z0-9-]+)[\"\']\]$/, input) -> # attribute ends NOT USABLE
        # IO.puts "ends #{input}"
        [matched, attr, val] = result
        "*[ends-with(@#{attr}, '#{val}')]"
      result = Regex.run(~r/^([^\s]+)\[([_A-Za-z0-9-]+)\]$/, input) -> # attribute existence
        # IO.puts "existence #{input}"
        [matched, entity, attr] = result
        "#{_transform(entity)}[@#{attr}]"
      result = Regex.run(~r/^\[([_A-Za-z0-9-]+)\]$/, input) -> # attribute existence
        # IO.puts "existence #{input}"
        [matched, attr] = result
        "*[@#{attr}]"
      result = Regex.run(~r/^([^\s]+)\s*\+\s*([^\s]+)$/, input) -> # immediate sibiling
        # IO.puts "immediate sibiling #{input}"
        [matched, lhs, rhs] = result
        _transform(lhs) <> "/following-sibling::*[1]/self::" <> _transform(rhs)
      result = Regex.run(~r/(.+)\s*>\s*(.+)/, input) -> # direct descendant
        # IO.puts "direct descendant #{input}"
        [matched, lhs, rhs] = result
        _transform(String.strip(lhs)) <> "/" <> _transform(String.strip(rhs))
      result = Regex.run(~r/(.+)\s+(.+)/, input) -> # any descendant
        # IO.puts "any descendant #{input}"
        [matched, lhs, rhs] = result
        _transform(String.strip(lhs)) <> "//" <> _transform(String.strip(rhs))
      true ->
        # IO.puts "plain #{input}"
        input
    end
  end
end
