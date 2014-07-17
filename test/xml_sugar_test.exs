defmodule XmlSugarTest do
  use ExUnit.Case, async: true
  require XmlSugar
  import XmlSugar
  require Record
  import List, only: [first: 1]
  import TestHelpers

  setup do
    simple = File.read!("./test/files/simple.xml")
    complex = File.read!("./test/files/complex.xml")
    {:ok, [simple: simple, complex: complex]}
  end

  test "parse", %{simple: doc} do
    result = doc |> parse
    assert Record.record?(result, :xmlElement) == true
    assert xmlElement(result, :name) == :html
  end

  test "[xpath] get list of text nodes", %{simple: doc} do
    result = doc |> parse |> xpath("//li/text()") |> value
    assert result == ['First', 'Second','Third', 'Forth']
  end

  test "[xpath] get list of text nodes with attribute filter", %{simple: doc} do
    result = doc |> parse |> xpath("//li[@class='second']/text()") |> value
    assert result == ['Second']
  end

  test "[xpath] get list of text nodes with position filter", %{simple: doc} do
    result = doc |> parse |> xpath("//li[2]/text()") |> value
    assert result == ['Second']
  end

  test "[xpath] get list of text nodes with `last` filter", %{simple: doc} do
    result = doc |> parse |> xpath("//li[last()]/text()") |> value
    assert result == ['Forth']
  end

  test "working with attributes", %{simple: doc} do
    result = doc
    |> parse
    |> xpath("//body/ul/li")
    |> value(class: "./@class", data_index: "./@data-index")
    assert result == [
      [class: 'first star', data_index: '1'],
      [class: 'second', data_index: nil],
      [class: 'third', data_index: nil]
    ]

    result = doc
    |> parse
    |> xpath("//body/ul/li/@data-index/..")
    |> value(class: "./@class", data_index: "./@data-index")
    assert result == [
      [class: 'first star', data_index: '1']
    ]
  end

  test "get the first element of a list", %{simple: doc} do
    result = doc
    |> parse
    |> at_xpath("//title/text()")
    |> value
    assert result == 'XML Parsing'

    result = doc
    |> parse
    |> at_xpath("//li[1]/text()")
    |> value
    assert result == 'First'

    result = doc
    |> parse
    |> at_xpath("//p/text()")
    |> value
    assert result == 'Neato'

    result = doc
    |> parse
    |> xpath("//p/text()")
    |> first
    |> value
    assert result == 'Neato'
  end

  test "xpath descending", %{simple: doc} do
    result = doc
    |> parse
    |> xpath("//div[@id=\"content\"]/p")
    |> Enum.map(fn (p_node) ->
      p_node
      |> at_xpath("./a/text()")
      |> value
    end)
    assert result == ['link', 'link2']
  end

  test "at_xpath and single value", %{simple: doc} do
    result = doc
    |> parse
    |> at_xpath("//div[@id='content']/header/text()")
    |> value
    assert result == 'Content Header'

    result = doc
    |> parse
    |> at_xpath("//div[@id='content']/p")
    |> value(link: "./a/text()")
    assert result == [link: 'link']

    result = doc
    |> parse
    |> at_xpath("//div[@id='content']")
    |> value(links: ".//a/text()")
    assert result == [links: ['link', 'link2']]

    result = doc
    |> parse
    |> at_xpath("//div[@id='content']")
    |> value(links: ".//a")
    assert result == [
      links: [
        {:xmlElement, :a, :a, [], {:xmlNamespace, [], []}, [p: 24, div: 8, body: 4, html: 1], 2, [], [{:xmlText, [a: 2, p: 24, div: 8, body: 4, html: 1], 1, [], 'link', :text}], [], :undefined, :undeclared},
        {:xmlElement, :a, :a, [], {:xmlNamespace, [], []}, [p: 26, div: 8, body: 4, html: 1], 2, [], [{:xmlText, [a: 2, p: 26, div: 8, body: 4, html: 1], 1, [], 'link2', :text}], [], :undefined, :undeclared}
      ]
    ]
  end

  test "nested xpath collection", %{simple: doc, complex: doc2} do

    result = doc
    |> parse
    |> value(first_list: "//body/ul", second_list: "//div/ul")
    |> Enum.map(fn ({label, node}) ->
      {label, node |> xpath("./li") |> value(text: "./text()", text2: "./text()")}
    end)
    assert result == [
      first_list: [
        [text: 'First', text2: 'First'],
        [text: 'Second', text2: 'Second'],
        [text: 'Third', text2: 'Third']
      ],
      second_list: [
        [text: 'Forth', text2: 'Forth']
      ]
    ]

    result = doc
    |> parse
    |> xpath("//div[@id='content']/p")
    |> value(link: "./a/text()", text: "./text()")
    assert result == [
      [link: 'link', text: 'Hello there. '],
      [link: 'link2', text: ['Another one. ', ' More stuff']]
    ]

    result = doc2
    |> parse
    |> xpath("//matchups/matchup/is_tied[contains(., '0')]/..")
    |> value(
      week: "./week/text()",
      winner_team_key: "./winner_team_key/text()",
      teams: "./teams/team"
    )
    |> Enum.map(fn (matchup) ->
      [
        week: matchup[:week],
        winner_team_key: matchup[:winner_team_key],
        teams: matchup[:teams] |> value(name: "./name/text()", key: "./team_key/text()")
      ]
    end)
    assert result == [
      [
        week: '16',
        winner_team_key: '273.l.239541.t.1',
        teams: [
          [name: 'Asgardian Warlords', key: '273.l.239541.t.1'],
          [name: 'yourgoindown220', key: '273.l.239541.t.2']
        ]
      ],
      [
        week: '16',
        winner_team_key: '273.l.239541.t.4',
        teams: [
          [name: '187 she wrote', key: '273.l.239541.t.4'],
          [name: 'bleedgreen', key: '273.l.239541.t.6']
        ]
      ],
      [
        week: '16',
        winner_team_key: '273.l.239541.t.9',
        teams: [
          [name: 'Thunder Ducks', key: '273.l.239541.t.5'],
          [name: 'jo momma', key: '273.l.239541.t.9']
        ]
      ],
      [
        week: '16',
        winner_team_key: '273.l.239541.t.10',
        teams: [
          [name: 'bingo_door', key: '273.l.239541.t.8'],
          [name: 'The Dude Abides', key: '273.l.239541.t.10']
        ]
      ]
    ]
  end

  test "complex", %{complex: doc} do
    # a list of matches that have clear winner
    # with matches having week, winner info, and loser info
    result = doc
    |> parse
    |> xpath("//matchups/matchup/is_tied[contains(., '0')]/..")
    |> value(
      week: "./week/text()",
      winner_team_key: "./winner_team_key/text()",
      teams: "./teams/team"
    )
    |> Enum.map(fn (matchup) ->
      teams = matchup[:teams]
      |> value(name: "./name/text()", key: "./team_key/text()")

      winner_team_key = matchup[:winner_team_key]

      winner = teams |> Enum.find(fn (team) -> team[:key] == winner_team_key end)
      loser = teams |> Enum.find(fn (team) -> team[:key] != winner_team_key end)
      [
        week: matchup[:week],
        winner: winner,
        loser: loser
      ]
    end)
    |> tap(fn (result) ->
      assert result == [
        [
          week: '16',
          winner: [name: 'Asgardian Warlords', key: '273.l.239541.t.1'],
          loser: [name: 'yourgoindown220', key: '273.l.239541.t.2']
        ],
        [
          week: '16',
          winner: [name: '187 she wrote', key: '273.l.239541.t.4'],
          loser: [name: 'bleedgreen', key: '273.l.239541.t.6']
        ],
        [
          week: '16',
          winner: [name: 'jo momma', key: '273.l.239541.t.9'],
          loser: [name: 'Thunder Ducks', key: '273.l.239541.t.5']
        ],
        [
          week: '16',
          winner: [name: 'The Dude Abides', key: '273.l.239541.t.10'],
          loser: [name: 'bingo_door', key: '273.l.239541.t.8']
        ]
      ]
    end)
    |> Enum.reduce HashDict.new, fn (matchup, accumulator) ->
      winner_name = matchup[:winner][:name]
      loser_name = matchup[:loser][:name]
      unless HashDict.has_key?(accumulator, winner_name) do
        accumulator = HashDict.put(accumulator, winner_name, %{wins: 0, loses: 0})
      end
      unless HashDict.has_key?(accumulator, loser_name) do
        accumulator = HashDict.put(accumulator, loser_name, %{wins: 0, loses: 0})
      end

      {_, accumulator} = get_and_update_in(accumulator, [winner_name, :wins], &{&1, &1 + 1})
      {_, accumulator} = get_and_update_in(accumulator, [loser_name, :loses], &{&1, &1 + 1})

      accumulator
    end

    assert HashDict.to_list(result) == [
      {'Asgardian Warlords', %{loses: 0, wins: 1}},
      {'yourgoindown220', %{loses: 1, wins: 0}},
      {'187 she wrote', %{loses: 0, wins: 1}},
      {'Thunder Ducks', %{loses: 1, wins: 0}},
      {'The Dude Abides', %{loses: 0, wins: 1}},
      {'jo momma', %{loses: 0, wins: 1}},
      {'bleedgreen', %{loses: 1, wins: 0}},
      {'bingo_door', %{loses: 1, wins: 0}}
    ]

    result = doc
    |> parse
    |> xpath("//matchups/matchup/is_tied[contains(., '0')]/..")
    |> value(
      week: "./week/text()",
      winner: "./teams/team/team_key[.=ancestor::matchup/winner_team_key]/..",
      loser: "./teams/team/team_key[.!=ancestor::matchup/winner_team_key]/.."
    )
    |> update(
      winner: [name: "./name/text()", key: "./team_key/text()"],
      loser: [name: "./name/text()", key: "./team_key/text()"]
    )

    assert result == [
      [
        week: '16',
        winner: [name: 'Asgardian Warlords', key: '273.l.239541.t.1'],
        loser: [name: 'yourgoindown220', key: '273.l.239541.t.2']
      ],
      [
        week: '16',
        winner: [name: '187 she wrote', key: '273.l.239541.t.4'],
        loser: [name: 'bleedgreen', key: '273.l.239541.t.6']
      ],
      [
        week: '16',
        winner: [name: 'jo momma', key: '273.l.239541.t.9'],
        loser: [name: 'Thunder Ducks', key: '273.l.239541.t.5']
      ],
      [
        week: '16',
        winner: [name: 'The Dude Abides', key: '273.l.239541.t.10'],
        loser: [name: 'bingo_door', key: '273.l.239541.t.8']
      ]
    ]
  end

  test "xpath simple values", %{simple: doc} do
    result = doc
    |> parse
    |> xpath("//div[@id=\"content\"]/p/a/text()")
    |> value
    assert result == ['link', 'link2']

    result = doc
    |> parse
    |> xpath("//div[@id=\"content\"]/p")
    |> Enum.map(fn(p) -> xpath(p, "./text()") end)
    |> Enum.map(fn(t) -> first(t) end)
    |> value
    assert result == ['Hello there. ', 'Another one. ']
  end

  test "xpath values with mapping", %{simple: doc} do
    result = doc
    |> parse
    |> value(
      header: "//div[@id=\"content\"]/header/text()",
      first_badge: "//div[@id=\"content\"]/span[@class=\"first badge odd\"]/text()"
    )
    assert result == [header: 'Content Header', first_badge: 'One']

    result = doc
    |> parse
    |> xpath("//div[@id=\"content\"]")
    |> value(
      header: "./header/text()",
      first_badge: "./span[@class=\"first badge odd\"]/text()"
    )
    assert result == [[header: 'Content Header', first_badge: 'One']]
  end
end
