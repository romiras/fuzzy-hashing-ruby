# This class implements a rolling hash algorithm, which is used in the spamsum algorithm.
# It maintains three separate hash values (h1, h2, h3) that are updated as new characters
# are processed, allowing for efficient computation of hash values over a sliding window of text.
class RollingHash
  # The size of the rolling window
  ROLLING_WINDOW = 7
  # The maximum value for a 32-bit unsigned integer
  MAX_UINT32 = 0xFFFFFFFF

  # Initializes a new RollingHash instance
  def initialize
    @h1 = 0
    @h2 = 0
    @h3 = 0

    @window = Array.new(ROLLING_WINDOW, 0)
    @n = 0
  end

  # Computes and returns the current hash value
  # @return [Integer] The combined hash value
  def hash
    (@h1 + @h2 + @h3) & MAX_UINT32
  end

  # Updates the rolling hash with a new character
  # @param char [String] A single character to be added to the hash
  def update(char)
    c = char.ord

    @h2 -= @h1
    @h2 += ROLLING_WINDOW * c

    @h1 += c
    @h1 -= @window[@n % ROLLING_WINDOW]

    @window[@n % ROLLING_WINDOW] = c
    @n += 1

    @h3 = (@h3 << 5) & MAX_UINT32
    @h3 ^= c
  end
end
