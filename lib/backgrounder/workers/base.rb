# encoding: utf-8
module CarrierWave
  module Workers

    module Base
      attr_accessor :klass, :id, :column, :record

      def initialize(*args)
        super(*args) unless self.class.superclass == Object
        set_args(*args) if args.present?
      end

      def perform(*args)
        set_args(*args) if args.present?
        # 使用主库处理图片 避免抛出异常重试，速度太慢, 但是考虑到连接主库失败，增加重连次数
        current_time, retry_time = 0, 3
        begin
          current_time += 1
          need_stick && ::ActiveRecord::Base.connection.stick_to_master!
        end until (::ActiveRecord::Base.connection.instance_variable_get("@master_context").present? || (current_time == retry_time))
        self.record = constantized_resource.find id
      end
      private

      def not_found_errors
        [].tap do |errors|
          errors << ::ActiveRecord::RecordNotFound      if defined?(::ActiveRecord)
          errors << ::Mongoid::Errors::DocumentNotFound if defined?(::Mongoid)
        end
      end

      def set_args(klass, id, column)
        self.klass, self.id, self.column = klass, id, column
      end

      def constantized_resource
        klass.is_a?(String) ? klass.constantize : klass
      end

      def when_not_ready
      end

    end # Base

  end # Workers
end # CarrierWave
