module RBC
  module Extensions
    module CurveScaleExt

      # @since 8.0.0
      def self.toggle_unified_dlg
        if @unified_dlg && @unified_dlg.visible?
          @unified_dlg.close
        else
          @unified_dlg = GUI::DialogProxy.new({
                                                 :dialog_title => LH['Unified Operation'],
                                                 :preferences_key => LH['Unified Operation'],
                                                 :scrollable => true,
                                                 :resizable => true,
                                                 :width => 550,
                                                 :height => 300,
                                                 :left => 100,
                                                 :top => 100
                                             })
          @unified_dlg.language = LH
          @unified_dlg.set_file(File.join(EXTENSION_DIR, 'unified.html'))
          @unified_dlg.ready {|dlg, params|
            hash2 = {}
            SS.to_h.each {|k, v| hash2[k] = v.to_s}
            {
                'types'.freeze => [
                    TYPE_SCALE_XYX,
                    TYPE_SCALE_X,
                    TYPE_SCALE_Y,
                    TYPE_SCALE_Z,

                    TYPE_ROTATE_X,
                    TYPE_ROTATE_Y,
                    TYPE_ROTATE_Z,

                    TYPE_MOVE_X,
                    TYPE_MOVE_Y,
                    TYPE_MOVE_Z
                ],
                'default_values'.freeze => hash2
            }
          }

          @unified_dlg.add_action_callback('cal') {|dlg, hash|
            hash2 = {
                'type'.freeze => hash['type'],
                'align'.freeze => hash['align']
            }
            if hash['type'] == TYPE_MOVE_X || hash['type'] == TYPE_MOVE_Y || hash['type'] == TYPE_MOVE_Z
              hash2['max'] = hash['max'].to_l
            elsif hash['type'] == TYPE_ROTATE_X || hash['type'] == TYPE_ROTATE_Y || hash['type'] == TYPE_ROTATE_Z
              hash2['max'] = hash['max'].to_f
            else
              hash2['max'] = hash['max'].to_f
            end
            SS.merge!(hash2)
            unified
          }
          @unified_dlg.show
          @unified_dlg.set_tool_frame
        end
      end

      # @since 8.0.0
      def self.unified
        model = Sketchup.active_model
        selection = model.selection
        ents = selection.to_a
        if ents.empty?
          GUI.warning(LH['plance select components or groups!!!'])
          return false
        end
        selection.clear
        model.start_operation(LH['Random operation'], true)
        pb = Progressbar.new(ents.length, LH['Random'])
        ents.each {|e|
          n = SS['max']
          case e
            when Sketchup::Group, Sketchup::ComponentInstance
              point = self.get_origin(e)
              case SS['type']
                when TYPE_SCALE_XYX
                  scale_instance(e, point, n, n, n)
                when TYPE_SCALE_X
                  scale_instance(e, point, n, 1, 1)
                when TYPE_SCALE_Y
                  scale_instance(e, point, 1, n, 1)
                when TYPE_SCALE_Z
                  scale_instance(e, point, 1, 1, n)
                when TYPE_MOVE_X
                  v = Geom::Vector3d.new(1, 0, 0)
                  v.length = n
                  move_instance(e, v)
                when TYPE_MOVE_Y
                  v = Geom::Vector3d.new(0, 1, 0)
                  v.length = n
                  move_instance(e, v)
                when TYPE_MOVE_Z
                  v = Geom::Vector3d.new(0, 0, 1)
                  v.length = n
                  move_instance(e, v)
                when TYPE_ROTATE_X
                  rotate_instance(e, point, n.degrees, X_AXIS)
                when TYPE_ROTATE_Y
                  rotate_instance(e, point, n.degrees, Y_AXIS)
                when TYPE_ROTATE_Z
                  rotate_instance(e, point, n.degrees, Z_AXIS)
                else
                  Console.warn("No such type found!(#{SS['type']})")
              end
            when Sketchup::ConstructionPoint
              case SS['type']
                when TYPE_SCALE_XYX
                  # scale_instance(e, point, n, n, n)
                when TYPE_SCALE_X
                  # scale_instance(e, point, n, 1, 1)
                when TYPE_SCALE_Y
                  # scale_instance(e, point, 1, n, 1)
                when TYPE_SCALE_Z
                  # scale_instance(e, point, 1, 1, n)
                when TYPE_MOVE_X
                  v = Geom::Vector3d.new(n, 0, 0)
                  e.parent.entities.transform_by_vectors([e], [v])
                when TYPE_MOVE_Y
                  v = Geom::Vector3d.new(0, n, 0)
                  e.parent.entities.transform_by_vectors([e], [v])
                when TYPE_MOVE_Z
                  v = Geom::Vector3d.new(0, 0, n)
                  e.parent.entities.transform_by_vectors([e], [v])
                when TYPE_ROTATE_X
                  # rotate_instance(e, point, n.degrees, X_AXIS)
                when TYPE_ROTATE_Y
                  # rotate_instance(e, point, n.degrees, Y_AXIS)
                when TYPE_ROTATE_Z
                  # rotate_instance(e, point, n.degrees, Z_AXIS)
                else
                  Console.warn("No such type found!(#{SS['type']})")
              end
            when Sketchup::Edge, Sketchup::Face
              # pass
            else
              # pass
          end
          pb.next
        }
        model.commit_operation
        selection.add(ents)
      end

    end # module CurveScaleExt
  end # module Extensions
end # module RBC
