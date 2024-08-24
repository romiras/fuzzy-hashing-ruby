# frozen_string_literal: true

require_relative './spam_sum'

path = ARGV[0]
SpamSum.new(path).call
