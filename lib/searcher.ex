defmodule Elindex.Searcher do
  def load_files do
    Agent.start_link(&load_all_files/0, name: :wikipedia)
  end

  def search(term) do
    Agent.get(:wikipedia, fn (data) ->
      Map.get(data, term, [])
      |> Enum.sort_by(fn({_,hits})-> hits end, &>=/2)
      |> Enum.take(10)
    end)
  end

  # [
  #    { "American football", [ "american", "football", ... ] },
  #    { "Snoop Dogg", [ "brussels", "belgium", ... ] }
  # ]
  def split_files() do
    File.ls!("sample")
    |> Enum.map(fn(filename) ->
      text = Path.join("sample", filename) |> File.read!
      title = String.split(text, "\n", parts: 2) |> List.first
      words = tokenize(text)
      {title, words}
    end)
  end

  # %{
  #   "waffles" => %{ "Snoop Dogg" => 5, ... },
  #   "traffic" => %{ "Snoop Dogg" => 2, ... }
  # }
  def load_all_files() do
    split_files()
    |> Enum.reduce(%{}, fn({title,words}, index)->
        Enum.reduce(words, index, fn(word, index) ->
          word_map = 
            Map.get(index, word, %{})
            |> Map.update(title, 1, &(&1 +1))
          Map.put(index, word, word_map)
        end)
      end)
  end

  def tokenize(text) do
    Regex.split(~r([^A-Za-z]+), String.downcase(text))
  end
end