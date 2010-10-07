require '../lib/similus.rb'
require './custom_benchmark.rb'

class SimilusBenchmark1
  def configure_redis
    Similus.config do |config|
      config.backend = :redis
      config.redis_server = "localhost:6379"
      config.redis_db = 8
    end
  end

  def test
    configure_redis

    [10,50,100,500,1_000,5_000,10_000,50_000,100_000,500_000,1_000_000].each do |t|
      test_method(:add_activity, t, :param_types => [:users,:actions,:targets], :flush => true)
      test_method(:similar_to, t, :repetitions => [t,100000].min, :method_options => {:load_objects => false})
      test_method(:recommended_for, t, :repetitions => [t,100000].min, :method_options => {:load_objects => false})
    end

    CustomBenchmark.print_table
  end

  def test_method(method, t=1, options={})
    options = {:param_types=>[:users], :flush=>false, :repetitions => t}.update(options)

    # Preapre data
    Similus.redis.flushdb if options[:flush]
    users = []; actions = []; targets = []
    options[:repetitions].times do |i|
      users[i] = ["User", rand([2,t/10].max)+1]
      actions[i] = [:view, :comment, :like].shuffle.first
      targets[i] = [["Article", "Author", "User", "Comment"].shuffle.first, rand([2,t/100].max)+1]
    end

    # Repeat t times
    CustomBenchmark.benchmark_block(method, t, options[:repetitions]) do
      print "Start #{method} #{options[:repetitions]} (#{t}) times: "
      options[:repetitions].times do |i|
        print "." if i%1000 == 0 and i > 0
        params = []
        params << users[i]   if options[:param_types].include?(:users)
        params << actions[i] if options[:param_types].include?(:actions)
        params << targets[i] if options[:param_types].include?(:targets)
        params << options[:method_options] if options[:method_options]
        Similus.send(method.to_sym, *params)
      end
      puts "Done!"
    end
  end
end

benchmark = SimilusBenchmark1.new
benchmark.test


# 28/09/2010
#
# (times)   :         add_activity |          similar_to |     recommended_for |
# 10        :         10.02 (1.00) |         3.45 (0.34) |         8.50 (0.85) |
# 50        :         39.04 (0.78) |        24.53 (0.49) |        45.48 (0.91) |
# 100       :         73.15 (0.73) |        55.42 (0.55) |        96.05 (0.96) |
# 500       :        422.46 (0.84) |       623.09 (1.25) |      1778.15 (3.56) |
# 1000      :        788.63 (0.79) |      1990.06 (1.99) |      4837.11 (4.84) |
# 5000      :       4295.17 (0.86) |     12390.42 (2.48) |     36720.16 (7.34) |
# 10000     :       8007.07 (0.80) |     41967.76 (4.20) |   105031.32 (10.50) |
# 50000     :      41792.52 (0.84) |    139241.77 (2.78) |    383507.61 (7.67) |
# 100000    :      85121.77 (0.85) |    467467.67 (4.67) |  1093418.17 (10.93) |
# 500000    :     487059.48 (0.97) |   1475465.49 (2.95) |   3576451.57 (7.15) |
# 1000000   :     992621.05 (0.99) |   4901504.93 (4.90) | 10251016.93 (10.25) | // 1.077.523.597 objects from similar
# 

# 04/10/2010 - 1M activity dump size = 196MB
#
# +-----------+-----------------------+-----------------------+-----------------------+
# |   (times) |    add_activity (avg) |      similar_to (avg) | recommended_for (avg) |
# +-----------+-----------------------+-----------------------+-----------------------+
# |        10 |          20.33 (2.03) |           3.43 (0.34) |           5.11 (0.51) |
# |        50 |          43.20 (0.86) |          21.45 (0.43) |          37.15 (0.74) |
# |       100 |          79.26 (0.79) |          47.26 (0.47) |          83.99 (0.84) |
# |       500 |         420.71 (0.84) |         645.66 (1.29) |        1233.73 (2.47) |
# |      1000 |         775.37 (0.78) |        2059.96 (2.06) |        3919.73 (3.92) |
# |      5000 |        4244.56 (0.85) |       13365.46 (2.67) |       31732.53 (6.35) |
# |     10000 |        8132.53 (0.81) |       46890.51 (4.69) |     103245.89 (10.32) |
# |     50000 |       40575.59 (0.81) |      184494.91 (3.69) |      421366.42 (8.43) |
# |    100000 |       83084.49 (0.83) |      662960.10 (6.63) |    1346657.15 (13.47) |
# |    500000 |      473529.20 (0.95) |      344602.52 (3.45) |      671415.21 (6.71) |
# |   1000000 |      969757.84 (0.97) |      566429.01 (5.66) |      986263.44 (9.86) |
# +-----------+-----------------------+-----------------------+-----------------------+
