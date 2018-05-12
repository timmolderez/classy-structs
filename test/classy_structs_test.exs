use Class

defclass Empty do
end

defclass Animal do

  var length: 50
  var height: 50

  def setDimensions(this, length, height) do
    %{this| length: length, height: height}
  end

  def dimensions(this) do
    [this.length, this.height]
  end

  def sound(_this) do
    "..."
  end

  @abstract description(struct()) :: String.t
end

defmodule SubClasses do
  # A caveat of `extends` is that superclasses must be defined in another context,
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
end