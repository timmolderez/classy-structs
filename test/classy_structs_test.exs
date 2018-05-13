#
# Classy structs test suite; to execute it, run `mix test`
#

use Class

defclass Empty do
end

defmodule PlainStruct do
  defstruct x: 5, y: 6
  def foo(this) do this.x end
  def bar(this) do this.y end
end

defclass Animal do
  @moduledoc """
    A class representing some properties of an animal
  """

  var length: 50
  var height: 50

  @spec setDimensions(Animal, number, number) :: Animal
  def setDimensions(this, length, height) do
    %{this| length: length, height: height}
  end

  def dimensions(this) do
    [this.length, this.height]
  end

  def sound(_this) do
    "..."
  end

  @abstract description(Animal) :: String.t

  def testNoParams, do: "Testing method without parameters"
  def testPrivate, do: private()
  defp private(), do: "Testing private method"
  def testGuarded(x) when is_integer(x), do: x
  def testGuarded(x) when is_boolean(x), do: x

  @doc """ 
    Doc test 
  """
  def attributeTest(), do: "Testing method with attribute"
end

defmodule SubClasses do

  # Note: A caveat of `extends` is that superclasses must be defined in another context,
  # i.e. another file or in another module. Hence the `SubClasses` module.
  # This is because, in Elixir, one module cannot depend on another module 
  # that is defined in the same context.

  defclass Dog do
    extends Animal
    var species: "Greyhound"
    var length: 100
  
    def new(species) do
      %Dog{species: species}
    end
  
    def sound(this) do
      if (this.height > 20) do "Woof!" else "Bark!" end
    end

    def description(this) do
      "Dog, species:" <> this.species
    end
  end
  
  defclass Cat do
    extends Animal
    var species: "European shorthair"
    var mice_caught: 0

    def new() do
      %Cat{}
    end
  
    def sound(_this) do
      "Meow!"
    end

    def description(this) do
      "Cat, species: " <> this.species
    end
  end

  defclass SubStruct do
    extends PlainStruct
    var x: 7
    var z: 8
    def foo(_this) do "OK" end
  end
end

defmodule MultipleInheritance do
  alias SubClasses.Cat
  alias SubClasses.Dog

  defclass PuppyCat do
    extends Cat, Dog
    var length: 80
  end  
end

# # ################################################################

defmodule ClassTest do
  use ExUnit.Case
  doctest Class

  test "new empty class" do
    assert Empty.new() == %Empty{}
  end

  test "static method call" do
    a = Animal.new()
    a = Animal.setDimensions(a, 20, 10)
    assert Animal.dimensions(a) == [20, 10]
  end

  test "basic inheritance" do
    alias SubClasses.Dog
    d = Dog.new("Greyhound")
    
    assert d.species == "Greyhound"
    assert d.length == 100
    assert d.height == 50
    assert Dog.dimensions(d) == [100, 50]
  end

  test "dynamic dispatch" do
    alias SubClasses.Cat
    c = Cat.new()
    assert Animal.sound(c) == "..."
    assert Cat.sound(c) == "Meow!"
    assert Animal~>sound(c) == "Meow!"
    assert Animal~>description(c) == "Cat, species: European shorthair"
  end

  test "multiple inheritance" do
    alias MultipleInheritance.PuppyCat

    pc = PuppyCat.new()
    assert Animal.sound(pc) == "..."
    assert PuppyCat.sound(pc) == "Meow!"
    assert Animal~>sound(pc) == "Meow!"
    assert Animal~>description(pc) == "Cat, species: European shorthair"
    assert pc.length == 80
    assert pc.species == "European shorthair"
  end

  test "parameterless method" do
    assert Animal.testNoParams() == "Testing method without parameters"
  end

  test "private method" do
    assert Animal.testPrivate() == "Testing private method"
  end

  test "guarded method" do
    alias SubClasses.Cat

    assert Animal.testGuarded(5) == 5
    assert Animal.testGuarded(true)
    assert Cat.testGuarded(5) == 5
    assert Cat.testGuarded(true)
  end

  test "using a struct as superclass" do
    alias SubClasses.SubStruct
    s = SubStruct.new()
    assert s == %SubStruct{x: 7, y: 6, z: 8}
    assert SubStruct.foo(s) == "OK"
    assert SubStruct.bar(s) == 6
  end
end