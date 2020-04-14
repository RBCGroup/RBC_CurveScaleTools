# ------------------
# RBC
# 腾讯QQ群: 397192573
# Facebook: https://www.facebook.com/groups/RBC.Sugar
# 公众号:RBC 联盟
# RBC官网:http://www.rbc321.cn
#
# 山西云联智达网络科技有限公司
# email:932180146@qq.com
# ------------------

module RBC
  module Extensions
    module CurveScaleExt

      # check lib.
      #
      # @param [String] ext_name
      #
      # @return [Boolean]
      #
      # @since 6.3.0
      def self.check_lib?(ext_name, mv, rv, fv)
        return false if defined?(RBC::LIB_UPDATE_) && RBC::LIB_UPDATE_
        return false if Sketchup.version.to_i < 15
        unless defined?(RBC::RBC_EXTENSION)
          # require RBC library.
          begin
            require 'RBC_Library_load.rb'
          rescue LoadError => e
            p e
          end
        end
        if defined?(RBC::RBC_VERSION_)
          if RBC::RBC_VERSION_[0] < mv
             update = true
           elsif RBC::RBC_VERSION_[1] < rv
             update = true
           elsif RBC::RBC_VERSION_[2] < fv 
            update  = true
           else
             update = false
           end

        else
          update = true
        end
        # check version.
        if update
          msg = "#{ext_name}: RBC Library(#{mv}.#{rv}.#{fv}) must be installed!(必须安装使用#{mv}.#{rv}.#{fv}版本以上的RBC Library!)"
          Sketchup.status_text = msg
          UI.messagebox(msg)
          RBC.const_set(:LIB_UPDATE_ ,true)
          false
        end
        !update
      end

      NAME = 'RBC_CurveScaleTools'.freeze
      VERSION = '9.1.0'.freeze
      DIR_NAME = (NAME + '_v' + VERSION).freeze
      EXTENSION_DIR = File.join(__dir__, DIR_NAME).freeze

      if self.check_lib?(DIR_NAME, 7, 7, 61)

        LH = RBC::LanguageHandler.new(File.join(EXTENSION_DIR, 'lang'))
        LH.name= LH[NAME]

        EXTENSION = SketchupExtension.new(NAME, File.join(EXTENSION_DIR, 'core'))
        EXTENSION.description = LH[NAME]
        EXTENSION.copyright = "Copyright (c) 2015 山西云联智达网络科技有限公司 All rights reserved."
        EXTENSION.version = VERSION
        EXTENSION.creator = '山西云联智达网络科技有限公司'
        Sketchup.register_extension(EXTENSION, true)

      end

    end # module CurveScaleExt
  end # module Extensions
end # module RBC
