# frozen_string_literal: true

begin
  require 'minitest/autorun'
rescue LoadError
  warn '[translation-validator:test] minitest unavailable; skipping contract test'
else
  require_relative 'translation_validator'

  module Jekyll
    module TranslationValidator
      class LogFormatTest < Minitest::Test
        def test_log_line_format
          formatter = LogFormatter.new
          line = formatter.line(:warn, :DUP_VARIANT, 'original_slug=test lang=en')
          assert_equal(
            'LANG-TX | WARN | DUP_VARIANT | original_slug=test lang=en',
            line
          )
        end
      end
    end
  end
end
