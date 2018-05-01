use Class

defclass Empty do
end

defclass Animal do
  var length: 0
  var height: 0

  def setDimensions(this, length, height) do
    %{this| length: length, height: height}
  end

  def dimensions(this) do
    [this.length, this.height]
  end

  def sound(_this) do
    "..."
  end
end

defmodule Extensions do
  defclass Dog do
    extends Empty
    var species: "Greyhound"
  
    def new(species) do
      %Dog{species: species}
    end
  
    def test() do
      %Animal{}
    end
  
    def sound(this) do
      if (this.height > 20) do "Woof!" else "Bark!" end
    end
  end  
end


# defclass Cat do
#   extends Animal
#   var species: "European shorthair"
#   var mice_caught: 0

#   def sound(this) do
#     "Meow!"
#   end
# end

# defclass PuppyCat do
#   extends Cat, Dog
# end

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

  # test "basic inheritance" do
  #   d = Extensions.Dog.new("Greyhound")
  #   IO.inspect Extensions.Dog.test()
  # end
end
