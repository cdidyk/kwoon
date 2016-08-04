# This is a monkeypatch for until the following is merged into BetterErrors:
# https://github.com/charliesome/better_errors/pull/327
module BetterErrors
  def local_variables
    return {} unless frame_binding

    frame_binding.eval("local_variables").each_with_object({}) do |name, hash|
      # Ruby 2.2's local_variables will include the hidden #$! variable if
      # called from within a rescue context. This is not a valid variable name,
      # so the local_variable_get method complains. This should probably be
      # considered a bug in Ruby itself, but we need to work around it.
      next if name == :"\#$!"

      if defined?(frame_binding.local_variable_get)
        hash[name] = frame_binding.local_variable_get(name)
      else
        hash[name] = frame_binding.eval(name.to_s)
      end
    end
  end
end