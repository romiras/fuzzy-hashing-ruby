# frozen_string_literal: true

# The Costs class calculates the edit distance between two strings using a dynamic programming approach.
# It supports various edit operations including insertion, deletion, change, and swap.
#
# @attr_reader [String] a The first input string
# @attr_reader [String] b The second input string
# @attr_reader [Integer] op_insert The cost of inserting a character
# @attr_reader [Integer] op_delete The cost of deleting a character
# @attr_reader [Integer] op_change The cost of changing a character
# @attr_reader [Integer] op_swap The cost of swapping two adjacent characters
class Costs
  # Initializes a new Costs object with two input strings.
  #
  # @param [String] a The first input string
  # @param [String] b The second input string
  # @raise [ArgumentError] If either input is not a String
  def initialize(a, b)
    raise ArgumentError, 'Inputs must be strings' unless a.is_a?(String) && b.is_a?(String)

    @a = a
    @b = b
    @op_insert = 1
    @op_delete = 1
    @op_change = 2
    @op_swap = 2
  end

  # Calculates and returns the costs matrix for edit distance.
  #
  # @return [Array<Array<Integer>>] The 2D costs matrix
  def matrix
    calc_costs_matrix
  end

  private

  attr_accessor :a, :b, :op_insert, :op_delete, :op_change, :op_swap

  # Calculates the costs matrix for edit distance
  #
  # Example:
  #   a = 'xyz'
  #   b = 'ayzb'
  #
  #   Resulting matrix:
  #     /   a y z b
  #       0 1 2 3 4
  #     x 1 2 3 4 5
  #     y 2 3 2 3 4
  #     z 3 4 3 2 3
  #
  # Access: m[row][col], e.g., m[2][4] == 4
  #
  # @return [Array<Array<Integer>>] The 2D costs matrix
  def calc_costs_matrix
    height = a.length + 1
    width = b.length + 1
    cost_matrix = initialize_costs_matrix(height, width)

    (1...height).each do |row|
      prev_row = row.pred
      prev_row_vector = cost_matrix[prev_row]
      cur_row_vector = cost_matrix[row]

      (1...width).each do |col|
        prev_col = col.pred
        north = prev_row_vector[col]
        west = cur_row_vector[prev_col]
        north_west = prev_row_vector[prev_col]

        cost = if a[prev_row] == b[prev_col]
                 north_west
               else
                 [north + op_delete, west + op_insert, north_west + op_change].min
               end

        cur_row_vector[col] = apply_swap_cost(cost_matrix, row, col, cost)
      end
    end

    cost_matrix
  end

  # Initializes the costs matrix with base values for the first row and column.
  #
  # @param [Integer] height The height of the matrix
  # @param [Integer] width The width of the matrix
  # @return [Array<Array<Integer>>] The initialized costs matrix
  def initialize_costs_matrix(height, width)
    Array.new(height) do |row|
      if row.zero?
        Array.new(width) { |col| col * op_insert }
      else
        Array.new(width) { |col| col.zero? ? row * op_delete : 0 }
      end
    end
  end

  # Applies the swap cost if applicable.
  #
  # @param [Array<Array<Integer>>] matrix The current costs matrix
  # @param [Integer] prev_row The previous row index
  # @param [Integer] prev_col The previous column index
  # @param [Integer] current_cost The current cost
  # @return [Integer] The minimum of the current cost and the swap cost
  def apply_swap_cost(matrix, prev_row, prev_col, current_cost)
    return current_cost unless prev_row.positive? && prev_col.positive? &&
                               a[prev_row.pred] == b[prev_col] &&
                               a[prev_row] == b[prev_col.pred]

    [current_cost, matrix[row - 2][col - 2] + op_swap].min
  end
end

# Prints the costs matrix for the given input strings.
#
# @param [String] a The first input string
# @param [String] b The second input string
# @return [nil]
def print_costs_matrix(a, b)
  m = Costs.new(a, b).matrix

  puts "/   #{b.chars.join(' ')}"

  a.chars.each_with_index do |c, index|
    puts "#{c} " + m[index].join(' ')
  end

  nil
end

# Calculates the edit distance between two strings.
#
# @param [String] a The first input string
# @param [String] b The second input string
# @return [Integer] The edit distance between the two strings
def edit_dist(a, b)
  Costs.new(a, b).matrix[-1][-1]
end
