module LDtk
  class LDtkBridge
    attr_reader :levels, :tileset
    def initialize file_name
      @ldtk_file = $gtk.parse_json_file(file_name)
      tSet = @ldtk_file["defs"]["tilesets"][0]

      # Tileset information
      @tileset = {
        :width => tSet["pxWid"],
        :height => tSet["pxHei"],
        :cell_size => tSet["tileGridSize"]
    }

      # Levels data generation
      # All data must be adapted with DragonRuby coordinate system
      @levels = @ldtk_file["levels"].map do |level|
        level_name = level["identifier"].to_sym


        level_data = level["layerInstances"].map do |layer|

          # common layer data
          cell_width = layer["__cWid"],
          cell_height = layer["__cHei"],
          cell_size = layer["__gridSize"],
          layer_data = []
          layer_type = :none

          case layer["__type"]
          when "Tiles"
            layer_type = :tiles
            layer_data = layer["gridTiles"].map do |tile|
              sx = tile["src"][0]
              sy = @tileset[:height] - tile["src"][1] - @tileset[:cell_size]
              x = tile["px"][0]
              y = cell_height * cell_size - tile["px"][1] - cell_size


              {x: x, y: y, sx: sx, sy: sy, w: @tileset[:cell_size], h: @tileset[:cell_size]}
            end
          when "Entities"
            layer_type = :entities
            layer_data = layer["entityInstances"].map do |ent|
              pos_x = ent["px"][0]
              pos_y = cell_height * cell_size - ent["px"][1] - cell_size
              name = ent["__identifier"].to_sym


              sx = ent["__tile"]["srcRect"][0]
              sy = @tileset[:height] - ent["__tile"]["srcRect"][1] - @tileset[:cell_size]
              sw = ent["__tile"]["srcRect"][2]
              sh = ent["__tile"]["srcRect"][3]

              fields = Hash.new
              ent["fieldInstances"].each do |f|
                field_name = f["__identifier"].to_sym
                field_value = nil
                # Some adaptation for specific field type

                ## For Array of Point
                if f["__type"] == "Array<Point>"
                  field_value = f["__value"].map do |point|
                    {
                      cx: point["cx"],
                      cy: cell_height - 1 - point["cy"]
                    }
                  end

                ## For Point
                elsif f["__type"] == "Point"
                  if f["__value"]
                    field_value = {
                      cx: f["__value"]["cx"],
                      cy: cell_height - 1 - f["__value"]["cy"]
                    }
                  end
                else
                  field_value = f["__value"]
                end
                fields[field_name] = field_value
              end
              {
                :name => name,
                :pos => {x: pos_x, y: pos_y},
                :source_rect => [sx, sy, sw,sh],
                :fields => fields,                # Fields are Hash
              }

            end


          when "IntGrid"
            layer_type = :intGrid
            layer_data = Array.new(layer["intGridCsv"].length)
            layer["intGridCsv"].each_with_index do |v, i|
              x = i % layer["__cWid"]
              y = cell_height - 1 - i.div(layer["__cHei"])
              layer_data[x + y * layer["__cWid"]] = v
      
            end
            layer_data
          end
          Layer.new(
            layer_type,
            layer["__identifier"].to_sym,
            layer["__cWid"],
            cell_height,
            cell_size, 
            layer_data

          )

        end
        Level.new(
          level_name,
          level["pxWid"],
          level["pxHei"],
          level["worldX"],
          level["worldY"],
          level_data
          )

      end
    end

    def get_level name
      # Return the first (and unique level) with the good name
      @levels.select{|level| level.name == name}[0]
    end
  end

  class Level
    attr_reader :name, :width, :height, :x_world, :y_world, :level_data
    def initialize name, w, h, x, y, data
      @name = name
      @width = w
      @height = h 
      @x_world = x 
      @y_world = y 
      @level_data = data
    end

    def get_layer name
      @level_data.select{|layer| layer.name == name}[0]

    end
  end

  class Layer
    attr_accessor :name,
                  :cell_width, 
                  :cell_height, 
                  :cell_size, 
                  :layer_data
    def initialize l_type, name, cw,ch, size, data
      @type = l_type
      @name = name
      @cell_width = cw 
      @cell_height = ch 
      @cell_size = size
      @layer_data = data
    end

    def get_all entity_type
      if @type == :entities
        layer_data.select{|element| element[:name] == entity_type}
      else
        []
      end
    end

    def get_int x, y
      if @type == :intGrid
        @layer_data[x + y * @cell_width]
      else
        nil
      end
    end
  end
end

