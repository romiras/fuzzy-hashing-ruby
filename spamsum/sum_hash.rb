# frozen_string_literal: true

class SumHash
  attr_reader :hash

  MAX_UINT32 = 0xFFFFFFFF

  def initialize
    @hash = 0x28021967
  end

  def update(char)
    @hash *= 0x01000193
    @hash &= MAX_UINT32
    @hash ^= char.ord
  end
end
