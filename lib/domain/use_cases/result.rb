module Domain
  module UseCases
    class Result
      attr_reader :steps, :passed, :failed, :state, :data

      def initialize args={}
        @steps = args[:steps]
        @passed = []
        @failed = []

        # possible states are:
        # :initialize (for when no steps are being run yet)
        # <steps.each>
        # :done (for when the use case passed all steps it encountered)
        @state = :initialize

        @data = {}
      end
    end
  end
end

# class UseCaseResult
#   attr_accessor :messages
#   attr_reader :steps, :passed, :failed, :halt

#   def initialize steps=[]
#     @messages = {}
#     @steps = steps
#     @passed = []
#     @failed = []
#     @halt = false
#   end

#   def pass step_name, &block
#     if !steps.include? step_name
#       raise ArgumentError, 'step_name must be one of the steps'
#     end

#     @failed.delete step_name
#     @passed << step_name
#     yield self
#   end

#   def fail step_name, &block
#     if !steps.include? step_name
#       raise ArgumentError, 'step_name must be one of the steps'
#     end

#     @passed.delete step_name
#     @failed << step_name
#     yield self
#   end

#   def fail_and_halt step_name, &block
#     if !steps.include? step_name
#       raise ArgumentError, 'step_name must be one of the steps'
#     end

#     @passed.delete step_name
#     @failed << step_name
#     @halt = true
#     yield self
#   end
# end
