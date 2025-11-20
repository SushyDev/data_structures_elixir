defmodule RadixTrie do
  defmodule Node do
    defstruct prefix: [], value: nil, children: %{}
  end

  def new() do
    %RadixTrie.Node{}
  end

  def get(tree, query) do
    case RadixTrie.lookup(tree, query) do
      nil -> nil
      %RadixTrie.Node{value: value} -> value
    end
  end

  def lookup(tree, query) do
    transformedQuery = String.codepoints(query)
    childNode = find_child(tree, transformedQuery)
    lookup(tree, transformedQuery, childNode)
  end

  def insert(tree, query, value \\ :is_leaf) do
    insert(tree, String.codepoints(query), value, tree)
  end

  defp find_child(node, query) do
    Map.get(node.children, List.first(query))
  end

  # Leave this to be optimized later bc this is terrible
  defp find_common_prefix(node, query) do
    queryLastMatch = query
      |> Enum.with_index()
      |> Enum.count(fn {letter, index} ->
        otherLetter = Enum.at(node.prefix, index) || nil
        letter == otherLetter
      end)

    common = query
      |> Enum.with_index()
      |> Enum.filter(fn { _letter, index } -> index < queryLastMatch end)
      |> Enum.map(fn { letter, _index } -> letter end)

    { _, query_suffix } = Enum.split(query, queryLastMatch)
    { _, node_suffix } = Enum.split(node.prefix, queryLastMatch)

    { common, query_suffix, node_suffix }
  end

  # This can also use optimization
  defp lookup(tree, query, node) do
    cond do
      List.first(query) == List.first(node.prefix) ->
        cond do
          query == node.prefix -> node
          true ->
            { _, query_suffix, _ } = find_common_prefix(node, query)
            foundChild = find_child(node, query_suffix)
            case foundChild do
              nil -> nil
              %Node{} -> lookup(tree, query_suffix, foundChild)
            end
        end
    end
  end

  defp insert(tree, query, value, node) do
    { common_prefix, query_suffix, node_suffix } = find_common_prefix(node, query)

    node_suffix_length = length(node_suffix)
    query_suffix_length = length(query_suffix)

    cond do
      # The Node's prefix equals the SearchKey.
      node_suffix_length == 0 && query_suffix_length == 0 -> 
        %{ node | value: value }

      # Node.prefix is a prefix of query
      # Example: Node="te", Query="team". Common="te", Remainder="am".
      node_suffix_length == 0 && query_suffix_length > 0 ->
        IO.puts("node prefix: " <> List.to_string(node.prefix) <> " is prefix of query: " <> List.to_string(query))
        IO.puts("Finding child: " <> List.to_string(query_suffix) <> " inside " <> List.to_string(node.prefix))
        # Create new child if not exists, else insert inside existing child recursively
        updated_children = Map.update(
          node.children,
          List.first(query_suffix),
          # 1. If key is missing, insert this:
          %RadixTrie.Node{prefix: query_suffix, value: value},
          # 2. If key exists, run this function on the existing child:
          fn child -> insert(tree, query_suffix, value, child) end
        )

        %{node | children: updated_children}

      # Query is a prefix of node.prefix
      # Example: Node="team", Query="te". Common="te", NodeSuffix="am".
      node_suffix_length > 0 && query_suffix_length == 0 ->
        IO.puts("query: " <> List.to_string(query) <> " is prefix of node prefix: " <> List.to_string(node.prefix))
        # Create new parent with prefix
        %RadixTrie.Node{ prefix: common_prefix, value: node.value, children: %{
          # Truncated current node
          List.first(node_suffix) => %{ node | prefix: node_suffix }
        } }
      # Example: Node="test", Key="team". Common="te". NodeSuffix="st", KeySuffix="am".
      node_suffix_length > 0 && query_suffix_length > 0 ->
        IO.puts("Mismatch")
        %RadixTrie.Node{ prefix: common_prefix, value: nil, children: %{
          # Truncated current node
          List.first(node_suffix) => %{ node | prefix: node_suffix },
          # New split node
          List.first(query_suffix) => %RadixTrie.Node{ prefix: query_suffix },
        } }
    end
  end
end

tree = RadixTrie.new()
IO.inspect(tree)
tree = RadixTrie.insert(tree, "team")
tree = RadixTrie.insert(tree, "test")
tree = RadixTrie.insert(tree, "testing", "a value")
tree = RadixTrie.insert(tree, "te")
tree = RadixTrie.insert(tree, "bruhbruh")
tree = RadixTrie.insert(tree, "bruh")
IO.inspect(tree)
RadixTrie.get(tree, "testing") |> IO.inspect
