module Apress
  module Images
    # Public: джоб нарезки изображений
    #
    # В случае падения срабатывает retry стратегия.
    # Периоды последующих попыток запуститься:
    # (@backoff_strategy[номер попытки] * <случайное число от 1 до @retry_delay_multiplicand_max>) в сек.
    class ProcessJob
      extend Resque::Plugins::ExponentialBackoff

      @backoff_strategy = [1.minute, 5.minutes, 15.minutes, 30.minutes]
      @retry_delay_multiplicand_max = 2.0

      def self.queue
        :images
      end

      def self.non_online_queue
        :non_online_images
      end

      def self.perform(image_id, class_name, opts = {})
        options = opts.with_indifferent_access
        model = class_name.camelize.constantize
        image = model.find_by(id: image_id)
        return unless image

        image.assign_attributes(options[:assign_attributes]) if options[:assign_attributes]
        image.img.process_delayed! if image.processing?
      end

      ActiveSupport.run_load_hooks(:'apress/images/process_job', self)
    end
  end
end
