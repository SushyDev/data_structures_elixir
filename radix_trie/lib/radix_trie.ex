defmodule RadixTrie do
  defmodule Node do
    defstruct prefix: [], value: nil, children: []
  end

  def new() do
    %RadixTrie.Node{}
  end

  def test(word \\ "test") do
    RadixTrie.lookup(RadixTrie.new(), word) |> IO.inspect
  end

  def get(tree, query) do
    node = RadixTrie.lookup(tree, query)

    case node do
      %Node{} -> node.value
      _ -> nil
    end
  end

  defp find_child(node, query) do
    Enum.find(node.children, fn child -> List.first(child.prefix) == List.first(query) end)
  end

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

    { _, querySuffix } = Enum.split(query, queryLastMatch)
    { _, nodeSuffix } = Enum.split(node.prefix, queryLastMatch)

    { common, querySuffix, nodeSuffix }
  end

  defp find_remaining_query(node, query) do
    mismatchPosition = node.prefix
      |> Enum.with_index()
      |> Enum.count(fn {letter, index} ->
        otherLetter = Enum.at(query, index) || nil
        letter == otherLetter
      end)

    remainingQuery = query
      |> Enum.with_index()
      |> Enum.filter(fn { _letter, index } -> index >= mismatchPosition end)
      |> Enum.map(fn { letter, _index } -> letter end)

    { remainingQuery, mismatchPosition }
  end

  def lookup(tree, string) do
    query = String.codepoints(string)
    lookup(tree, query, find_child(tree, query))
  end

  defp lookup(tree, query, node) do
    cond do
      List.first(query) == List.first(node.prefix) ->
        cond do
          query == node.prefix -> node
          true ->
            { _, querySuffix, _ } = find_common_prefix(node, query)
            foundChild = find_child(node, querySuffix)
            case foundChild do
              %Node{} -> lookup(tree, querySuffix, foundChild)
              _ -> nil
            end
        end
      true -> nil
    end
  end

  def insert(tree, query, value \\ true) do
    insert(tree, String.codepoints(query), value, tree)
  end

  defp insert(tree, query, value, node) do
    { commonPrefix, querySuffix, nodeSuffix } = find_common_prefix(node, query)

    cond do
      # The Node's prefix equals the SearchKey.
      length(nodeSuffix) == 0 && length(querySuffix) == 0 -> 
        %{ node | value: value }

      # Node.prefix is a prefix of query
      # Example: Node="te", Query="team". Common="te", Remainder="am".
      length(nodeSuffix) == 0 && length(querySuffix) > 0 ->
        IO.puts("node prefix: " <> List.to_string(node.prefix) <> " is prefix of query: " <> List.to_string(query))
        IO.puts("Finding child: " <> List.to_string(querySuffix) <> " inside " <> List.to_string(node.prefix))
        childNode = find_child(node, querySuffix)

        case childNode do
          nil ->
            newChild = [ %RadixTrie.Node{ prefix: querySuffix, value: value } ]
            updatedChildren = node.children ++ newChild
            %{ node | children: updatedChildren }
          %RadixTrie.Node{} ->
            newChild = [ insert(tree, querySuffix, value, childNode) ]
            updatedChildren = Enum.filter(node.children, fn child -> child.prefix != childNode.prefix end) ++ newChild
            %{ node | children: updatedChildren }
        end

      # Query is a prefix of node.prefix
      # Example: Node="team", Query="te". Common="te", NodeSuffix="am".
      length(nodeSuffix) > 0 && length(querySuffix) == 0 ->
        IO.puts("query: " <> List.to_string(query) <> " is prefix of node prefix: " <> List.to_string(node.prefix))
        # Create new parent with prefix
        %RadixTrie.Node{ prefix: commonPrefix, value: node.value, children: [
          # Truncated current node
          %{ node | prefix: nodeSuffix }
        ] }
      # Example: Node="test", Key="team". Common="te". NodeSuffix="st", KeySuffix="am".
      length(nodeSuffix) > 0 && length(querySuffix) > 0 ->
        IO.puts("Mismatch")
        %RadixTrie.Node{
          prefix: commonPrefix,
          value: nil,
          children: [
            %{ node | prefix: nodeSuffix },
            %RadixTrie.Node{ prefix: querySuffix },
          ],
        }
    end
  end
end

tree = RadixTrie.new()
IO.inspect(tree)
tree = RadixTrie.insert(tree, "team")
tree = RadixTrie.insert(tree, "test")
tree = RadixTrie.insert(tree, "testing")
tree = RadixTrie.insert(tree, "te")
IO.inspect(tree)
