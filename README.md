XmlSugar
========

This is a simple Elixir sugar wrapper around `:xmerl`.

## Usage

Given a xml document such as below

```xml
<?xml version="1.05" encoding="UTF-8"?>
<game>
  <matchups>
    <matchup winner-id="1">
      <name>Match One</name>
      <teams>
        <team>
          <id>1</id>
          <name>Team One</name>
        </team>
        <team>
          <id>2</id>
          <name>Team Two</name>
        </team>
      </teams>
    </matchup>
    <matchup winner-id="2">
      <name>Match Two</name>
      <teams>
        <team>
          <id>2</id>
          <name>Team Two</name>
        </team>
        <team>
          <id>3</id>
          <name>Team Three</name>
        </team>
      </teams>
    </matchup>
    <matchup winner-id="1">
      <name>Match Three</name>
      <teams>
        <team>
          <id>1</id>
          <name>Team One</name>
        </team>
        <team>
          <id>3</id>
          <name>Team Three</name>
        </team>
      </teams>
    </matchup>
  </matchups>
</game>
```
We can do the following

```elixir
doc = "..." # as above

# get the name of the first match
result = doc |> XmlSugar.get(~x"//matchup/name/text()") # `x` marks sigil for (x)path
assert result == 'Match One'

# get the xml record of the name of the first match
result = doc |> XmlSugar.get(~x"//matchup/name"e) # `e` is the modifier for (e)ntity
assert result == {:xmlElement, :name, :name, [], {:xmlNamespace, [], []},
        [matchup: 2, matchups: 2, game: 1], 2, [],
        [{:xmlText, [name: 2, matchup: 2, matchups: 2, game: 1], 1, [],
          'Match One', :text}], [],
        '/Users/frank/projects/elixir/xml_sugar', :undeclared}

# get the full list of matchup name
result = doc |> XmlSugar.get(~x"//matchup/name/text()"l) # `l` stands for (l)ist
assert result == ['Match One', 'Match Two', 'Match Three']

# get a list of matchups with different map structure
result = doc |> XmlSugar.get(
  ~x"//matchups/matchup"l,
  name: ~x"./name/text()",
  winner: [
    ~x".//team/id[.=ancestor::matchup/@winner-id]/..",
    name: ~x"./name/text()"
  ]
)
assert result == [
  %{name: 'Match One', winner: %{name: 'Team One'}},
  %{name: 'Match Two', winner: %{name: 'Team Two'}},
  %{name: 'Match Three', winner: %{name: 'Team One'}}
]
```

## How to Use

Generally, all you need to do is use `get/2`, where first argument being a `string`, `char_list`, or a xml record
as specified in `:xmerl` (see https://github.com/otphub/xmerl/blob/master/include/xmerl.hrl). second argment being
either a xpath tuple, i.e. ~x"//some/path/to/your/node/or/nodes" or
a list with first item being a xpath, the rest being in a keyword list format, to specify your mapping.

### Xpath sigil and modifiers

Given a xpath string such as "//head/title",

```elixir
iex> ~x"//head/title/text()"e
{:xpath, "//head/title/text()", 'e'}
```

By default `XmlSugar.get/2` will only return the first node that matches the xpath, and automatically convert it
to the value of the node if the node is a text node, attribute node, comment node, or processing instruction.

To get all occurences, use the `l` modifier

```elixir
iex> doc |> get(~x"//li"l)
```

To force `XmlSugar.get/2` to return the node itself (the erlang record), use the `e` modifier. For example:

```elixir
iex> doc |> get(~x"//head/title/text"e)
{:xmlText, ...}
```

You can combine the above two modifiers to get the full list of entities.

```elixir
iex> doc |> get(~x"//li/text()"el)
```

### Chaining

Note that since often what you get is a node or a list of nodes, and the input to `get/2` can also be a node,
you can chain them, e.g.

```elixir
iex> doc |> get(~x"//li"l) |> Enum.map fn (li_node) ->
  %{name: get(li_node, ~x"./name/text()"),
    age: get(li_node, ~x"./age/text()")}
end
```

### Mapping to a structure

Since the previous example is such a common use case, XmlSugar allows you just simply do the following

```elixir
iex> doc |> get(~x"//li"l, name: ~x"./name/text()", age: ~x"./age/text()")
```

### Nesting

But what you want is sometimes more complex than just that, XmlSugar thus also allows nesting

```elixir
iex> doc |> get(
  ~x"//li"l,
  name: [
    ~x"./name",
    first: ~x"./first/text()",
    last: ~x"./last/text()"
  ],
  age: ~x"./age/text()"
)
```

For more examples, please take a look at the tests.
