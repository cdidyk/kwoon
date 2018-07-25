module Domain
  class InterfaceEnforcer
    def self.audit obj, interface
      interface.instance_methods(false).all? do |fn|
        obj.public_methods(false).include? fn
      end
    end
  end
end
