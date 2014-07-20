XmlSugar
========

This is a simple Elixir sugar wrapper around `:xmerl`. What it adds is css selectors.

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
result = xml_doc # as defined above
|> XmlSugar.to_map(
  matchups: [
    ~x"//matchups/matchup"l,
    name: ~x"./name/text()",
    winner: [
      ~x".//team/id[.=ancestor::matchup/@winner-id]/..",
      name: ~x"./name/text()"
    ]
  ]
)

assert result == %{
  matchups: [
    %{name: 'Game One', winner: %{name: 'Team One'}},
    %{name: 'Game Two', winner: %{name: 'Team Two'}},
    %{name: 'Game Three', winner: %{name: 'Team One'}}
  ]
}

# or something simple... get the list of match names
result = xml_doc |> XmlSugar.get(~x"//matchup/name/text()"l)
assert result == ['Match One', 'Match Two', 'Match Three']

```

## How to Use

### Overview

(TODO, outdated, need to be rewritten)

Generally, all you need to do is use `to_map/2` as follows `to_map(doc, spec)` where `doc` is a string, char_list, or xml record
as specified in `:xmerl`. `to_map/2` returns a `map`.

### Mapping from xml to Map

The second argument to `to_map/2`, should be a keyword list that can be in either of the following formats:

```elixir
XmlSugar.to_map(doc, label1: path1) # where label is a string or atom and path is a xpath string

XmlSugar.to_map(doc, label1: [path1, label11: path11, label12: path12, ...]) # where label is a string or atom and path is a string
```

The structure above can be nested arbitrarily deep.

### Label Types

As you saw earlier, the labels have strange symbols `&` and `[]`. This is to help us specify what type of result the mapping
will return.

- `&...` indicates value. Without this, mapping will return tuples that conform to Record definitions specified in xmerl. Note
that `&` is only valid if the path correspond to `xmlText`, `xmlComment`, `xmlPI`, `xmlAttribute`. This is why as shown above,
you need to use "./text()" to pull out the text node to use with `&`. Also you may want to try "./@some-attr" with `&` to get
the value of the attributes.

- `...[]` indicates list. With out this, you will only get the first node of the matched nodes.

## API

### `to_map/2`

This is the main function, probably the only one you'll ever need. Explained above.

### Helper Methods

In case you are lazy, you can use the following to get to what you want without dealing with `map`

#### `to_node/2`

same as `doc |> to_map("temp": spec) |> Map.get(:temp)`

#### `to_value/2`

same as `doc |> to_map("&temp": spec) |> Map.get(:temp)`

#### `to_list/2`

same as `doc |> to_map("temp[]": spec) |> Map.get(:temp)`

#### `to_list_of_values/2`

same as `doc |> to_map("&temp[]": spec) |> Map.get(:temp)`


## Examples

```xml
<?xml version="1.05" encoding="UTF-8"?>
<html>
  <head>
    <title>XML Parsing</title>
  </head>
  <body>
    <p>Neato</p>
    <ul>
      <li class="first star" data-index="1">First</li>
      <li class="second">Second</li>
      <li class="third">Third</li>
    </ul>
    <div>
      <ul>
        <li>Forth</li>
      </ul>
    </div>
    <div id="content">
      <header>Content Header</header>
      <span class="first badge odd" data-attr="first-half">One</span>
      <span class="badge" data-attr="first-half">Two</span>
      <span class="badge odd" data-attr="first-half">Three</span>
      <span class="badge" data-attr="first-half">Four</span>
      <span class="badge" data-attr="first-half">Five</span>
      <span class="badge">Six</span>
      <span class="badge">Seven</span>
      <span class="badge">Eight</span>
      <span class="badge">Nine</span>
      <span class="badge">Ten</span>
      <p class='nested-paragraph'>Hello there. <a>link</a></p>
      <p class="padded-paragraph">Another one. <a>link2</a> More stuff</p>
    </div>
    <special_match_key>first star</special_match_key>
  </body>
</html>
```

```iex
iex> doc = ... # as above
iex> import XmlSugar

iex> doc |> to_list_of_values("//li/text()")
['First', 'Second','Third', 'Forth']

iex> doc |> to_value("//li[@class='second']/text()")
'Second'

iex> doc |> to_node("//li[2]/text()")
{:xmlText, [li: 4, ul: 4, body: 4, html: 1], 1, [], 'Second', :text}

iex> doc |> to_map("&list_of_items[]": "//li/text()")
%{list_of_items: ['First', 'Second', 'Third', 'Forth']}

iex> doc |> to_map(
...>  "html": [
...>    "//html",
...>    "body": [
...>      "./body",
...>      "&p": "./p[1]/text()",
...>      "first_list[]": [
...>        "./ul/li",
...>        "&class": "./@class",
...>        "&data_attr": "./@data-attr",
...>        "&text": "./text()"
...>      ],
...>      "&second_list[]": "./div//li/text()"
...>    ]
...>  ],
...>  "&odd_badges_class_values[]": "//span[contains(@class, 'odd')]/@class",
...>  "&special_match": "//li[@class=ancestor::body/special_match_key]/text()"
...>)
%{
  html: %{
    body: %{
      p: 'Neato',
      first_list: [
        %{class: 'first star', data_attr: nil, text: 'First'},
        %{class: 'second', data_attr: nil, text: 'Second'},
        %{class: 'third', data_attr: nil, text: 'Third'}
      ],
      second_list: ['Forth']
    }
  },
  odd_badges_class_values: ['first badge odd', 'badge odd'],
  special_match: 'First'
}

```
