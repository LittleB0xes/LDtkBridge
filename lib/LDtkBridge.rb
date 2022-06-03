module LDtk
  class LDtkBridge
    attr_reader :levels,
                :tileset,
                :tilesets

    def initialize(folder, file_name)

      @ldtk_file = $gtk.parse_json_file(folder+file_name)
      @folder = folder
      tSet = @ldtk_file["defs"]["tilesets"][0]
      @tilesets = {}
      @ldtk_file["defs"]["tilesets"].each do |tileset|
        @tilesets[tileset["uid"]]= {
          :width => tileset["pxWid"],
          :height => tileset["pxHei"],
          :cell_size => tileset["tileGridSize"],
          :identifier => tileset["identifier"].to_sym,
          :rel_path => tileset["relPath"]
        }
      end
      # Tileset information
      # @tileset = {
      #   :width => tSet["pxWid"],
      #   :height => tSet["pxHei"],
      #   :cell_size => tSet["tileGridSize"]
      # }

      # Levels data generation
      # All data must be adapted with DragonRuby coordinate system
      @levels = @ldtk_file["levels"].map do |level|
        level_name = level["identifier"].to_sym


        level_data = level["layerInstances"].map do |layer|

          # common layer data
          cell_width = layer["__cWid"]
          cell_height = layer["__cHei"]
          cell_size = layer["__gridSize"]
          layer_data = Array.new()
          layer_type = :none
          tileset_id = nil
          tileset_path = nil

          case layer["__type"]
          when "Tiles"
            layer_type = :tiles
            tileset_id = layer["__tilesetDefUid"]
            tileset_path = @tilesets[tileset_id][:rel_path]
            #tileset_path = tileset_path[2, tileset_path.length]
            tileset = @tilesets[tileset_id]
            layer_data = layer["gridTiles"].map do |tile|
              sx = tile["src"][0]
              sy = tileset[:height] - tile["src"][1] - tileset[:cell_size]
              x = tile["px"][0]
              y = cell_height * cell_size - tile["px"][1] - cell_size
              f = tile["f"]
              v_flip = false
              h_flip = false
              case f
              when 0
                v_flip = false
                h_flip = false
              when 1
                v_flip = false
                h_flip = true
              when 2
                v_flip = true
                h_flip = false
              when 3
                v_flip = true
                h_flip = true
              end





              {x: x, y: y, sx: sx, sy: sy, w: tileset[:cell_size], h: tileset[:cell_size], f: f, flip_vertically: v_flip, flip_horizontally: h_flip}
            end
          when "Entities"
            layer_type = :entities
            layer_data = layer["entityInstances"].map do |ent|

              tileset_path = ""
              
              pivot_x = ent["__pivot"][0]
              pivot_y = ent["__pivot"][1]

              width = ent["width"]
              height = ent["height"]
              pos_x = ent["px"][0] - pivot_x * width
              pos_y = cell_height * cell_size - ent["px"][1] - (1 - pivot_y) * height#cell_size
              
              name = ent["__identifier"].to_sym


              #  Check if tile exist for this entity
              if ent["__tile"]

                #Tileset Id is usefull if we use tile to represent an entitie
                tileset_id = ent["__tile"]["tilesetUid"]

                # DragonRuby friendly path of the tileset
                tileset_path = @folder + @tilesets[tileset_id][:rel_path]

                # Enttitie sprite position in tileset
                sx = ent["__tile"]["x"]

                # ... and we need to change y position to be DragonRuby friendly
                sy = @tilesets[tileset_id][:height] - ent["__tile"]["y"] - ent["__tile"]["h"]
                
                sw = ent["__tile"]["w"]
                sh = ent["__tile"]["h"]
              end

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
                :pivot => {x: pivot_x, y: 1 - pivot_y},
                :size => {w: width, h: height},
                :source_rect => {source_x: sx, source_y: sy, source_w: sw, source_h: sh, path: tileset_path },
                :fields => fields,                # Fields are Hash
              }

            end


          when "IntGrid"
            layer_type = :intGrid
            layer_data = Array.new(layer["intGridCsv"].length)
            layer["intGridCsv"].each_with_index do |v, i|
              x = i % layer["__cWid"]
              #y = cell_height - 1 - i.div(layer["__cHei"])
              y = i.div(layer["__cWid"])

              layer_data[x + (cell_height - 1 - y) * layer["__cWid"]] = v
      
            end
            layer_data
          end
          Layer.new(
            tileset_id,
            @folder,
            tileset_path,
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
      @levels.select{|level| level.name == name}[0]
    end

    def serialize
      {tileset: @tileset, levels: @levels}
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
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
    def serialize
      {width: @width, height: @height, x: @x_world, y: @y_world, level_data: @level_data}
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
    end
  end

  class Layer
    attr_accessor :name,
                  :cell_width,
                  :cell_height,
                  :cell_size,
                  :layer_data,
                  :tileset_id,
                  :tileset_path
    def initialize tileset_id, folder, path, l_type, name, cw,ch, size, data
      @tileset_id = tileset_id

      @folder = folder
      # Relative path of the tileset
      @tileset_path = path

      @type = l_type
      @name = name
      @cell_width = cw 
      @cell_height = ch 
      @cell_size = size
      @layer_data = data
    end

    def get_tileset_path
      @tileset_path
    end
      

    def get_all entity_type
      if @type == :entities
        @layer_data.select{|element| element[:name] == entity_type}
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

    # get_all_scaled_tiles generate a DragonRuby hash sprite array which
    # can be use directly in outputs.sprites or outputs.static_sprite
    # arguments :
    # scale to scale the tile
    # dx and dy for an optional camera translation
    def render(scale=1, dx=0, dy=0)
      return unless @type == :tiles
      @layer_data.map do |tile|
        {
          x: (tile.x - dx) * scale,
          y: (tile.y - dy) * scale,
          w: tile.w * scale,
          h: tile.h * scale,
          source_x: tile.sx,
          source_y: tile.sy,
          source_w: tile.w,
          source_h: tile.h,
          path: @folder + @tileset_path,
          flip_horizontally: tile.flip_horizontally,
          flip_vertically: tile.flip_vertically,
        }
      end

    end



    def serialize
      {}
    end

    def inspect
      serialize.to_s
    end

    def to_s
      serialize.to_s
    end
  end
end

