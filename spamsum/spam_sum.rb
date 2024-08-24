# frozen_string_literal: true

# The `SpamSum` class is responsible for generating a hash-based checksum for a file, which can be used to detect spam
# or similar content. The class has the following key features:

# - Configurable block size for the hashing algorithm, with a default heuristic
# to determine the optimal block size based on the file size.
# - Generates two types of hashes: a "normal" hash that uses the full digest length,
# and a "shorter" hash that uses half the digest length.
# - Provides a `call` method that reads the file, generates the hashes, and prints the resulting hash sums
# in a specific format.

# The class uses the `SumHash` and `RollingHash` classes to implement the hashing algorithm,
# and the `join_hashes` method to convert the hash values into a base64-encoded string.

require_relative './sum_hash'
require_relative './rolling_hash'

# SpamSum class implements the ssdeep fuzzy hashing algorithm
# This algorithm is used for creating context triggered piecewise hashes (CTPH)
# which are useful for identifying similar files or data
class SpamSum
  MIN_BLOCK_SIZE = 3
  MAX_DIGEST_LEN = 64
  HALF_MAX_DIGEST_LEN = MAX_DIGEST_LEN / 2
  B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  HASHSUM_FORMAT = '%<block_size>d:%<normal>s:%<shorter>s'

  # Initializes a new SpamSum instance
  #
  # @param path [String] The path to the file to be hashed
  # @param block_size [Integer] The initial block size for hashing (default: 0)
  def initialize(path, block_size: 0)
    @path = path
    total_bytes = File.size(path)
    @block_size = block_size.zero? ? guess_block_size_heuristically(total_bytes) : block_size
  end

  # Computes and returns the SpamSum hash for the file
  #
  # @return [String] The computed SpamSum hash
  def call
    File.open(path, 'rb') { |file| iterate_blocks(file) }
  end

  private

  attr_reader :path, :block_size

  # Guesses the optimal block size based on the file size
  #
  # @param total_bytes [Integer] The total size of the file in bytes
  # @return [Integer] The guessed optimal block size
  def guess_block_size_heuristically(total_bytes)
    block_size = MIN_BLOCK_SIZE
    block_size *= 2 while block_size * MAX_DIGEST_LEN < total_bytes
    block_size
  end

  # Joins the computed hashes into a single string
  #
  # @param io [IO] The file IO object
  # @param block_size [Integer] The block size for hashing
  # @param digest_len [Integer] The length of the digest (default: MAX_DIGEST_LEN)
  # @param legacy_mode [Boolean] Whether to use legacy mode (default: false)
  # @return [String] The joined hash string
  def join_hashes(io, block_size, digest_len = MAX_DIGEST_LEN, legacy_mode: false)
    io.rewind
    s = String.new
    iterate_hashes(io, block_size, digest_len, legacy_mode) do |hash|
      s << B64[hash % 64]
    end
    s
  end

  # Iterates through blocks of the file to compute the SpamSum hash
  #
  # @param io [IO] The file IO object
  def iterate_blocks(io)
    cur_block_size = block_size
    loop do
      normal = join_hashes(io, cur_block_size, MAX_DIGEST_LEN)
      shorter = join_hashes(io, cur_block_size * 2, HALF_MAX_DIGEST_LEN)

      normal_should_be_longer = normal.length < HALF_MAX_DIGEST_LEN
      can_reduce_block = cur_block_size > MIN_BLOCK_SIZE

      if normal_should_be_longer && can_reduce_block
        cur_block_size /= 2
      else
        print_sum(block_size: cur_block_size, normal: normal, shorter: shorter)
        return
      end
    end
  end

  # Prints the computed SpamSum hash
  #
  # @param block_size [Integer] The block size used for hashing
  # @param normal [String] The normal hash string
  # @param shorter [String] The shorter hash string
  def print_sum(block_size:, normal:, shorter:)
    puts format(HASHSUM_FORMAT, block_size: block_size, normal: normal, shorter: shorter)
  end

  # Iterates through the file computing hashes for each block
  #
  # @param io [IO] The file IO object
  # @param block_size [Integer] The block size for hashing
  # @param digest_len [Integer] The length of the digest
  # @param legacy_mode [Boolean] Whether to use legacy mode
  # @yield [Integer] The computed hash for each block
  def iterate_hashes(io, block_size, digest_len, legacy_mode)
    yielded = 0
    sh = SumHash.new
    rh = RollingHash.new

    io.each_char do |char|
      sh.update(char)
      rh.update(char)

      next if (rh.hash % block_size) != (block_size.pred) ||
              yielded >= (digest_len.pred)

      yield(sh.hash)

      yielded += 1
      sh = SumHash.new
    end

    yield(sh.hash) if rh.hash != 0 || legacy_mode || sh.hash != SumHash.new.hash
  end
end
