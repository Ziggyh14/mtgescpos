require 'escpos'
require 'escpos/image'
require 'mini_magick'
require 'rmagick'
require 'json'
require "down"

card = JSON.parse(File.read('card.json'))

@printer = Escpos::Printer.new

i = Magick::ImageList.new("template.png")
#i = Magick::Image.new(441,616) #{ |i| i.background_color = "black" }

d = Magick::Draw.new

#mana cost
d.annotate(i, 0,0,0,10, card['mana_cost']){ |t|
  t.gravity = Magick::NorthEastGravity
  t.pointsize = 27
  t.font = 'Hack-Bold.ttf'
  t.fill = 'black'
  t.font_weight = Magick::BoldWeight
}

#name
d.annotate(i, 0,0,0,10, card['name']){ |t|
  t.gravity = Magick::NorthWestGravity
  t.pointsize = 34
  t.font = 'Matrix-Bold.ttf'
  t.fill = 'black'
  t.font_weight = Magick::BoldWeight
}

#type line
d.annotate(i, 0,0,0,25, card['type_line']){ |t|
  t.gravity = Magick::WestGravity
  t.pointsize = 28
  t.font = 'Matrix-Bold.ttf'
  t.fill = 'black'
  t.font_weight = Magick::BoldWeight
}

#text box
SEPARATOR = ' '.freeze
s = card['oracle_text']

unless  d.get_multiline_type_metrics(s).width < 420
    s = s.split(SEPARATOR).each_with_object('').with_index do |(word, line), index|
      tmp_line = "#{line}#{SEPARATOR}#{word}"
      line.concat(d.get_multiline_type_metrics(tmp_line).width < 420? SEPARATOR : '\n') if index != 0
      line.concat(word)
    end
end
d.annotate(i, 0,0,0,165,s ){ |t|
  t.gravity = Magick::WestGravity
  t.pointsize = 31
  t.font = 'Matrix-Bold.ttf'
  t.fill = 'black'
  t.interline_spacing = 6
}

# pow/toughness
d.annotate(i, 0,0,0,0, "#{card['power']}/#{card['toughness']}"){ |t|
  t.gravity = Magick::SouthEastGravity
  t.pointsize = 35
  t.font = 'Hack-Bold.ttf'
  t.fill = 'black'
  t.font_weight = Magick::BoldWeight
}

  Down.download(card['image_uris']['art_crop'], destination: "art.jpg")
Magick::ImageList.new('art.jpg').tap do |a|
  a.resize!(441,270) 
  i.composite!(a, 0, 50, Magick::OverCompositeOp)
end

i.write("temp.png")
image = Escpos::Image.new "temp.png", {
  processor: "MiniMagick",
  resize: "x369>",
  rotate: '90',
  extent: true
  # ... other options, see following sections
}
@printer << image
puts @printer.to_escpos
puts "\x1d\x56\x41\x03" #cut paper
 # returns ESC/POS data ready to be sent to printer
# on linux this can be piped directly to /dev/usb/lp0
# with network printer sent directly to printer socket (see example below)
# with serial port printer it can be sent directly to the serial port
