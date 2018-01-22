module Trailblazer
  # Implementation module that can be passed to `Activity[]`.
  class Activity < Module
    def self.Railway(options={})
      Railway.new(Railway, options)
    end

    class Railway < Activity
      def self.config
        Path.config.merge(
          builder_class:  Magnetic::Builder::Railway,
          plus_poles:     Magnetic::Builder::Railway.default_plus_poles,
          extend:         [ DSL.def_dsl(:step), DSL.def_dsl(:fail), DSL.def_dsl(:pass) ],
        )
      end
    end
  end
end
