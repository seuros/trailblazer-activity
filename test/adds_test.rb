require "test_helper"

class AddsTest < Minitest::Spec
  # DISCUSS: not tested here is Append to empty Pipeline because we always initialize it.
  let(:pipeline) { Trailblazer::Activity::TaskWrap::Pipeline }

#@ No mutation on original pipe
  it "what" do
    pipe1 = pipeline.new([pipeline::Row["task_wrap.call_task", "task, call"]])

  #@ {Prepend} to element 0
    add = { insert: [pipeline::Insert.method(:Prepend), "task_wrap.call_task"], row: pipeline::Row["trace-in-outer", "trace, prepare"] }
    pipe2 = pipeline::Adds.apply_adds(pipe1, [add])

  #@ {Append} to element 0
    add = { insert: [pipeline::Insert.method(:Append), "task_wrap.call_task"], row: pipeline::Row["trace-out-outer", "trace, prepare"] }
    pipe3 = pipeline::Adds.apply_adds(pipe2, [add])

  #@ {Prepend} again
    add = { insert: [pipeline::Insert.method(:Prepend), "task_wrap.call_task"], row: pipeline::Row["trace-in-inner", "trace, prepare"] }
    pipe4 = pipeline::Adds.apply_adds(pipe3, [add])

  #@ {Append} again
    add = { insert: [pipeline::Insert.method(:Append), "task_wrap.call_task"], row: pipeline::Row["trace-out-inner", "trace, prepare"] }
    pipe5 = pipeline::Adds.apply_adds(pipe4, [add])

  #@ {Append} to last element
    add = { insert: [pipeline::Insert.method(:Append), "trace-out-outer"], row: pipeline::Row["last-id", "log"] }
    pipe6 = pipeline::Adds.apply_adds(pipe5, [add])

  #@ {Replace}

  #@ {Delete}

    assert_equal inspect(pipe1), %{#<Trailblazer::Activity::TaskWrap::Pipeline:
 @sequence=[["task_wrap.call_task", "task, call"]]>
}

    assert_equal inspect(pipe2), %{#<Trailblazer::Activity::TaskWrap::Pipeline:
 @sequence=
  [["trace-in-outer", "trace, prepare"],
   ["task_wrap.call_task", "task, call"]]>
}

    assert_equal inspect(pipe3), %{#<Trailblazer::Activity::TaskWrap::Pipeline:
 @sequence=
  [["trace-in-outer", "trace, prepare"],
   ["task_wrap.call_task", "task, call"],
   ["trace-out-outer", "trace, prepare"]]>
}

    assert_equal inspect(pipe4), %{#<Trailblazer::Activity::TaskWrap::Pipeline:
 @sequence=
  [["trace-in-outer", "trace, prepare"],
   ["trace-in-inner", "trace, prepare"],
   ["task_wrap.call_task", "task, call"],
   ["trace-out-outer", "trace, prepare"]]>
}

    assert_equal inspect(pipe5), %{#<Trailblazer::Activity::TaskWrap::Pipeline:
 @sequence=
  [["trace-in-outer", "trace, prepare"],
   ["trace-in-inner", "trace, prepare"],
   ["task_wrap.call_task", "task, call"],
   ["trace-out-inner", "trace, prepare"],
   ["trace-out-outer", "trace, prepare"]]>
}

    assert_equal inspect(pipe6), %{#<Trailblazer::Activity::TaskWrap::Pipeline:
 @sequence=
  [["trace-in-outer", "trace, prepare"],
   ["trace-in-inner", "trace, prepare"],
   ["task_wrap.call_task", "task, call"],
   ["trace-out-inner", "trace, prepare"],
   ["trace-out-outer", "trace, prepare"],
   ["last-id", "log"]]>
}
  end

  def inspect(pipe)
    pipe.pretty_inspect.sub(/0x\w+/, "")
  end
end