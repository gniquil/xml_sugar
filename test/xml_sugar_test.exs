defmodule XmlSugarTest do
  use ExUnit.Case
  require XmlSugar
  import XmlSugar.Transformer, only: [transform: 1]

  @xml_doc """
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
  """

  test "[xpath] get list of text nodes" do
    node_list = XmlSugar.xpath(@xml_doc, "//li/text()") |> Enum.map &(&1.value)
    assert node_list == ['First', 'Second','Third', 'Forth']
  end

  test "[xpath] get list of text nodes with attribute filter" do
    node_list = XmlSugar.xpath(@xml_doc, "//li[@class='second']/text()") |> Enum.map &(&1.value)
    assert node_list == ['Second']
  end

  test "[xpath] get list of text nodes with position filter" do
    node_list = XmlSugar.xpath(@xml_doc, "//li[2]/text()") |> Enum.map &(&1.value)
    assert node_list == ['Second']
  end

  test "[xpath] get list of text nodes with `last` filter" do
    node_list = XmlSugar.xpath(@xml_doc, "//li[last()]/text()") |> Enum.map &(&1.value)
    assert node_list == ['Forth']
  end

  test "[xpath] get list of text nodes from anywhere" do
    node_list = XmlSugar.xpath(@xml_doc, "//li/text()") |> Enum.map &(&1.value)
    assert node_list == ['First', 'Second', 'Third', 'Forth']
  end

  test "[xpath] get list of attributes" do
    node_list = XmlSugar.xpath(@xml_doc, "//li[@data-index]")
    assert length(node_list) == 1
    attributes = List.first(node_list).attributes
      |> Enum.map fn (attribute) ->
        attribute.value
      end
    assert attributes == ['first star', '1']
  end

  test "[xpath] get text node short cut" do
    node_list = XmlSugar.xpath(@xml_doc, "//li")
                  |> Enum.map &(&1.text)
    assert node_list == ['First', 'Second', 'Third', 'Forth']
  end

  test "[xpath] get the first element of a list" do
    assert XmlSugar.at_xpath(@xml_doc, "//title/text()").value == 'XML Parsing'
    assert XmlSugar.at_xpath(@xml_doc, "//li[1]").text == 'First'
    assert XmlSugar.at_xpath(@xml_doc, "//p").text == 'Neato'
  end

  test "[css] simple" do
    result = XmlSugar.css(@xml_doc, "li") |> Enum.map &(&1.text)
    assert result == ['First', 'Second', 'Third', 'Forth']
  end

  test "[css] any descendant" do
    result = XmlSugar.css(@xml_doc, "div li") |> Enum.map &(&1.text)
    assert result == ['Forth']
  end

  test "[css] mixed entity and class" do
    result = XmlSugar.css(@xml_doc, "li.second") |> Enum.map &(&1.text)
    assert result == ['Second']

    assert XmlSugar.at_css(@xml_doc, "li.second").text == 'Second'
  end

  test "[css] class shortcut" do
    result = XmlSugar.css(@xml_doc, ".second") |> Enum.map &(&1.text)
    assert result == ['Second']

    assert XmlSugar.at_css(@xml_doc, ".second").text == 'Second'
  end

  test "[css] class short multiple" do
    result = XmlSugar.css(@xml_doc, ".badge.odd") |> Enum.map &(&1.text)
    assert result == ['One', 'Three']

    assert XmlSugar.at_css(@xml_doc, ".badge.odd").text == 'One'
  end

  test "[css] exact attribute match" do
    result = XmlSugar.css(@xml_doc, "li[data-index='1']") |> Enum.map &(&1.text)
    assert result == ['First']

    assert XmlSugar.at_css(@xml_doc, "li[data-index='1']").text == 'First'
  end

  test "[css] substring" do
    result = XmlSugar.css(@xml_doc, "li[class*='s']") |> Enum.map &(&1.text)
    assert result == ['First', 'Second']
  end

  test "[css] attribute existence" do
    result = XmlSugar.css(@xml_doc, "li[data-index]") |> Enum.map &(&1.text)
    assert result == ['First']
  end

  test "[css] mixed attribute and class" do
    result = XmlSugar.css(@xml_doc, "li.star[data-index='1']") |> Enum.map &(&1.text)
    assert result == ['First']
  end

  test "[css] muliple direct descendant" do
    result = XmlSugar.css(@xml_doc, "div > ul > li") |> Enum.map &(&1.text)
    assert result == ['Forth']
  end

  test "[css] mixed pseudo selector id, and class" do
    result = XmlSugar.css(@xml_doc, "#content .badge:first-child") |> Enum.map &(&1.text)
    assert result == ['One']
  end

  test "[css] :first-child :last-child" do
    result = XmlSugar.css(@xml_doc, "#content *:first-child") |> Enum.map &(&1.text)
    assert result == ['Content Header']
    assert XmlSugar.at_css(@xml_doc, "#content *:first-child").text == 'Content Header'
    assert XmlSugar.css(@xml_doc, "#content li:last-child") |> Enum.map &(&1.text) == ['Ten']
    XmlSugar.css(@xml_doc, "#content li:last-child")
      |> Enum.map fn (node) -> IO.puts node end
  end

  test "[css] :nth-child even" do
    result = XmlSugar.css(@xml_doc, ".badge:nth-child(even)") |> Enum.map &(&1.text)
    assert result == ['Two', 'Four', 'Six', 'Eight', 'Ten']
  end

  test "[css] :nth-child odd" do
    result = XmlSugar.css(@xml_doc, ".badge:nth-child(odd)") |> Enum.map &(&1.text)
    assert result == ['One', 'Three', 'Five', 'Seven', 'Nine']
  end

  test "[css] contains" do
    result = XmlSugar.css(@xml_doc, "*[data-attr~='first-half']") |> Enum.map &(&1.text)
    assert result == ['One', 'Two', 'Three', 'Four', 'Five']

    result = XmlSugar.css(@xml_doc, "*[class~='first']") |> Enum.map &(&1.text)
    assert result == ['First', 'One']
  end

  # ends is not supported since ends-with gives the following error:
  # ** (exit) {:not_a_core_function, :ends-with}
  # test "[css] ends with" do
  #   result = XmlSugar.css(@xml_doc, "li[class$='d']") |> Enum.map &(&1.text)
  #   assert result == ['First', 'Second']
  # end
end
