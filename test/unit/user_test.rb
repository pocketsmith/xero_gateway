require File.join(File.dirname(__FILE__), '../test_helper.rb')

class UserTest < Test::Unit::TestCase

  # Tests that a currency can be converted into XML that Xero can understand, and then converted back to a currency
  def test_build_and_parse_xml
    user = create_test_user

    # Generate the XML message
    user_as_xml = user.to_xml

    # Parse the XML message and retrieve the account element
    user_element = REXML::XPath.first(REXML::Document.new(user_as_xml), "/User")

    # Build a new account from the XML
    result_user = XeroGateway::User.from_xml(user_element)

    # Check the account details
    assert_equal user, result_user
  end


  private

  def create_test_user
    XeroGateway::User.new.tap do |user|
      user.user_id           = "cdd39980-bbcf-0131-7704-60f847205428"
      user.first_name        = "Jimmy"
      user.last_name         = "Tester"
      user.email_address     = "tester@example.com"
      user.is_subscriber     = true
      user.organisation_role = "ROLE FOR THE USER"
      user.updated_date_utc  = "2010-03-02T01:59:07.903"
    end
  end
end