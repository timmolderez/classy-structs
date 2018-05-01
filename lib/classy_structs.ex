defmodule Class do
  @moduledoc """
    Defines a few macros that add an inheritance and polymorphism mechanism on top of Elixir's structs,
    such that structs can be used as if they are (immutable) class instances.
    @author Tim Molderez
  """

  defmacro __using__(_opts) do
    quote do
      import Class
    end
  end

  @doc """
    Defines a new immutable class
    
    The defclass macro is similar in use to defmodule, except that you can also
    use the `var` macro to define fields, and the `extend` macro to specify superclasses.

    ## Examples
    
      defclass Animal do
        var weight: 10
        var speed: 20

        def sound() do
          ""
        end
      end

      defclass Dog do
        extends Animal
        var speed: 40
        var breed: "Greyhound"

        def sound() do
          "Woof!"
        end
      end
  """
  defmacro defclass(name, block) do
    block = elem(Keyword.get(block, :do), 2)

    fields = Enum.filter(block,
      fn(member) -> is_tuple(member) and elem(member, 0) == :var end)
    # Expand the "var" macros so we get a Keyword list
    fields = Enum.map(fields, 
      fn(field) -> Macro.expand(field,__CALLER__) end)

    methods = Enum.filter(block,
      fn(member) ->
        is_tuple(member) and elem(member, 0) != :var and elem(member, 0) != :extends
      end)
    
    extends = Enum.find(block,
      fn(member) -> is_tuple(member) and elem(member, 0) == :extends end)
    super_classes = if (extends != nil) do elem(extends, 2) else [] end

    IO.inspect __CALLER__
    all_fields = Enum.reduce(super_classes, fields, 
      fn(super_class,fields) ->
        super_instance = instantiate_class(super_class, __CALLER__)
        Enum.reduce(Map.from_struct(super_instance), fields, 
          fn({super_field_key, super_field_value}, fields) ->
            # Check if this field was already overridden
            if (Enum.find(fields, fn({field_key, _}) -> field_key == super_field_key end)) do
              fields
            else
              fields ++ [{super_field_key, super_field_value}]
            end
          end)
      end)

    # Generate a default constructor (if needed)
    methods = if (search_methods(methods, fn(name,arity) -> name == :new and arity == 0 end)) do
      methods
    else
      methods ++ [quote do
        def new() do
          unquote(name).__struct__
        end
      end]
    end

    all_methods = Enum.reduce(super_classes, methods,
      fn(super_class, methods) ->
        module = Macro.expand(super_class,__CALLER__)

        # Find out which functions we need to inherit
        functions = module.__info__(:functions)
        inherited_functions = Enum.filter(functions, fn{ name, arity } ->
          if (name == :new or name == :__struct__) do 
            false
          else
            search_methods(methods,
              fn(m_name, m_arity) -> 
                not (name == m_name and arity == m_arity)
              end)
          end
        end)

        # Construct defdelegate statements
        # Based on https://gist.github.com/orenbenkiki/5174435
        signatures = Enum.map(inherited_functions, 
          fn { name, arity } ->
            args = if arity == 0 do
              []
            else
              Enum.map 1 .. arity, fn(i) -> { gen_param_name(i), [], nil } end
            end
            { name, [], args }
        end)
        delegates = Enum.map(signatures, 
          fn(signature) ->
            quote do
              defdelegate unquote(signature), to: unquote(module)
            end
          end)
        methods ++ delegates  
      end)

    quote do
      defmodule unquote(name) do
        defstruct(
          unquote(all_fields)
        )

        unquote(all_methods)
      end
    end
  end

  @doc """
    Defines a new field in a class, with its default value
    (The default value cannot be an anonymous function.)

    ## Examples
    
      var species: "Mammal"
      var dimensions: [20, 40]
  """
  defmacro var([keyword]) do
    keyword
  end

  @doc """
    Call a function using dynamic dispatch

    The function is dispatched based on the type of the first argument.
    (To use static dispatch, use the `.` operator instead of `~>`.)

    ##Examples
    Animal~>walk(dog)
    Shape~>scale(square, 2.0)
  """
  defmacro _module ~> expr do
    IO.inspect expr
    receiver = List.first(elem(expr, 2))
    IO.inspect receiver
    quote do
      module = unquote(receiver).__struct__
      module.unquote(expr)
    end
  end

  # Create an instance of the given class
  defp instantiate_class(class, env) do
    module = Macro.expand(class, env)

    has_default_constructor = :erlang.function_exported(module, :new, 0)
    if (has_default_constructor) do
      module.new()
    else
      module.__struct__
    end
  end

  # Search for a specific method based on the given condition
  defp search_methods(methods, condition_fn) do
    Enum.find(methods, 
      fn(method) ->
        api = List.first(elem(method, 2))
        name = elem(api, 0)
        arity = length(elem(api, 2))
        condition_fn.(name, arity)
      end)
  end

  # Generates a parameter name given an index
  # Index 0 produces "a"; 1 produces "b"; 2 produces "c"; and so on
  defp gen_param_name(i) do
    # See https://stackoverflow.com/questions/41313995/elixir-convert-integer-to-unicode-character
    x = 97 + i # The UTF-8 code point for the letter "a" is 97
    String.to_atom(<<x::utf8>>)
  end
end