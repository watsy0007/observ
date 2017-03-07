require "ob_serv/version"
module ObServ
  module DSL
    def subscribe(event, options = {})
      options[:on] = event unless options.include?(:on)
      return ObServ.register self, event, options, &Proc.new if block_given?
      ObServ.register self, event, options
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

  def register(obj, event, options = {})
    @notifies ||= {}
    block = block_given? ? Proc.new : nil
    @notifies[event] ||= {}
    @notifies[event][obj.__id__] = [obj, options, block]
  end

  def publish(event, *args)
    @notifies[event]&.each do |_, (obj, opts, blk)|
      next blk.call(*args) if blk
      m = opts[:on]
      if obj.respond_to?(m) && obj.respond_to?(:name) && obj.to_s == obj.name
        next obj.send m, *args if obj.respond_to? m
      end
      obj.send m, *args if obj.respond_to? m
    end
  end
end
