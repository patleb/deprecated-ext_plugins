require 'minitest/spec'
require 'minitest/hooks'
require 'mocha/mini_test'
require "maxitest/vendor/around"
require "maxitest/trap"
require "maxitest/let_bang"
require "maxitest/let_all"
require "maxitest/pending"
require "maxitest/xit"
require "maxitest/static_class_order"
require 'sql_query'
require 'ext_ruby'

Minitest::Spec::DSL.send(:alias_method, :context, :describe)

class << Minitest::Test
  alias_method :order_dependent!, :i_suck_and_my_tests_are_order_dependent!
end

Minitest::Spec::DSL.class_eval do
  alias_method :xshould, :xit
end

# Improved Minitest output (color and progress bar)
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::RubyMineReporter.new

module Kernel
  def describe_for(desc, *additional_desc, &block)
    describe desc, *additional_desc do
      subject{ desc.new }
      instance_eval(&block)
    end
  end
  private :describe_for
end

# TODO https://gist.github.com/ordinaryzelig/2032303
# https://jkotests.wordpress.com/2013/12/02/comparing-arrays-in-an-order-independent-manner-using-minitest/