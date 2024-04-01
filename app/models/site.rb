class Site
  attr_accessor :id, :dns_name

  def initialize(identifier, fqdn)
    @id = identifier
    @dns_name = fqdn
  end
end
