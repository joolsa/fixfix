require 'nokogiri'

class XMLParser
  def initialize(file)
    @file = file
  end

  def doc_and_words
    @doc = File.open(@file) { |f| Nokogiri::XML(f.read) }
    @words = @doc.css('SourceTextChar > CharPos, FinalTextChar > CharPos').map { |char|
      x = char[:X].to_i
      y = char[:Y].to_i
      w = char[:Width].to_i
      h = char[:Height].to_i
      Word.new(char[:Value], x, y, x + w, y + h)
    }
  end

  def parse
    doc_and_words

    # @doc.css('Events > Fix[Dur]').map { |element|
    #   # x = element[:X].to_i
    #   # y = element[:Y].to_i
    #   xl = element[:Xl].to_i
    #   yl = element[:Yl].to_i
    #   xr = element[:Xr].to_i
    #   yr = element[:Yr].to_i
    #   time = element[:Time].to_i
    #   left = Gaze.new(xl, yl, nil, 0)
    #   right = Gaze.new(xr, yr, nil, 0)
    #   Sample.new(time, left, right)
    # }
    @doc.css('Events > Eye').map { |element|
      # x = element[:X].to_i
      # y = element[:Y].to_i
      xl = element[:Xl].to_i
      yl = element[:Yl].to_i
      pl = element[:pl].to_f
      xr = element[:Xr].to_i
      yr = element[:Yr].to_i
      pr = element[:pr].to_f
      vl = pl == -1 ? 4 : 0
      vr = pr == -1 ? 4 : 0
      time = element[:Time].to_i
      left = Gaze.new(xl, yl, pl, vl)
      right = Gaze.new(xr, yr, pr, vr)
      Sample.new(time, left, right)
    }
  end

  def flags
    {
      center: true,
      xml: true,
    }
  end

  def words
    doc_and_words unless @words
    @words
  end

  def self.generate(reading, file)
    doc = File.open(file) { |f| Nokogiri::XML(f.read) { |config| config.noblanks } }
    events = doc.at_css('Events')
    nodes = events.children.remove.select { |node| node.node_name != 'Fix' && node['Time'] }
    reading.samples.each do |sample|
      node = Nokogiri::XML::Node.new 'Fix', doc
      node['Time'] = sample.time
      node['Dur'] = sample.duration
      node['X'] = (sample.left.x + sample.right.x) / 2
      node['Y'] = (sample.left.y + sample.right.y) / 2
      node['Xl'] = sample.left.x
      node['Yl'] = sample.left.y
      node['Xr'] = sample.right.x
      node['Yr'] = sample.right.y
      # TODO What about TT, Win, Cursor
      nodes << node
    end
    nodes.sort_by! { |node| node['Time'].to_i }
    nodes.each do |node|
      events << node
    end
    doc.to_xml
  end
end
