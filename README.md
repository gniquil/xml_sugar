XmlSugar
========

This is a simple Elixir sugar wrapper around `:xmerl`. What it adds is css selectors.

## Usage

Given a xml document such as below

```xml
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
    </div>
  </body>
</html>
```
We can do the following

```iex
iex> doc = ...[defined above]...
iex> XmlSugar.xpath(doc, "//li[@class='second']") |> Enum.map &(&1.text)
['Second']
iex> XmlSugar.at_xpath(doc, "//li[@class='second']").text
'Second'
iex> XmlSugar.css(doc, "li") |> Enum.map &(&1.text)
['First', 'Second', 'Third', 'Forth']
iex> XmlSugar.at_css(doc, '#content .badge:first-child').text
'One'
```

## Specifics

To be more specific, both `xpath` and `css` returns a list of `XmlSugar.Element` or
`XmlSugar.Text`, both of which has a convenient accessor `.text`. If the current node is a text node or it has only singular text node child, then `.text` will contain the text value.

```iex
iex> XmlSugar.css(doc, ".badge.odd")
[%XmlSugar.Element{attributes: [%XmlSugar.Attribute{entity_type: :xmlAttribute,
    expanded_name: [], language: [], name: :class, namespace: [],
    normalized: false, nsinfo: [], parents: [span: 4, div: 8, body: 4, html: 1],
    pos: 1, value: 'first badge odd'},
   %XmlSugar.Attribute{entity_type: :xmlAttribute, expanded_name: [],
    language: [], name: :"data-attr", namespace: [], normalized: false,
    nsinfo: [], parents: [span: 4, div: 8, body: 4, html: 1], pos: 2,
    value: 'first-half'}],
  content: [%XmlSugar.Text{entity_type: :xmlText,
    parents: [span: 4, div: 8, body: 4, html: 1], pos: 1, type: :text,
    value: 'One'}], entity_type: :xmlElement, expanded_name: :span, name: :span,
  parents: [div: 8, body: 4, html: 1], pos: 4, text: 'One'},
 %XmlSugar.Element{attributes: [%XmlSugar.Attribute{entity_type: :xmlAttribute,
    expanded_name: [], language: [], name: :class, namespace: [],
    normalized: false, nsinfo: [], parents: [span: 8, div: 8, body: 4, html: 1],
    pos: 1, value: 'badge odd'},
   %XmlSugar.Attribute{entity_type: :xmlAttribute, expanded_name: [],
    language: [], name: :"data-attr", namespace: [], normalized: false,
    nsinfo: [], parents: [span: 8, div: 8, body: 4, html: 1], pos: 2,
    value: 'first-half'}],
  content: [%XmlSugar.Text{entity_type: :xmlText,
    parents: [span: 8, div: 8, body: 4, html: 1], pos: 1, type: :text,
    value: 'Three'}], entity_type: :xmlElement, expanded_name: :span,
  name: :span, parents: [div: 8, body: 4, html: 1], pos: 8, text: 'Three'}]
```


`at_xpath` and `at_css` simply returns the first node of the result.

Note that css selector is not a full implementation of the css3 selector. It is simply
a select few of the commonly used ones transformed into xpath. Obviously xpath is
limited to what's only available in :xmerl. Therefore xpath functions such as
`ends-with`, `substring`, and many others are not available. Take a look at the tests
to get a sense of what it can do.

Below are some more examples

```iex

```

