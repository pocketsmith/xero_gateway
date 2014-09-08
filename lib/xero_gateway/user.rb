module XeroGateway
  class User

    unless defined? ATTRS
      ATTRS = {
        "UserID" 	         => :string,  # Xero identifier, UUID
        "EmailAddress"     => :string,  # Email address of user
        "FirstName"        => :string,  # First name of user
        "LastName"         => :string,  # Last name of user
        "UpdatedDateUTC"   => :string,  # Timestamp of last change to user
        "IsSubscriber"     => :boolean, # Boolean to indicate if user is the subscriber (jrkw: todo)
        "OrganisationRole" => :string   # User role
      }
    end

    attr_accessor *ATTRS.keys.map(&:underscore)

    def initialize(params = {})
      params.each do |k,v|
        self.send("#{k}=", v)
      end
    end

    def ==(other)
      ATTRS.keys.map(&:underscore).each do |field|
        return false if send(field) != other.send(field)
      end
      return true
    end

    def to_xml(b = Builder::XmlMarkup.new)
      b.User do
        ATTRS.keys.each do |attr|
          attr_value = self.send(attr.underscore.to_sym)
          unless attr_value.nil? || attr_value == ""
            eval("b.#{attr} '#{self.send(attr.underscore.to_sym)}'")
          end
        end
      end
    end

    def self.from_xml(user_element)
      User.new.tap do |user|
        user_element.children.each do |element|

          attribute             = element.name
          underscored_attribute = element.name.underscore

          raise "Unknown attribute: #{attribute}" unless ATTRS.keys.include?(attribute)

          case (ATTRS[attribute])
            when :boolean then  user.send("#{underscored_attribute}=", (element.text == "true"))
            else                user.send("#{underscored_attribute}=", element.text)
          end

        end
      end
    end

  end
end