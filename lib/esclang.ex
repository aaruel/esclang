defmodule Esclang do
    
end

defmodule Esclang.BF do
    defp new_loop(s \\ %{}, l \\ 0) do
        %{scripts: s, level: l}
    end

    defp new_machine(p \\ 0, b \\ %{}, l \\ new_loop()) do
        %{pointer: p, buffer: b, loop: l}
    end

    defp arith_pointer(%{pointer: p, buffer: b, loop: l}, input, op) do
        {new_machine(op.(p, 1), b, l), input}
    end

    defp arith(%{pointer: p, buffer: b, loop: l}, input, op) do
        n = b |> Map.get(p, 0) |> op.(1)
        {new_machine(p, b |> Map.put(p, n), l), input}
    end

    defp put_char(%{pointer: p, buffer: b, loop: l}, input) do
        <<b |> Map.get(p, 0)>> |> IO.write
        {new_machine(p, b, l), input}
    end

    defp after_matching_bracket(input, nested \\ false, level \\ 0) do
        {current, tail} = input |> String.split_at(1)
        cond do
            !nested ->
                case current do
                    "]" -> tail
                    "[" -> after_matching_bracket(tail, true, level + 1)
                    _ -> after_matching_bracket(tail)
                end
            level > 0 ->
                case current do
                    "]" -> after_matching_bracket(tail, true, level - 1)
                    "[" -> after_matching_bracket(tail, true, level + 1)
                    _ -> after_matching_bracket(tail, true, level)
                end
            true ->
                tail
        end
    end

    defp start_loop(%{pointer: p, buffer: b, loop: l}, input) do
        n = b |> Map.get(p, 0)
        if n != 0 do
            {level, l} = l |> Map.get_and_update!(:level, fn e -> {e + 1, e + 1} end)
            l = l |> Map.update!(:scripts, fn e ->
                e |> Map.put(level, input)
            end)
            {new_machine(p, b, l), input}
        else
            IO.puts('\n')
            {new_machine(p, b, l), after_matching_bracket(input)}
        end
    end

    defp end_loop(%{pointer: p, buffer: b, loop: l}, input) do
        {level, l} = l |> Map.get_and_update!(:level, fn e -> {e, e - 1} end)
        input = l |> Map.get(:scripts) |> Map.get(level)
        {new_machine(p, b, l), "[" <> input}
    end

    defp start(input, machine) do
        if (input |> String.length) > 0 do
            {current, tail} = input |> String.split_at(1)
            {u_machine, u_input} = case current do
                ">" -> arith_pointer(machine, tail, &+/2)
                "<" -> arith_pointer(machine, tail, &-/2)
                "+" -> arith(machine, tail, &+/2)
                "-" -> arith(machine, tail, &-/2)
                "." -> put_char(machine, tail)
                "," -> {machine, tail}
                "[" -> start_loop(machine, tail)
                "]" -> end_loop(machine, tail)
            end
            start(u_input, u_machine)
        else
            :ok
        end
    end

    def interpret(input) do
        start(input, new_machine())
    end
end
