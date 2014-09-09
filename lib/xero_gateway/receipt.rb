module XeroGateway

  class Receipt
    include Dates
    include Money
    include LineItemCalculations

    LINE_AMOUNT_TYPES = {
      "Inclusive" =>        'Invoice lines are inclusive tax',
      "Exclusive" =>        'Invoice lines are exclusive of tax (default)',
      "NoTax"     =>        'Invoices lines have no tax'
    } unless defined?(LINE_AMOUNT_TYPES)

    GUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ unless defined?(GUID_REGEX)

    # Xero::Gateway associated with this invoice.
    attr_accessor :gateway

    # Any errors that occurred when the #valid? method called.
    # Or errors that were within the XML payload from Xero
    attr_accessor :errors

    # All accessible fields
    attr_accessor :date, :contact, :line_items, :user, :reference, :line_amount_types, :sub_total, :total_tax, :total, :receipt_id, :receipt_status, :receipt_number, :updated_date_utc, :has_attachments, :url

    # Accepts a name value for the contact that this relates to, used in loading up @contact
    attr_accessor :receipt_from

    def initialize(params = {})
      @errors ||= []

      params = {
        :line_amount_types => "Exclusive"
      }.merge(params)

      params.each do |k,v|
        self.send("#{k}=", v)
      end

      @line_items ||= []
    end

    # Validate the Receipt record according to what will be valid by the gateway.
    #
    # Usage:
    #  receipt.valid?     # Returns true/false
    #
    #  Additionally sets receipt.errors array to an array of field/error.
    def valid?
      @errors = []

      # jrkw - todo - below are the required values
      # <Date>  Date of receipt – YYYY-MM-DD
      # <Contact>  See Contacts
      # <Lineitems>  See LineItems
      # <User>  The user in the organisation that the expense claim receipt is for. See Users

      @errors.size == 0
    end


    # Helper method to fetch the associated contact object. If the contact with :name => receipt_from doesn't exist, a new contact is built
    def contact
      return nil unless receipt_from
      @contact ||= get_contact_from_receipt_from || build_contact(:name => receipt_from)
    end

    def get_contact_from_receipt_from
      return nil unless gateway
      return nil unless receipt_from
      c = gateway.get_contacts(:where => "name=\"#{receipt_from}\"").response_item
      c.present? ? c : nil
    end

    def build_contact(params = {})
      self.contact = gateway ? gateway.build_contact(params) : Contact.new(params)
    end


    # Creates this receipt record (using gateway.create_receipt) with the associated gateway.
    # If no gateway set, raise a NoGatewayError exception.
    def create
      raise NoGatewayError unless gateway
      gateway.create_receipt(self)
    end


    def to_xml(b = Builder::XmlMarkup.new)
      b.Receipt {
        b.ReceiptID self.receipt_id if self.receipt_id
        b.ReceiptNumber self.receipt_number if self.receipt_number
        b.Date Receipt.format_date(self.date) if self.date
        contact.to_xml(b) if contact
        user.to_xml(b) if user
        b.LineItems {
          self.line_items.each do |line_item|
            line_item.to_xml(b)
          end
        } if self.line_items.any?
        b.Reference self.reference if self.reference
        b.LineAmountTypes self.line_amount_types if self.line_amount_types
        b.SubTotal self.sub_total if self.sub_total
        b.TotalTax self.total_tax if self.total_tax
        b.Total self.total if self.total
        b.Status self.receipt_status if self.receipt_status
        b.UpdatedDateUTC self.updated_date_utc if self.updated_date_utc
        b.HasAttachments self.has_attachments if self.has_attachments
        b.Url url if url
      }
    end

    def self.from_xml(receipt_element, gateway = nil, options = {})
      receipt = Receipt.new(options.merge({:gateway => gateway}))
      receipt_element.children.each do |element|
        case(element.name)
          when "ReceiptID" then receipt.receipt_id = element.text
          when "ReceiptNumber" then receipt.receipt_number = element.text
          when "Date" then receipt.date = parse_date(element.text)
          when "Contact" then receipt.contact = Contact.from_xml(element)
          when "LineItems" then element.children.each {|line_item| receipt.line_items << LineItem.from_xml(line_item) }
          when "User" then receipt.user = User.from_xml(element)
          when "Reference" then receipt.reference = element.text
          when "LineAmountTypes" then receipt.line_amount_types = element.text
          when "SubTotal" then receipt.sub_total = BigDecimal.new(element.text)
          when "TotalTax" then receipt.total_tax = BigDecimal.new(element.text)
          when "Total" then receipt.total = BigDecimal.new(element.text)
          when "Status" then receipt.invoice_status = element.text
          when "UpdatedDateUTC" then receipt.updated_date_utc = parse_date(element.text)
          when "HasAttachments" then receipt.has_attachments = element.text
          when "Url" then receipt.url = element.text
          when "ValidationErrors" then receipt.errors = element.children.map { |error| Error.parse(error) }
        end
      end
      invoice
    end

  end
end