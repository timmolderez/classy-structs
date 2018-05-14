defmodule Class do
  @moduledoc """
  The `Class` module defines a few macros that provide object-oriented features, such as inheritance and polymorphism, on top of Elixir's structs.

  Additional documentation is available on the [Classy structs Github page](https://github.com/timmolderez/classy-structs#usage).
  
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
  use `var` to define fields, and `extends` to specify superclasses.

  Additional documentation is available on the [Classy structs Github page](https://github.com/timmolderez/classy-structs#usage).

  ## Examples
  ```Elixir
    defclass Animal do
      var weight: 0
      @abstract sound(Animal) :: String.t
    end

    defclass Dog do
      extends Animal
      var species: ""

      def new(species), do
    end
  ```
  """
  defmacro defclass(name, do: body) do
    # Retrieve the list of all class members
    block = if (macro_name(body) == :__block__) do
      elem(body, 2)
    else
      [body]
    end

    ### Class attributes

    attributes = Enum.filter(block,
      fn(member) -> is_tuple(member) and macro_name(member) == :@ end)
    # Rename any @abstract attributes to @callback
    attributes = Enum.map(attributes,
      fn(attribute) -> 
        if (attribute_name(attribute) == :abstract) do
          rename_attribute(attribute, :callback)
        else
          attribute
        end
      end)

    ### Super classes

    extends = Enum.find(block,
      fn(member) -> is_tuple(member) and elem(member, 0) == :extends end)
    super_classes = if (extends != nil) do elem(extends, 2) else [] end

    ### Class fields

    fields = Enum.filter(block,
      fn(member) -> is_tuple(member) and macro_name(member) == :var end)
    # Expand the "var" macros so we get a Keyword list
    fields = Enum.map(fields, 
      fn(field) -> Macro.expand(field,__CALLER__) end)

    # Include all inherited fields
    all_fields = Enum.reduce(super_classes, fields, 
      fn(super_class,fields) ->
        super_instance = instantiate_class(super_class, __CALLER__)
        Enum.reduce(Map.from_struct(super_instance), fields, 
          fn({super_field_key, super_field_value}, fields) ->
            # Check if this field was already overridden
            if (Enum.find(fields, fn({field_key, _}) -> field_key == super_field_key end)) do
              fields
            else
              fields ++ [{super_field_key, Macro.escape(super_field_value)}]
            end
          end)
      end)

    ### Class methods

    methods = Enum.filter(block,
      fn(member) ->
        is_tuple(member) 
        and (not Enum.member? [:@, :var, :extends, :__aliases__], macro_name(member))
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

    # Include all inherited methods
    all_methods = Enum.reduce(super_classes, methods,
      fn(super_class, methods) ->
        module = Macro.expand(super_class,__CALLER__)

        # Find out which functions we need to inherit
        functions = module.__info__(:functions)
        inherited_functions = Enum.filter(functions, fn{ name, arity } ->
          if (name == :new or name == :__struct__) do 
            false
          else
            overriding_method = search_methods(methods,
              fn(m_name, m_arity) -> 
                name == m_name and arity == m_arity
              end)
            if (overriding_method != nil) do
              false
            else
              true
            end
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

    behaviours = Enum.reduce(super_classes, [], fn(super_class, behaviours) ->
        module = Macro.expand(super_class,__CALLER__)
        # Only add a @behaviour for super classes with @callbacks
        if (function_exported?(module, :behaviour_info, 1)) do
          behaviour = quote do
            @behaviour unquote(super_class)
          end
          behaviours ++ [behaviour]
        else
          behaviours
        end
      end)

    quote do
      defmodule unquote(name) do
        defstruct(
          unquote(all_fields)
        )
        unquote(attributes)
        unquote(behaviours)
        unquote(all_methods)
      end
    end
  end

  @doc """
  Defines a new field in a class, with its default value
  (The default value cannot be an anonymous function.)

  ## Examples
  
  ```Elixir
    var species: "Mammal"
    var dimensions: [20, 40]
  ```
  """
  defmacro var([keyword]) do
    keyword
  end

  @doc """
  Call a function using dynamic dispatch

  The function is dispatched based on the type of the first argument.
  (To use static dispatch, use the `.` operator instead of `~>`.)

  ## Examples
    
  ```Elixir
    use Class

    defclass Animal do
      def sound(this), do: "..."
    end
    
    defclass Cat do
      extends Animal
      def sound(this), do: "Meow!"
    end

    c = Cat.new()
    Animal.sound(c)   # "..."
    Animal~>sound(c)  # "Meow!"
  ```
  """
  defmacro _module ~> expr do
    receiver = List.first(elem(expr, 2))
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
        arity = if (elem(api, 2) == nil) do
          0
        else
          length(elem(api, 2))
        end
        
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

  defp rename_attribute(attribute_ast, new_name) do
    body = elem(attribute_ast, 2)
    body_first = List.first(body)
    new_body_first = put_elem(body_first, 0, new_name)
    new_body = List.replace_at(body,0,new_body_first)
    put_elem(attribute_ast, 2, new_body)
  end

  # Given an AST of an attribute, get its name
  defp attribute_name(attribute_ast) do
    elem(List.first(elem(attribute_ast, 2)), 0)
  end

  # Given an AST representing the application of a macro,
  # get the name of that macro
  defp macro_name(ast) do
    elem(ast, 0)
  end
end