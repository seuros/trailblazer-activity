require "test_helper"

class DocInternalsTest < Minitest::TrailblazerSpec
  #:method
  def outdated_method
    Trailblazer::Activity::Deprecate.warn caller_locations[0], "The `#outdated_method` is deprecated."

    # old code here.
  end
  #:method end

  #:test
  it "gives a deprecation warning" do
    _, err = capture_io do
      outdated_method()
    end
    line_no = __LINE__

    assert_equal err, %([Trailblazer] #{__FILE__}:#{line_no - 2} The `#outdated_method` is deprecated.\n)
  end
  #:test end
end
