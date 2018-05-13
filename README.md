![alt text](https://raw.githubusercontent.com/timmolderez/classy-structs/master/priv/classy_structs.png "Classy structs logo")

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
    var breed: ""
    var bark: "Woof!"
    var weight: 30          # Overriding fields

    def new(b) do           # Constructor
      %Dog{breed: b}
    end

    def sound(this) do      # Overriding methods
      this.bark
    end
  end

  iex> d = Dog.new("Greyhound")
  %Dog{breed: "Greyhound", bark: "Woof!", weight: 30, speed: 10}

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

### Basic classes

`defclass` is used to define a class. The following is an example of a simple class definition:

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

Note that class instances are structs. This is important to keep in mind because:
* It implies that, like all Elixir data structures, class instances are immutable.
* It implies that all fields are public.
* The syntax for [accessing and updating fields](https://elixir-lang.org/getting-started/structs.html#accessing-and-updating-structs) is reused.

Just to show how close classes are to structs, the `Rectangle` example actually expands to:

```Elixir
  defmodule Rectangle do
    defstruct width: 20, height: 10

    def surface(this) do
      this.width * this.height
    end

    def scale(this, factor) do
      %{this | width: this.width * factor, height: this.height * factor}
    end

    def new(), do: %Rectangle{}
  end
```

### Methods

Methods in *Classy structs* are just plain Elixir functions. There only is the convention that the class instance should be passed explicitly as the first parameter. (Unlike e.g. Java or C++, there is no implicit `this`.)

The only construct in *Classy structs* that relies on this convention is [dynamic dispatch](#calls).

You can also leave out the class instance parameter to mimic a "static method".

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

*Classy structs* supports multiple inheritance. To make use of it, include an `extends` construct in your class definition that lists one or more superclasses.

Class without a superclass:

```Elixir
  defclass Animal do
    var legs: 4
    var weight: 0
    def sound(_this), do: "..."
  end
```

Class with one superclass:
```Elixir
  defclass Dog do
    extends Animal
    var weight: 30
    var bark: "Woof!"
    def sound(this), do: this.bark
  end

  defclass Cat do
    extends Animal
    var weight: 4
  end

  iex> d = Dog.new()
  %Dog{legs: 4, weight: 30, bark: "Woof!"}

  iex> c = Cat.new()
  %Cat{legs: 4, weight: 4}

  iex> Dog.sound(d)
  "Woof!"

  iex> Cat.sound(c)
  "..."
```

As you can see, all inherited fields are included in class instances.

Class with multiple superclasses:
```Elixir
  defclass PuppyCat do
    extends Cat, Dog
    var breed: "Maine Coon"
  end

  iex> p = PuppyCat.new()
  %PuppyCat{legs: 4, weight: 4, bark: "Woof!", breed: "Maine Coon"}

  iex> PuppyCat.sound(p)
  "..."
```

When listing multiple superclasses, the order of these superclasses matters: if there are multiple superclasses that define the same field or method, the first one wins.

Finally, as class instances are just structs, you can also use a struct (that wasn't defined using `defclass`) as a superclass. This may come in useful whenever you'd like to extend structs from existing Elixir code.

### <a id="calls"></a>Static and dynamic method calls

The semantics of the `.` operator remain unchanged. A method call using `.` corresponds to calling a named function:

```Elixir
  # (reusing the Dog and Cat examples of the previous section)
  d = Dog.new()
  c = Cat.new()

  iex> Dog.sound(d)
  "Woof!"

  iex> Animal.sound(d)
  "..."

  iex> Cat.sound(c) # Inherited function
  "..."

```

In other words, the `.` operator performs static dispatch. To call methods using dynamic dispatch (which is how e.g. Java method calls work), the `~>` operator should be used. Dynamic dispatch figures out which method to call by looking at the type of the first argument:

```Elixir
  a = Animal.new()
  d = Dog.new()

  iex>Animal~>sound(a)
  "..."
  
  iex>Animal~>sound(d)
  "Woof!"
```

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

Using the `@abstract` attribute, it is possible to define abstract methods. These are methods without a body; they only specify the method's interface. Any class that extends a superclass with abstract methods must provide an implementation for all abstract methods:

```Elixir
  defclass Animal do
    @abstract sound(Animal) :: String.t
  end

  defclass Dog do
    extends Animal
    var bark: "Woof!"
    def sound(this), do: this.bark
  end

  
```

Note that abstract methods also provide a type specification. Elixir's [typespecs notation](https://hexdocs.pm/elixir/typespecs.html) is used for this specification.


If a subclass does not implement an abstract method, this produces a warning:

```Elixir
  iex>defclass Cat do
  ...>  extends Animal
  ...>end

  warning: function sound/1 required by behaviour Animal is not implemented (in module Cat)
```

## Limitations

There are a few things to watch out for when using *Classy structs*: 

* Fields cannot be initialized to anonymous functions using `var`. However, you can always update a field of an existing class instance to an anonymous function.
* A class and its superclass must be defined in seperate context. That is, they can't both be defined in the same file (unless the subclass is nested a another module). This is because, in Elixir, one module cannot depend on another module that is defined in the same context.
* If a class uses multiple inheritance, and two of its superclasses define the same abstract method, this produces a warning. This is because abstract methods are implemented using Elixir's @callback and @behaviour attributes. (When a module implements two behaviours, it produces this warning when both behaviours define the same callback.)