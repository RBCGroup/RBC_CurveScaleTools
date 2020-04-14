module RBC
  module Extensions
    module CurveScaleExt

      PluginContext = self

      # 控制类型
      DEF_NEAR = 'NEAR'.freeze # 近大远小
      DEF_FAR = 'FAR'.freeze # 近小远大

      # 对齐方式
      ALIGN_CENTER = 'CENTER'.freeze #
      ALIGN_BOTTOM_CENTER = 'BOTTOM_CENTER'.freeze #
      ALIGN_LOCAL_AXIS_ORIGIN = 'LOCAL_AXIS_ORIGIN'.freeze #
      ALIGN_AXIS_ORIGIN = 'AXIS_ORIGIN'.freeze #

      # 干扰类型
      TYPE_SCALE_XYX = 'SCALE_XYZ'.freeze
      TYPE_SCALE_X = 'SCALE_X'.freeze
      TYPE_SCALE_Y = 'SCALE_Y'.freeze
      TYPE_SCALE_Z = 'SCALE_Z'.freeze
      TYPE_ROTATE_X = 'ROTATE_X'.freeze
      TYPE_ROTATE_Y = 'ROTATE_Y'.freeze
      TYPE_ROTATE_Z = 'ROTATE_Z'.freeze
      TYPE_MOVE_X = 'MOVE_X'.freeze
      TYPE_MOVE_Y = 'MOVE_Y'.freeze
      TYPE_MOVE_Z = 'MOVE_Z'.freeze

      SS = Settings.new(NAME) {
        {
            'type'.freeze => TYPE_SCALE_XYX,
            'c_max'.freeze => 30000.mm,
            'c_min'.freeze => 10.mm,
            'max'.freeze => 3,
            'min'.freeze => 1,
            'angle'.freeze => ALIGN_CENTER,
            'control_mode'.freeze => DEF_NEAR
        }
      }

      if RBC.first_loaded_locale?

        RBC.autoload_dir(self, EXTENSION_DIR)

        menu = UI.menu(GUI::MENU_EXTENSIONS).add_submenu(LH[NAME])
        toolbar = GUI.toolbar(LH[NAME])
        path = File.join(EXTENSION_DIR, 'icon')

        cmd = GUI::Command.new(LH['Curve Scale']) { PluginContext.toggle_cs_dlg }
        cmd.icon = GUI.smart_icon(path, 'curve.png')
        cmd.description =  LH['Curve Scale']
        cmd.tip = LH['Curve Scale']
        toolbar.add_item(cmd)
        menu.add_item(cmd)

        cmd = GUI::Command.new(LH['Random operation']) { PluginContext.toggle_random_dlg }
        cmd.icon = GUI.smart_icon(path, 'random.png')
        cmd.description =  LH['Random operation']
        cmd.tip = LH['Random operation']
        toolbar.add_item(cmd)
        menu.add_item(cmd)

        cmd = GUI::Command.new(LH['Unified Operation'], "#{NAME}-Unified Operation") { PluginContext.toggle_unified_dlg }
        cmd.icon = GUI.smart_icon(path, 'unified.png')
        cmd.description =  LH['Unified Operation']
        cmd.tip = LH['Unified Operation']
        toolbar.add_item(cmd)
        menu.add_item(cmd)

        toolbar.show

      end

    rescue => exception
      Console.show_error(exception)

    end # module CurveScaleExt
  end # module Extensions
end # module RBC

