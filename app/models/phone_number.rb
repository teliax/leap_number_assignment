class PhoneNumber
  attr_accessor :id, :name, :number, :destination, :created_at

  def initialize(id, name, number, destination=nil, created_at=nil)
    @id = id
    @name = name
    @number = number
    @destination = destination
    @created_at = created_at
  end
end
