module RBC
  module Extensions
    module CurveScaleExt

      # 显示／隐藏曲线干扰对话框
      #
      # @since 5.0
      def self.toggle_cs_dlg
        if @dlg && @dlg.visible?
          @dlg.close
        else
          @dlg = GUI::DialogProxy.new({
                                          :dialog_title => LH[NAME],
                                          :preferences_key => "#{NAME}_dlg",
                                          :scrollable => true,
                                          :resizable => true,
                                          :width => 550,
                                          :height => 500,
                                          :left => 100,
                                          :top => 100
                                      })
          @dlg.language = (LH)
          @dlg.set_file(File.join(EXTENSION_DIR, 'curve_scale.html'))

          @dlg.ready {|dlg, params|
            hash2 = {}
            SS.to_h.each {|k, v|
              hash2[k] = v.to_s
            }
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

          @dlg.add_action_callback('getRD') {|dlg, hash|
            model = Sketchup.active_model
            selection = model.selection
            if selection.empty?
              c_max = model.bounds.diagonal / 2
            else
              c_max = Geom3d.cal_bounds(model.selection).diagonal / 2
            end
            Locale.to_length(c_max).to_s
          }

          @dlg.add_action_callback('cal') {|dlg, hash|
            hash2 = {
                'type'.freeze => hash['type'],
                'c_max'.freeze => Locale.to_l(hash['c_max']),
                'c_min'.freeze => Locale.to_l(hash['c_min']),
                #
                'align'.freeze => hash['align'],
                'control_mode'.freeze => hash['control_mode']
            }
            if hash['type'] == TYPE_MOVE_X || hash['type'] == TYPE_MOVE_Y || hash['type'] == TYPE_MOVE_Z
              hash2['max'] = Locale.to_l(hash['max'])
              hash2['min'] = Locale.to_l(hash['min'])
            elsif hash['type'] == TYPE_ROTATE_X || hash['type'] == TYPE_ROTATE_Y || hash['type'] == TYPE_ROTATE_Z
              hash2['max'] = hash['max'].to_f
              hash2['min'] = hash['min'].to_f
            else
              hash2['max'] = hash['max'].to_f
              hash2['min'] = hash['min'].to_f
            end
            SS.merge!(hash2)
            cal
          }

          @dlg.show
          @dlg.set_tool_frame
        end
      end

      # @return [nil]
      # @since 5.0
      def self.cal
        model = Sketchup.active_model
        selection = model.selection
        vertices = []
        selection.grep(Sketchup::Edge) {|edge|
          vertices += edge.vertices
        }
        vertices.compact!
        pts = vertices.map {|v| v.position}
        selection.grep(Sketchup::ConstructionPoint).each {|cp| pts << cp.position}
        instances = Container.grouponents(selection).to_a
        if instances.empty?
          GUI.warning(LH['plance select components or groups!!!'])
          return
        end
        if pts.empty?
          GUI.warning(LH['plance select edges cpoints or curves!!!'])
          return
        end
        pts_cache = {}
        distance_cache = {}
        bounds_cache = {}
        instances.map {|g|
          bb = g.bounds
          bounds_cache[g] = bb
          pt = pts.sort_by {|pt| bb.center.distance(pt)}.first
          pts_cache[g] = pt
          distance_cache[g] = bb.center.distance(pt)
        }
        pb = Progressbar.new(pts_cache.length, LH['Curve Scale'])
        model.start_operation(LH['Curve Scale'], true)
        pts_cache.each {|g, pt|
          n = self.get_numeric(distance_cache[g])
          next unless (n)
          point = self.get_origin(g)
          case SS['type']
            when TYPE_SCALE_XYX
              scale_instance(g, point, n, n, n)
            when TYPE_SCALE_X
              scale_instance(g, point, n, 1, 1)
            when TYPE_SCALE_Y
              scale_instance(g, point, 1, n, 1)
            when TYPE_SCALE_Z
              scale_instance(g, point, 1, 1, n)
            when TYPE_MOVE_X
              v = Geom::Vector3d.new(1, 0, 0)
              v.length = n
              move_instance(g, v)
            when TYPE_MOVE_Y
              v = Geom::Vector3d.new(0, 1, 0)
              v.length = n
              move_instance(g, v)
            when TYPE_MOVE_Z
              v = Geom::Vector3d.new(0, 0, 1)
              v.length = n
              move_instance(g, v)
            when TYPE_ROTATE_X
              rotate_instance(g, point, n.degrees, X_AXIS)
            when TYPE_ROTATE_Y
              rotate_instance(g, point, n.degrees, Y_AXIS)
            when TYPE_ROTATE_Z
              rotate_instance(g, point, n.degrees, Z_AXIS)
            else
              Console.warn("No such type found!(#{SS['type']})")
          end
          pb.next
        }
        model.commit_operation
      end

      # @param [Length] l
      # @return [Numeric]
      # @since 5.0.0
      def self.get_numeric(l)
        max = SS['max']
        min = SS['min']
        if SS['control_mode'] == DEF_FAR
          s = l / SS['c_max']
        else
          s = (SS['c_max'] - l) / SS['c_max']
        end
        rx = s.abs * (max - min).abs
        h = self.get_math_value(rx)
        (h + min).abs
      end

      # @param [Numeric] x
      # @param [String, nil] fun_type
      # @return [Numeric]
      # @since 5.0.0
      def self.get_math_value(x, fun_type = nil)
        math = x
        math.abs
      end

      # 获取参考点
      # @param [Sketchup::ComponentInstance, Sketchup::Group] instance
      # @return [Geom::Point3d, false]
      # @since 5.0.0
      def self.get_origin(instance)
        case SS['align']
          when ALIGN_AXIS_ORIGIN
            return ORIGIN
          when ALIGN_LOCAL_AXIS_ORIGIN
            return instance.transformation.origin
          else
            Console.warn("No such type found!(#{SS['align']})")
        end
        if Grouponent.is?(instance)
          behavior = instance.definition.behavior
          if behavior.always_face_camera?
            face_me = true
            instance.definition.behavior.always_face_camera = false
          else
            face_me = false
          end
        else
          face_me = false
        end
        case SS['align']
          when ALIGN_CENTER
            point = instance.bounds.center
          when ALIGN_BOTTOM_CENTER
            point = Geom3d.bb_corner_point(instance.bounds, BB_CENTER_CENTER_BOTTOM)
          else
            Console.warn("No such type found!(#{SS['align']})")
            return false
        end
        instance.definition.behavior.always_face_camera = true if face_me
        point
      end

      # 缩放组件／群组
      # @param [Sketchup::ComponentInstance, Sketchup::Group] instance
      # @param [Geom::Point3d] point
      # @param [Numeric] x_scale
      # @param [Numeric] y_scale
      # @param [Numeric] z_scale
      # @return [Boolean]
      # @since 5.0.0
      def self.scale_instance(instance, point, x_scale, y_scale, z_scale)
        tr = Geom::Transformation.scaling(point, x_scale, y_scale, z_scale)
        instance.transform!(tr)
        tr
      end

      # 旋转组件／群组
      # @param [Sketchup::ComponentInstance, Sketchup::Group] instance
      # @param [Geom::Point3d] point
      # @param [Numeric] deg
      # @param [Symbol] type(:x :y :z)
      # @return [Boolean]
      # @since 5.0.0
      def self.rotate_instance(instance, point, deg, vector)
        t = Geom::Transformation.rotation point, vector, deg
        instance.transform!(t)
        t
      end

      # 移动组件／群组
      # @param [Sketchup::ComponentInstance, Sketchup::Group] instance
      # @param [Geom::Vector3d] vector
      # @return [Boolean]
      # @since 5.0.0
      def self.move_instance(instance, vector)
        t = Geom::Transformation.translation(vector)
        instance.transform!(t)
        t
      end

    end # module CurveScaleExt
  end # module Extensions
end # module RBC
