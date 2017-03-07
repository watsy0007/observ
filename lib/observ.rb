require "observ/version"
module Observ
  module DSL
    def subscribe(event, on: :receive)
      return ObServ.register self, event, on: on, &Proc.new if block_given?
      ObServ.register self, event, on: on
    end

    def publish(event, *args)
      # ObServ.publish event, *args
      ObServ.config[:publish].call(event, *args)
    end
  end

  module_function
  attr_accessor :notifies

  def config
    @config ||= {
      publish: ObServ.method(:publish)
    }
  end

  def register(obj, event, on: :receive)
    @notifies ||= {}
    block = block_given? ? Proc.new : nil
    @notifies[event] ||= {}
    @notifies[event][obj.__id__] = [obj, on, block]
  end

  def publish(event, *args)
    @notifies[event]&.each do |_, (obj, m, blk)|
      next blk.call(*args) if blk
      if obj.respond_to?(m) && obj.respond_to?(:name) && obj.to_s == obj.name
        next obj.send m, *args if obj.respond_to? m
      end
      obj.send m, *args if obj.respond_to? m
      obj.send event, *args if obj.respond_to? event
    end
  end
end
