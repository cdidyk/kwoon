module Domain
  module UseCases
    class Result
      attr_reader :steps, :passed, :failed, :last_completed, :data

      def initialize args={}
        @steps = args[:steps]
        @passed = []
        @failed = []

        # should be one of the steps
        @last_completed = nil

        # REVIEW: keep an eye on this as it might change a lot
        # structure: {
        #   messages: {<attribute>: [<string>]},
        #   <k>: <primitive value>
        # }
        @data = {}
      end

      def fail_step step, fail_data={}
        # TODO: ensure that step is in @steps
        @failed << step unless @failed.include? step
        @last_completed = step
        @data.merge!(fail_data) do |k,ov,nv|
          ov.respond_to?(:merge!) ? ov.merge!(nv) : nv
        end
      end

      def pass_step step, pass_data={}
        # TODO: ensure that step is in @steps
        @passed << step unless @passed.include? step
        @last_completed = step
        @data.merge!(pass_data) do |k,ov,nv|
          ov.respond_to?(:merge!) ? ov.merge(nv) : nv
        end
      end

      def successful?
        passed.size > 0 && failed.empty?
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
