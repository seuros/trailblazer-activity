module Trailblazer
  class Activity::Schema
      Output = Struct.new(:signal, :role)
      Line   = Struct.new(:source, :output)

      class OpenLines
    def initialize
      @arr = []
    end

    def pop(signal)
      lines = @arr.find_all { |line| line.output.role == signal }
      @arr -= lines
      lines
    end

    def <<((node, output))
      @arr << Line.new(node, output)
    end
  end

    def self.bla(steps)
      start_evt  = Circuit::Start.new(:default)
      start_args = [ start_evt, { type: :event, id: "Start.default" } ]
      start      = Activity::Graph::Start( *start_args )


          added_tasks      = {}
      open_lines = OpenLines.new
      open_lines << [ start, Output.new(Circuit::Right, :success) ]

      steps.each do |(magnetic_to, node, outputs)|
        puts "drawing #{node} which wants #{magnetic_to}"
        new_node = nil

        magnetic_to.each do |signal|
          incoming_lines = open_lines.pop(signal)
          raise("no matching edges found for your incoming #{magnetic_to}") unless incoming_lines.any?

          # connect this new node to all magnetic, open edges.
          incoming_lines.each do |line|
            command, existing_node = added_tasks[node] ? [ :connect!, added_tasks[node] ] : [ :attach!, [node, id: node] ]

            new_node, edge = start.send(
              command, # attach! or connect!
              source: line.source,
              target: existing_node,
              edge:   [ line.output.signal, {} ]
            )

            added_tasks[node] = new_node #
          end

          outputs.each do |output|
            open_lines << [new_node, output]
          end

        end
      end

      start
    end
  end

end
