class CustomBenchmark
  def self.benchmark_block(txtlabel, counter_container=0, times_repeated=nil)
    benchmark[counter_container] ||= {}
    now = Time.now.to_f
    res = yield if block_given?
    benchmark[counter_container][txtlabel] = {:total => (Time.now.to_f - now) * 1000, :times => times_repeated || counter_container}
    res
  end

  def self.benchmark
    @benchmark ||= {}
  end

  def self.print_table
    labels = benchmark.first[1].keys
    max_label_size = labels.map(&:size).max + 7
    fmt_str = "|%10s |" + ("%#{max_label_size}s |" * labels.size) + "\n"

    # Header
    print_line(labels, max_label_size)
    printf(fmt_str, "(times)", *(labels.map { |l| "#{l} (avg)"}))
    print_line(labels, max_label_size)

    # Body
    benchmark.each do |t,bench|
      values = labels.map do |txtlabel|
        sprintf("%.2f", bench[txtlabel][:total]) + " (" + sprintf("%.2f", bench[txtlabel][:total]/bench[txtlabel][:times]) + ")"
      end
      printf(fmt_str, t, *values)
    end

    # End line
    print_line(labels, max_label_size)
  end
  
  def self.print_line(labels, max_label_size)
    format = "+%10s-+" + ("%#{max_label_size}s-+" * labels.size) + "\n"
    label_lines = ['-'*max_label_size]*labels.size
    printf(format, "-"*10, *label_lines)
  end
end
