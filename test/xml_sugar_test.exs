defmodule XmlSugarTest do
  use ExUnit.Case, async: true
  import XmlSugar
  require Record

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

  test "xpath sigil" do
    # default = node
    assert ~x"//header/text()" == {:xpath, "//header/text()", ''}

    # value
    assert ~x"//header/text()"e == {:xpath, "//header/text()", 'e'}

    # list (node)
    assert ~x"//header/text()"l == {:xpath, "//header/text()", 'l'}

    # list (value)
    assert ~x"//header/text()"el == {:xpath, "//header/text()", 'el'}
    assert ~x"//header/text()"le == {:xpath, "//header/text()", 'el'}
  end

  test "spec processing modifiers" do
    assert process_spec(first_p: ~x"//p") == [first_p: [path: '//p', is_list: false, is_value: true, children: []]]
    assert process_spec(first_p: ~x"//p"e) == [first_p: [path: '//p', is_list: false, is_value: false, children: []]]
    assert process_spec(first_p: ~x"//p"l) == [first_p: [path: '//p', is_list: true, is_value: true, children: []]]
    assert process_spec(first_p: ~x"//p"el) == [first_p: [path: '//p', is_list: true, is_value: false, children: []]]
  end

  test "spec processing nested" do
    result = process_spec(
      first_p: [
        ~x"//p"l,
        name: ~x"./name",
        key: ~x"./key"
      ],
      second_p: ~x"//p/text()",
      third_p: [
        ~x"//p",
        teams: [
          ~x".//team"l,
          name: ~x"./name/text()"
        ]
      ]
    )

    assert result == [
      first_p: [
        path: '//p',
        is_list: true,
        is_value: true,
        children: [
          name: [
            path: './name',
            is_list: false,
            is_value: true,
            children: []
          ],
          key: [
            path: './key',
            is_list: false,
            is_value: true,
            children: []
          ]
        ]
      ],
      second_p: [
        path: '//p/text()',
        is_list: false,
        is_value: true,
        children: []
      ],
      third_p: [
        path: '//p',
        is_list: false,
        is_value: true,
        children: [
          teams: [
            path: './/team',
            is_list: true,
            is_value: true,
            children: [
              name: [
                path: './name/text()',
                is_list: false,
                is_value: true,
                children: []
              ]
            ]
          ]
        ]
      ]
    ]
  end

  test "to_map single level", %{simple: doc} do
    result = doc
    |> to_map(header: ~x"//header/text()"e)
    assert result == %{
      header: {:xmlText, [header: 2, div: 8, body: 4, html: 1], 1, [], 'Content Header', :text}
    }

    result = doc
    |> to_map(header: ~x"//header/text()")
    assert result == %{header: 'Content Header'}

    result = doc
    |> to_map(badges: ~x"//span[contains(@class,'badge')][@data-attr='first-half']/text()"l)
    assert result == %{
      badges: ['One', 'Two', 'Three', 'Four', 'Five']
    }

    result = doc
    |> to_map(
      header: ~x"//header/text()",
      badges: ~x"//span[contains(@class,'badge')][@data-attr='first-half']/text()"l
    )
    assert result == %{
      header: 'Content Header',
      badges: ['One', 'Two', 'Three', 'Four', 'Five']
    }
  end

  test "to_map multiple level", %{simple: doc} do
    result = doc
    |> to_map(
      content: [
        ~x"//div[@id='content']",
        badges: ~x"//span[contains(@class,'badge')][@data-attr!='first-half']/text()"l
      ]
    )
    assert result == %{
      content: %{
        badges: ['Six', 'Seven', 'Eight', 'Nine', 'Ten']
      }
    }

    result = doc
    |> to_map(
      header: ~x"//header/text()",
      content: [
        ~x"//div[@id='content']",
        first_non_first_half_badge: ~x"//span[contains(@class,'badge')][@data-attr!='first-half']/text()"
      ]
    )
    assert result == %{
      header: 'Content Header',
      content: %{
        first_non_first_half_badge: 'Six'
      }
    }
  end

  test "reuse returned nodes", %{simple: doc} do
    result = doc
    |> to_map(list: ~x"//li"l)
    |> Map.get(:list)
    |> Enum.map(fn (li_node) ->
      to_map(li_node, text: ~x"./text()") |> Map.get(:text)
    end)
    assert result == ['First', 'Second', 'Third', 'Forth']
  end

  test "working with attributes", %{simple: doc} do
    result = doc
    |> to_map(
      list: [
        ~x"//body/ul/li"l,
        class: ~x"./@class",
        data_index: ~x"./@data-index"
      ]
    )
    assert result == %{
      list: [
        %{class: 'first star', data_index: '1'},
        %{class: 'second', data_index: nil},
        %{class: 'third', data_index: nil}
      ]
    }

    result = doc
    |> to_map(
      list_item_with_data_index: [
        ~x"//body/ul/li/@data-index/..",
        class: ~x"./@class",
        data_index: ~x"./@data-index"
      ]
    )
    assert result == %{
      list_item_with_data_index: %{class: 'first star', data_index: '1'}
    }
  end

  test "convenience functions", %{simple: doc} do
    result = doc |> get(~x"//header/text()")
    assert result == 'Content Header'

    result = doc |> get(~x"//header/text()"e)
    assert result == {:xmlText, [header: 2, div: 8, body: 4, html: 1], 1, [], 'Content Header', :text}

    result = doc |> get(~x"//span[contains(@class,'badge')][@data-attr='first-half']/text()"el)
    assert result == [
      {:xmlText, [span: 4, div: 8, body: 4, html: 1], 1, [], 'One', :text},
      {:xmlText, [span: 6, div: 8, body: 4, html: 1], 1, [], 'Two', :text},
      {:xmlText, [span: 8, div: 8, body: 4, html: 1], 1, [], 'Three', :text},
      {:xmlText, [span: 10, div: 8, body: 4, html: 1], 1, [], 'Four', :text},
      {:xmlText, [span: 12, div: 8, body: 4, html: 1], 1, [], 'Five', :text}
    ]

    result = doc |> get(~x"//span[contains(@class,'badge')][@data-attr='first-half']/text()"l)
    assert result == ['One', 'Two', 'Three', 'Four', 'Five']


    result = doc |> get(~x"//li"l) |> Enum.map &(&1 |> get(~x"./text()"))
    assert result == ['First', 'Second', 'Third', 'Forth']
  end

  test "complex parsing", %{complex: doc} do
    result = doc
    |> to_map(
      matchups: [
        ~x"//matchups/matchup/is_tied[contains(., '0')]/.."l,
        week: ~x"./week/text()",
        winner: [
          ~x"./teams/team/team_key[.=ancestor::matchup/winner_team_key]/..",
          name: ~x"./name/text()",
          key: ~x"./team_key/text()"
        ],
        loser: [
          ~x"./teams/team/team_key[.!=ancestor::matchup/winner_team_key]/..",
          name: ~x"./name/text()",
          key: ~x"./team_key/text()"
        ],
        teams: [
          ~x"./teams/team"l,
          name: ~x"./name/text()",
          key: ~x"./team_key/text()"
        ]
      ]
    )
    assert result == %{
      matchups: [
        %{
          week: '16',
          winner: %{name: 'Asgardian Warlords', key: '273.l.239541.t.1'},
          loser: %{name: 'yourgoindown220', key: '273.l.239541.t.2'},
          teams: [
            %{name: 'Asgardian Warlords', key: '273.l.239541.t.1'},
            %{name: 'yourgoindown220', key: '273.l.239541.t.2'}
          ]
        },
        %{
          week: '16',
          winner: %{name: '187 she wrote', key: '273.l.239541.t.4'},
          loser: %{name: 'bleedgreen', key: '273.l.239541.t.6'},
          teams: [
            %{name: '187 she wrote', key: '273.l.239541.t.4'},
            %{name: 'bleedgreen', key: '273.l.239541.t.6'}
          ]
        },
        %{
          week: '16',
          winner: %{name: 'jo momma', key: '273.l.239541.t.9'},
          loser: %{name: 'Thunder Ducks', key: '273.l.239541.t.5'},
          teams: [
            %{name: 'Thunder Ducks', key: '273.l.239541.t.5'},
            %{name: 'jo momma', key: '273.l.239541.t.9'}
          ]
        },
        %{
          week: '16',
          winner: %{name: 'The Dude Abides', key: '273.l.239541.t.10'},
          loser: %{name: 'bingo_door', key: '273.l.239541.t.8'},
          teams: [
            %{name: 'bingo_door', key: '273.l.239541.t.8'},
            %{name: 'The Dude Abides', key: '273.l.239541.t.10'}
          ]
        }
      ]
    }
  end

  test "complex parsing and processing", %{complex: doc} do
    result = doc
    |> get(
      ~x"//matchups/matchup/is_tied[contains(., '0')]/.."l,
      week: ~x"./week/text()",
      winner: [
        ~x"./teams/team/team_key[.=ancestor::matchup/winner_team_key]/..",
        name: ~x"./name/text()",
        key: ~x"./team_key/text()"
      ],
      loser: [
        ~x"./teams/team/team_key[.!=ancestor::matchup/winner_team_key]/..",
        name: ~x"./name/text()",
        key: ~x"./team_key/text()"
      ],
      "teams[]": [
        ~x"./teams/team"l,
        name: ~x"./name/text()",
        key: ~x"./team_key/text()"
      ]
    )
    |> Enum.reduce %{}, fn(matchup, stat) ->
      winner_name = matchup[:winner][:name]
      loser_name = matchup[:loser][:name]
      stat = Map.put_new(stat, winner_name, %{wins: 0, loses: 0})
      stat = Map.put_new(stat, loser_name, %{wins: 0, loses: 0})

      {_, stat} = get_and_update_in(stat, [winner_name, :wins], &{&1, &1 + 1})
      {_, stat} = get_and_update_in(stat, [loser_name, :loses], &{&1, &1 + 1})

      stat
    end

    assert result == %{
      'Asgardian Warlords' => %{loses: 0, wins: 1},
      'yourgoindown220' => %{loses: 1, wins: 0},
      '187 she wrote' => %{loses: 0, wins: 1},
      'Thunder Ducks' => %{loses: 1, wins: 0},
      'The Dude Abides' => %{loses: 0, wins: 1},
      'jo momma' => %{loses: 0, wins: 1},
      'bleedgreen' => %{loses: 1, wins: 0},
      'bingo_door' => %{loses: 1, wins: 0}
    }
  end

  test "read me examples", %{simple: simple_doc} do
    doc = File.read!("test/files/readme_example.xml")

    # get the name of the first match
    result = doc |> XmlSugar.get(~x"//matchup/name/text()") # `x` marks sigil for (x)path
    assert result == 'Match One'

    # get the xml record of the name fo the first match
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

    # get a map with lots of nesting
    result = simple_doc |> XmlSugar.to_map(
      html: [
        ~x"//html",
        body: [
          ~x"./body",
          p: ~x"./p[1]/text()",
          first_list: [
            ~x"./ul/li"l,
            class: ~x"./@class",
            data_attr: ~x"./@data-attr",
            text: ~x"./text()"
          ],
          second_list: ~x"./div//li/text()"l
        ]
      ],
      odd_badges_class_values: ~x"//span[contains(@class, 'odd')]/@class"l,
      special_match: ~x"//li[@class=ancestor::body/special_match_key]/text()"
    )

    assert result == %{
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
  end

end
