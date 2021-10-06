# coding: utf-8
module Paperclip
  class Watermark < Thumbnail
    # Handles watermarking of images that are uploaded.
    attr_accessor :types_without_watermark, :watermark_path, :overlay, :position

    def initialize(file, options = {}, attachment = nil)
      super
      @types_without_watermark = options.fetch(:types_without_watermark, [])
      @watermark_path          = options[:watermark_path]
      @position                = options[:position] || "SouthEast"
      @overlay                 = options[:overlay].nil?
    end

    # TODO: extend watermark
    # Performs the conversion of the +file+ into a watermark. Returns the Tempfile
    # that contains the new image.
    def make
      src = @file
      dst = Tempfile.new([@basename, @format].compact.join('.'))
      dst.binmode

      begin
        parameters = []
        parameters << watermark_options
        parameters << ":watermark"
        parameters << source_file_options
        parameters << ":source"
        parameters << transformation_command
        parameters << convert_options
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        Paperclip.run(program, parameters,
          :source => "#{File.expand_path(src.path)}#{'[0]' unless animated?}",
          :dest => File.expand_path(dst.path),
          :watermark => if file.is_a?(Paperclip::Tempfile)
                          watermark_path
                        else
                          types_without_watermark.exclude?(file.content_type) ? watermark_path : nil
                        end
        )
      rescue Cocaine::ExitStatusError
        raise Paperclip::Error, "There was an error processing the watermark for #{@basename}" if @whiny
      rescue Cocaine::CommandNotFoundError
        raise Paperclip::CommandNotFoundError.new("Could not run the `#{program}` command. Please install ImageMagick.")
      end

      dst
    end

    def program
      file.is_a?(Paperclip::Tempfile) ? program_without_types : program_with_types
    end

    def program_without_types
      watermark_path.present? ? 'composite' : 'convert'
    end

    def program_with_types
      watermark_path.present? && types_without_watermark.exclude?(file.content_type) ? 'composite' : 'convert'
    end

    def watermark_options
      watermark_path.present? && position.present? ? ['-gravity', position] : []
    end

    def transformation_command
      @auto_orient = false if watermark_path.present?
      trans = super
      trans << '-colorspace sRGB'
      trans
    end
  end
end
