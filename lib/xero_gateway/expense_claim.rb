module XeroGateway

  class ExpenseClaim

    # Xero::Gateway associated with this expense claim.
    attr_accessor :gateway

    # Any errors that occurred when the #valid? method called.
    # Or errors that were within the XML payload from Xero
    attr_accessor :errors

    # All accessible fields
    attr_accessor :user, :receipts

    attr_reader :expense_claim_id, :status, :updated_date_utc, :total, :amount_due, :amount_paid, :payment_due_date, :reporting_date

    def initialize(params = {})
      @errors ||= []
      @receipts ||= []

      params.each do |k,v|
        self.send("#{k}=", v)
      end

    end

    # Validate the ExpenseClaim record according to what will be valid by the gateway.
    #
    # Usage:
    #  expense_claim.valid?     # Returns true/false
    #
    #  Additionally sets expense_claim.errors array to an array of field/error.
    def valid?
      @errors = []

      # jrkw - todo - below are the required values
      # <User>  The user in the organisation that the expense claim is for. See Users
      # <Receipts>  At least one receipt

      @errors.size == 0
    end


    # Creates this expense_claim record (using gateway.create_expense_claim) with the associated gateway.
    # If no gateway set, raise a NoGatewayError exception.
    def create
      raise NoGatewayError unless gateway
      gateway.create_expense_claim(self)
    end


    def to_xml(b = Builder::XmlMarkup.new)
      b.ExpenseClaim {
        user.to_xml(b)
        b.Receipts {
          self.receipts.each do |receipt|
            receipt.to_xml(b)
          end
        }
        b.ExpenseClaimID self.expense_claim_id if self.expense_claim_id
        b.Status self.status if self.status
        b.UpdatedDateUTC self.updated_date_utc if self.updated_date_utc
        b.Total self.total if self.total
        b.AmountDue self.amount_due if self.amount_due
        b.AmountPaid self.amount_paid if self.amount_paid
        b.PaymentDueDate self.payment_due_date if self.payment_due_date
        b.ReportingDate self.reporting_date if self.reporting_date
      }
    end

    def self.from_xml(expense_claim_element, gateway = nil, options = {})
      expense_claim = ExpenseClaim.new(options.merge({:gateway => gateway}))
      expense_claim_element.children.each do |element|
        case(element.name)
          when "User" then receipt.user = User.from_xml(element)
          when "Receipts" then element.children.each { |receipt| expense_claim.receipts << Receipt.from_xml(receipt) }
          when "ExpenseClaimID" then expense_claim.expense_claim_id = element.text
          when "Status" then expense_claim.status = element.text
          when "UpdatedDateUTC" then expense_claim.updated_date_utc = parse_date(element.text)
          when "Total" then expense_claim.total = BigDecimal.new(element.text)
          when "AmountDue" then expense_claim.amount_due = BigDecimal.new(element.text)
          when "AmountPaid" then expense_claim.amount_paid = BigDecimal.new(element.text)
          when "PaymentDueDate" then expense_claim.payment_due_date = parse_date(element.text)
          when "ReportingDate" then expense_claim.reporting_date = parse_date(element.text)
        end
      end
      invoice
    end

  end
end