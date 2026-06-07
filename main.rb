require 'escpos'
require 'escpos/image'
require 'mini_magick'
require 'rmagick'
require 'json'
require "down"

WIDTH = 384
HEIGHT = 512
NAME_OFFSET = {x: 0, y: 0, mc_width: 0}
TYPELINE_OFFSET = {x: 0, y: HEIGHT/2 + 20}
STATBOX_OFFSET = {x: 0, y: 0}
TEXTBOX_OFFSET = {x: 0, y: HEIGHT/2+20}
ART_OFFSET = {x: 0, y: 30}
ART_HEIGHT = 240

card = JSON.parse(File.read('card.json'))

@printer = Escpos::Printer.new

i = Magick::ImageList.new("test.png")
#i = Magick::Image.new(441,616) #{ |i| i.background_color = "black" }

d = Magick::Draw.new

#mana cost
d.annotate(i, 0,0,NAME_OFFSET[:x],NAME_OFFSET[:y], card['mana_cost']){ |t|
  t.gravity = Magick::NorthEastGravity
  t.pointsize = 20
  t.font = 'Hack-Bold.ttf'
  t.fill = 'black'
  t.font_weight = Magick::BoldWeight
  NAME_OFFSET[:mc_width] = card['mana_cost'] == ''? 0 : t.get_type_metrics(card['mana_cost']).width
}
#name
d.annotate(i, 0,0,NAME_OFFSET[:x],NAME_OFFSET[:y], card['name']){ |t|
  t.gravity = Magick::NorthWestGravity
  p = 34
  t.pointsize = p
    t.font = 'Matrix-Bold.ttf'
  while d.get_type_metrics(card['name']).width > WIDTH - NAME_OFFSET[:mc_width] && p > 5 do
    t.pointsize = (p += -1)
  end
  t.pointsize = p
}

#type line
d.annotate(i, 0,0,TYPELINE_OFFSET[:x],TYPELINE_OFFSET[:y], card['type_line']){ |t|
  t.gravity = Magick::NorthWestGravity
  t.font = 'Matrix-Bold.ttf'
  p = 33
  t.pointsize = p
  while d.get_type_metrics(card['type_line']).width > WIDTH && p > 5 do
    t.pointsize = (p += -1)
  end
  TEXTBOX_OFFSET[:y] += p
}

#text box


d.interline_spacing = 6
d.font = 'Matrix-Bold.ttf'

h = true
SEPARATOR = ' '.freeze
s = ''
p = 30 + 1
while h && p > 5 do
  d.pointsize = (p += -1)
  s = card['oracle_text']
  unless  d.get_type_metrics(s).width < WIDTH 
      s = s.split(SEPARATOR).each_with_object('').with_index do |(word, line), index|
        tmp_line = "#{line}#{SEPARATOR}#{word}"
        line.concat(d.get_multiline_type_metrics(tmp_line).width < WIDTH ? SEPARATOR : '\n') if index != 0
        line.concat(word)
      end
  end
  h = d.get_multiline_type_metrics(s).height > HEIGHT - TEXTBOX_OFFSET[:y] - 20
end

if d.get_multiline_type_metrics(s).height < (HEIGHT - TEXTBOX_OFFSET[:y])/2
    TEXTBOX_OFFSET[:y] += (HEIGHT - TEXTBOX_OFFSET[:y])/4
end

d.annotate(i, 0,0,TEXTBOX_OFFSET[:x],TEXTBOX_OFFSET[:y],s )

# pow/toughness
d.annotate(i, 0,0,STATBOX_OFFSET[:x],STATBOX_OFFSET[:y], "#{card['power']}/#{card['toughness']}"){ |t|
  t.gravity = Magick::SouthEastGravity
  t.pointsize = 27
  t.font = 'Hack-Bold.ttf'
  t.fill = 'black'
  t.font_weight = Magick::BoldWeight
}

#art 
Down.download(card['image_uris']['art_crop'], destination: "art.jpg")
Magick::ImageList.new('art.jpg').tap do |a|
  a.resize!(WIDTH,ART_HEIGHT) 
  i.composite!(a, ART_OFFSET[:x],ART_OFFSET[:y], Magick::OverCompositeOp)
end

i.write("temp.png")
image = Escpos::Image.new "temp.png", {
  processor: "MiniMagick",
  rotate: '90',
  # ... other options, see following sections
}
@printer << image
puts @printer.to_escpos
puts "\x1d\x56\x41\x03" #cut paper
