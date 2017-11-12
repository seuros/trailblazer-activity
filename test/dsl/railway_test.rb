require "test_helper"

require "trailblazer/activity/dsl/railway"

class RailwayTest < Minitest::Spec
  class A; end

  # outputs for task.
  let(:initial_plus_poles) { Activity::Magnetic::PlusPoles.new.merge( Activity::Magnetic.Output(Circuit::Right, :success) => :success, Activity::Magnetic.Output(Circuit::Right, :failure) => :failure ) }

  it do
    magnetic_to, plus_poles = Activity::DSL::PoleGenerator::Railway.step( A, plus_poles: initial_plus_poles )

    magnetic_to.must_equal [:success]
    Inspect(plus_poles.to_a).must_equal %{[#<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Circuit::Right, semantic=:success>, color=:success>, #<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Circuit::Right, semantic=:failure>, color=:failure>]}
  end

  it do
    magnetic_to, plus_poles = Activity::DSL::PoleGenerator::Railway.fail( A, plus_poles: initial_plus_poles )

    magnetic_to.must_equal [:failure]
    Inspect(plus_poles.to_a).must_equal %{[#<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Circuit::Right, semantic=:success>, color=:failure>, #<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Circuit::Right, semantic=:failure>, color=:failure>]}
  end

  it do
    magnetic_to, plus_poles = Activity::DSL::PoleGenerator::FastTrack.step( A, plus_poles: initial_plus_poles, fast_track: true )

    magnetic_to.must_equal [:success]
    Inspect(plus_poles.to_a).must_equal %{[#<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Circuit::Right, semantic=:success>, color=:success>, #<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Circuit::Right, semantic=:failure>, color=:failure>, #<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Activity::DSL::PoleGenerator::FastTrack::FailFast, semantic=:fail_fast>, color=:fail_fast>, #<struct Trailblazer::Activity::Magnetic::PlusPole output=#<struct Trailblazer::Activity::Magnetic::Output signal=Trailblazer::Activity::DSL::PoleGenerator::FastTrack::PassFast, semantic=:pass_fast>, color=:pass_fast>]}
  end
end