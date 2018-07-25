require_relative '../../lib/domain/interface_enforcer'

RSpec.describe Domain::InterfaceEnforcer do
  describe ".audit" do
    it "returns false when the object doesn't implement all of the interface's methods"
    it "returns true when the object implements all of the interface's methods"
  end
end
