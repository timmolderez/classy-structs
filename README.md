# Classy structs

*Classy structs* provides object-oriented features, such as inheritance and polymorphism, on top of Elixir's structs.

You can use this tiny macro library to define your own classes with fields and methods:

```Elixir
  use Class

  defclass Animal do
    var speed:10
    var weight:10

    def sound(_this) do
      "..."
    end
  end
```

Once a class is instantiated, you'll find that class instances are actually just structs:
```Elixir
  iex> a = Animal.new()
  %Animal{speed: 10}
```

However, these structs have a few more tricks up their sleeve:
```Elixir
  use Class

  defclass Dog do
    extends Animal          # Inheritance
    var species: ""
    var bark: "Woof!"
    var weight: 30          # Overriding fields

    def new(s) do           # Constructor
      %Dog{species: s}
    end

    def sound(this) do      # Overriding methods
      this.bark
    end
  end

  iex> d = Dog.new("Greyhound")
  %Dog{species: "Greyhound", bark: "Woof!", weight: 30, speed: 10}

  iex> Animal.sound(d)      # Static dispatch
  "..."

  iex> Animal~>sound(d)     # Dynamic dispatch
  "Woof!"
```

To learn more about everything *Classy structs* has to offer, go ahead and have a look at the [Usage](#usage) section.


## Installation

*Classy structs* can be installed by adding it to your project's dependencies in the `mix.exs` file:

```elixir
def deps do
  [
    {:classy_structs, git: "https://github.com/timmolderez/classy-structs.git"}
  ]
end
```

## <a id="usage"></a>Usage

### Defining basic classes

`defclass` is used to define a new class. The following is an example of a simple class definition:

```Elixir
  use Class

  defclass Rectangle do
    var width: 20
    var height: 10

    def surface(this) do
      this.width * this.height
    end

    def scale(this, factor) do
      %{this | width: this.width * factor, height: this.height * factor}
    end
  end
```

This example defines the `Rectangle` class. It has two fields `width` and `height`. Fields and their initial value are defined using `var`.

The class also has two methods `surface` and `scale`. These are defined like any other Elixir function, using `def`.

To construct a `Rectangle` instance, call the `new` method:
```Elixir
  iex> r = Rectangle.new()
  %Rectangle{width: 20, height:10}
```

Note that class instances actually are structs. This is important to keep in mind for two reasons:
* It implies that class instances are immutable.
* The same syntax is used to [access and update fields](https://elixir-lang.org/getting-started/structs.html#accessing-and-updating-structs).

Just to show how close classes are to structs, the `Rectangle` example expands to:

```Elixir
  defmodule Rectangle do
    defstruct width: 20, height: 10

    def surface(this) do
      this.width * this.height
    end

    def scale(this, factor) do
      %{this | width: this.width * factor, height: this.height * factor}
    end
  end
```

### Methods

Methods in *Classy structs* are just plain Elixir functions. There only is the convention that the class instance should be passed explicitly as the first parameter. (Unlike e.g. Java or C++, there is no implicit `this`.)

Again, this is just a convention, you can also leave out this parameter to mimic the notion of a "static method".

### Constructors

A constructor can be defined by adding a `new` function:

```Elixir
  defclass Dog do
    var species: ""
    var name: ""
    def new(s) do
      %Dog{species: s}
    end
  end
```

If no constructors are defined, a default one (without parameters) is automatically generated.

Given that a class instance is a struct, you're of course free to directly create your struct/instance instead of using constructors.

### Inheritance

### Static and dynamic method calls

### Super calls

Because it is possible to make static method calls, there is no need for an additional construct for "super calls". For example:

```Elixir
  defclass Text do
    var msg
    def toString(this), do: this.msg
  end

  defclass BoldText do
    extends Text
    def toString(this), do: "<b>" <> Text.toString(this) <> "<b>"
  end
```

The `Text.toString(this)` call is a super call.

### Abstract methods

## Limitations

There are a few things to watch out for when using *Classy structs*: 

* Fields cannot be initialized to anonymous functions using `var`. However, you can always update a field of a class instance to an anonymous function.
* A class and its subclass must be defined in seperate context. That is, they can't both be defined in the same file (unless the subclass is nested a another module). This is because, in Elixir, one module cannot depend on another module that is defined in the same context.
* If a class uses multiple inheritance, and two of its superclasses define the same abstract method, this produces a warning. This is because abstract methods are implemented using Elixir's @callback and @behaviour attributes. (When a module implements two behaviours, it produces this warning when both behaviours define the same callback.)