module Octopus
  class RelationProxy < BasicObject
    include ::Octopus::ShardTracking::Attribute

    module CaseFixer
      def ===(other)
        other = other.ar_relation while ::Octopus::RelationProxy === other
        super
      end
    end

    attr_accessor :ar_relation

    def initialize(shard, ar_relation)
      @current_shard = shard
      @ar_relation = ar_relation
    end

    def respond_to?(*args)
      method_missing(:respond_to?, *args)
    end

    def method_missing(method, *args, &block)
      super if @ar_relation.private_methods.include?(method)
      if block
        @ar_relation.send(method, *args, &block)
      else
        run_on_shard { @ar_relation.send(method, *args) }
      end
    end

    def ==(other)
      case other
      when ::Octopus::RelationProxy
        method_missing(:==, other.ar_relation)
      else
        method_missing(:==, other)
      end
    end
    alias_method :eql?, :==
  end
end

ActiveRecord::Relation.extend(Octopus::RelationProxy::CaseFixer)
