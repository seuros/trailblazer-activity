require "test_helper"

class IntermediateTest < Minitest::Spec
  # Example task that doesn't return standard binary signals but
  # {"b/success"} etc.
  def self.b_task((ctx, flow_options), **)
    ctx[:seq] << :b

    signal = (ctx[:b] == false) ? "B/failure" : "B/success"

    return signal, [ctx, flow_options]
  end

  it "compiles {Schema} from intermediate and implementation, with two termini" do
    # generated by the editor or a specific DSL.
    # TODO: unique {id}
    # Intermediate shall not contain actual object references, since it might be generated.
    intermediate = Inter.new(
      {
        Inter::TaskRef(:b) => [Inter::Out(:success, :d), Inter::Out(:failure, :c)],
        Inter::TaskRef(:a) => [Inter::Out(:success, :b), Inter::Out(:failure, :c)],
        Inter::TaskRef(:c) => [Inter::Out(:success, "End.failure"), Inter::Out(:failure, "End.failure")],
        Inter::TaskRef(:d) => [Inter::Out(:success, "End.success"), Inter::Out(:failure, "End.success")],
        Inter::TaskRef("End.success", stop_event: true) => [],
        Inter::TaskRef("End.failure", stop_event: true) => []
      },
      {"End.success" => :success, "End.failure" => :failure},
      :a # start
    )

    a_extension_1 = ->(config:, **) { config.merge(a1: true) }
    a_extension_2 = ->(config:, **) { config.merge(a2: :yo)   }
    b_extension_1 = ->(config:, **) { config.merge(b1: false) }

    implementation = {
      :a => Schema::Implementation::Task(Implementing.method(:a),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)],        [a_extension_1, a_extension_2]),
      :b => Schema::Implementation::Task(IntermediateTest.method(:b_task),  [Activity::Output("B/success", :success), Activity::Output("B/failure", :failure)], [b_extension_1]),
      :c => Schema::Implementation::Task(Implementing.method(:c),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)]),
      :d => Schema::Implementation::Task(Implementing.method(:d),           [Activity::Output(Activity::Right,       :success), Activity::Output(Activity::Left, :failure)]),
      "End.success" => Schema::Implementation::Task(Implementing::Success,  [Activity::Output(Implementing::Success, :success)]), # DISCUSS: End has one Output, signal is itself?
      "End.failure" => Schema::Implementation::Task(Implementing::Failure,  [Activity::Output(Implementing::Failure, :failure)])
    }

    schema = Inter::Compiler.(intermediate, implementation)

    assert_process schema, :success, :failure, %(
#<Method: IntermediateTest.b_task>
 {B/success} => #<Method: Fixtures::Implementing.d>
 {B/failure} => #<Method: Fixtures::Implementing.c>
#<Method: Fixtures::Implementing.a>
 {Trailblazer::Activity::Right} => #<Method: IntermediateTest.b_task>
 {Trailblazer::Activity::Left} => #<Method: Fixtures::Implementing.c>
#<Method: Fixtures::Implementing.c>
 {Trailblazer::Activity::Right} => #<End/:failure>
 {Trailblazer::Activity::Left} => #<End/:failure>
#<Method: Fixtures::Implementing.d>
 {Trailblazer::Activity::Right} => #<End/:success>
 {Trailblazer::Activity::Left} => #<End/:success>
#<End/:success>

#<End/:failure>
)

    assert_equal schema[:outputs].inspect, %{[#<struct Trailblazer::Activity::Output signal=#<Trailblazer::Activity::End semantic=:success>, semantic=:success>, #<struct Trailblazer::Activity::Output signal=#<Trailblazer::Activity::End semantic=:failure>, semantic=:failure>]}

    # :extension API
    #   test it works with and without [bla_ext], and more than one per line
    assert_equal schema[:config].inspect, %{{:wrap_static=>{}, :b1=>false, :a1=>true, :a2=>:yo}}

    assert_invoke Activity.new(schema), seq: "[:a, :b, :d]"
    assert_invoke Activity.new(schema), b: false, seq: "[:a, :b, :c]", terminus: :failure
  end

  it "allows using any terminus configuration" do
    module D
      class End < Trailblazer::Activity::End
        def call((ctx, flow_options), **)
          ctx[:seq] << :d
          return self, [ctx, flow_options]
        end
      end
    end

    intermediate =
      Inter.new(
        {
          Inter::TaskRef("Start.default")                 => [Inter::Out(:success, :C)],
          Inter::TaskRef(:C)                              => [Inter::Out(:success, :D)],
          Inter::TaskRef(:D)                              => [],
          Inter::TaskRef(:E)                              => [Inter::Out(:success, "End.success")],
          Inter::TaskRef("End.success", stop_event: true) => []
        },
        { # terminus_id => semantic
          :D            => :win,
          "End.success" => :success
        },
        :C # start
      )

    implementation =
      {
        "Start.default" => Schema::Implementation::Task(Implementing::Start, [Activity::Output(Activity::Right, :success)], []),
        :C => Schema::Implementation::Task(Implementing.method(:c), [Activity::Output(Activity::Right, :success)], []),
        :E => Schema::Implementation::Task(Implementing.method(:f), [Activity::Output(Activity::Right, :success)], []),
        :D => Schema::Implementation::Task(D::End.new(semantic: :win),                  [], []),
        "End.success" => Schema::Implementation::Task(Implementing::Success,  [], [])
      }

    schema = Inter::Compiler.(intermediate, implementation)

    assert_equal schema[:outputs].inspect, %{[#<struct Trailblazer::Activity::Output signal=#<IntermediateTest::D::End semantic=:win>, semantic=:win>, #<struct Trailblazer::Activity::Output signal=#<Trailblazer::Activity::End semantic=:success>, semantic=:success>]}

    assert_circuit schema, %{
#<Start/:default>
 {Trailblazer::Activity::Right} => #<Method: Fixtures::Implementing.c>
#<Method: Fixtures::Implementing.c>
 {Trailblazer::Activity::Right} => #<IntermediateTest::D::End/:win>
#<IntermediateTest::D::End/:win>

#<Method: Fixtures::Implementing.f>
 {Trailblazer::Activity::Right} => #<End/:success>
#<End/:success>
}

    assert_invoke Activity.new(schema), seq: "[:c, :d]", terminus: :win
  end

  describe ":extension API: Config" do
    let(:intermediate) do
      Inter.new(
        {
          Inter::TaskRef(:C)                              => [Inter::Out(:success, "End.success")],
          Inter::TaskRef("End.success", stop_event: true) => []
        },
        {"End.success" => :success},
        :C # start
      )
    end

    def implementation(c_extensions)
      {
        :C            => Schema::Implementation::Task(c = Implementing.method(:c), [Activity::Output(Activity::Right, :success)], c_extensions),
        "End.success" => Schema::Implementation::Task(Implementing::Success, [], [])
      }
    end

    # Accessor API

    it "doesn't allow mutations" do
      ext_a = ->(config:, **) { config[:a] = "bla" }

      exception = Object.const_defined?(:FrozenError) ? FrozenError : RuntimeError # < Ruby 2.5

      assert_raises exception do
        Inter::Compiler.(intermediate, implementation([ext_a]))
      end
    end

    it "allows using the {Config} API" do
      ext_a = ->(config:, **)       { config.merge(a: "bla") }
      ext_b = ->(config:, **)       { config.merge(b: "blubb") }
      ext_d = ->(config:, id:, **)  { config.merge(id => 1) }              # provides :id
      ext_e = ->(config:, **)       { config.merge(e: config[:C] + 1) } # allows reading new {Config} instance.

      schema = Inter::Compiler.(intermediate, implementation([ext_a, ext_b, ext_d, ext_e]))

      assert_equal (schema[:config].to_h.inspect), %{{:wrap_static=>{}, :a=>\"bla\", :b=>\"blubb\", :C=>1, :e=>2}}
    end

  # {Implementation.call()} allows to pass {config} data
    describe "{Implementation.call()}" do
      it "accepts {config_merge:} data that is merged into {config}" do
        schema = Inter::Compiler.(intermediate, implementation([]), config_merge: {beer: "yes"})

        assert_equal (schema[:config].to_h.inspect), %{{:wrap_static=>{}, :beer=>\"yes\"}}
      end

      it "{:config_merge} overrides values in {default_config}" do
        schema = Inter::Compiler.(intermediate, implementation([]), config_merge: {beer: "yes", wrap_static: "yo"})

        assert_equal (schema[:config].to_h.inspect), %{{:wrap_static=>"yo", :beer=>\"yes\"}}
      end
    end
  end
end
