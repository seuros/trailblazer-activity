require "test_helper"
require "trailblazer/circuit/trace"
require "trailblazer/circuit/present"

class TracingTest < Minitest::Spec
  Circuit = Trailblazer::Circuit

  module Blog
    Read    = ->(options, flow_options) { options[:read] = 1;  [ Circuit::Right, options, flow_options ] }
    # Nest    = ->(options, flow_options) { options["Nest"] = 2; Nested.(Circuit::Start, options) [ Circuit::Right, options, flow_options ] }
    Write   = ->(options, flow_options) { options[:write] = 3; [ Circuit::Right, options, flow_options ] }
  end

    # Nested  = ->(options, *) { snippet }

  let (:circuit) do
    read    = Circuit::Task::Binary(Circuit::Task::Args::KW(Blog::Read))
    write   = Circuit::Task::Binary(Circuit::Task::Args::KW(Blog::Write))
    _nest   = Circuit::Nested(circuit2)

    circuit = Circuit::Activity(id: "blog", read=>["Blog::Read"], write=>["Blog::Write"], _nest=> ["[circuit2]", true]) do |evt|
      {
        evt[:Start] => { Circuit::Right => read },
        read        => { Circuit::Right => _nest },
        _nest       => { circuit2[:End] => write },
        write       => { Circuit::Right => evt[:End] },
      }
    end
  end

  module User
    Talk    = ->(options, flow_options) { options[:talk] = 1;  [ Circuit::Right, options, flow_options   ] }
    Speak   = ->(options, flow_options) { options[:speak] = 3; [ Circuit::Right, options, flow_options ] }
  end

  let (:circuit2) do
    talk    = Circuit::Task::Binary(Circuit::Task::Args::KW(User::Talk))
    speak   = Circuit::Task::Binary(Circuit::Task::Args::KW(User::Speak))

    circuit = Circuit::Activity({ id: "user", talk => ["User::Talk"], speak => ["User::Speak"] }) do |evt|
      {
        evt[:Start] => { Circuit::Right => talk },
        talk        => { Circuit::Right => speak },
        speak       => { Circuit::Right => evt[:End] },
      }
    end
  end

  it do
    direction, result, flow_options = circuit.(circuit[:Start], options={}, runner: Circuit::Trace.new, stack: [])

    direction.must_equal circuit[:End]
    options.must_equal({:read=>1, :talk=>1, :speak=>3, :write=>3})


    stack = flow_options[:stack]
    Circuit::Trace::Present.tree(stack)

    stack.collect{ |ary| ary[0] }.must_equal [circuit[:Start], "Blog::Read", "[circuit2]", "Blog::Write", circuit[:End]]
    stack[2][5].collect{ |ary| ary[0] }.must_equal [circuit2[:Start], "User::Talk", "User::Speak", circuit2[:End]]
  end
end

