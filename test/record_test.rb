require "test_helper"

class RecordTest < Minitest::Spec
  let(:activity) do
    Module.new do
      extend Trailblazer::Activity::Railway()

      step task: :a
      pass task: :b, Output(:success) => Path() do
        task task: :c
      end
      step task: :d
    end
  end

  it "what" do
    activity[:record].values.size.must_equal 3
  end

  it "allows cloned methods" do
    activity = Module.new do
      extend Trailblazer::Activity::Railway()
      module_function

      def a(ctx, **)
      end

      step method(:a).clone
      step method(:a).clone
    end

    activity[:record].values.size.must_equal 2
  end
end
