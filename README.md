# Classy structs

*Classy structs* adds inheritance and polymorphism mechanisms on top of Elixir's structs, so they can be used in an object-oriented manner.


```Elixir
  use Class

  defclass Animal do
    var speed:40

    def sound(this) do
      "..."
    end
  end
```
```Elixir
  use Class

  defclass Dog do
    extends Animal

    var breed: ""
    var happy: true

    def new(dog_breed) do
      %Dog{breed: dog_breed}
    end

    def sound(this) do
      if (this.happy) do
        "Woof!"
      else
        "Grrr ruff!"
      this.sound
    end
  end
```

```
  iex> dog = Dog.new("Greyhound")
  %Dog{breed: "Greyhound", speed: 40}
  
  iex> Animal.sound(cat)
  "..."
```

You can create subclasses:




```Elixir
  use Class

  defclass Dog do
    extends Animal

    var species: ""

    def new(s) do
      %Dog{species: s}
    end

    def sound() do "Woof!" end
  end
```

This tiny macro library is designed to do as little magic as possible. You can write OOP code with it, but it's still very close to plain Elixir:
* Class instances are structs.
* Consequently, class instances are immutable.
* Class methods are functions in a module. There is no implicit `this` object; it has to be mentioned explicitly.
* All the inheritance mechanism does is copy fields from another struct. Methods are inherited by inserting `defdelegate` statements.
* When methods are called with the usual `.` operator, it is equivalent to a function call. Dynamic dispatch is only used when calling methods with the `~>` operator.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `classy_structs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:classy_structs, "~> 0.9"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/classy_structs](https://hexdocs.pm/classy_structs).

## Usage