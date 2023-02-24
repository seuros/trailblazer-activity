module Trailblazer
  # This is DSL-independent code, focusing only on run-time.
  class Activity
    # include Activity::Interface # TODO

    def initialize(schema)
      @schema = schema
    end

    def call(args, **circuit_options)
      @schema[:circuit].(
        args,
        **circuit_options.merge(activity: self)
      )
    end

    def to_h
      @schema.to_h
    end

    def inspect
      %{#<Trailblazer::Activity:0x#{object_id}>}
    end

    # Canonical entry-point to invoke an {Activity} or Strategy such as {Activity::Railway}
    # with its taskWrap.
    def self.call(activity, ctx)
      TaskWrap.invoke(activity, [ctx, {}])
    end
  end # Activity
end

require "trailblazer/activity/structures"
require "trailblazer/activity/schema"
require "trailblazer/activity/schema/implementation"
require "trailblazer/activity/schema/intermediate"
require "trailblazer/activity/circuit"
require "trailblazer/activity/circuit/task_adapter"
require "trailblazer/activity/config"
require "trailblazer/activity/introspect"
require "trailblazer/activity/task_wrap/pipeline"
require "trailblazer/activity/task_wrap/call_task"
require "trailblazer/activity/task_wrap"
require "trailblazer/activity/task_wrap/runner"
require "trailblazer/activity/task_wrap/extension"
require "trailblazer/activity/adds"
require "trailblazer/activity/deprecate"
require "trailblazer/option"
require "trailblazer/context"


