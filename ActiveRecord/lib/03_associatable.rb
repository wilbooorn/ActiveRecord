require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @primary_key = options[:primary_key]
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key ||= :id
    @foreign_key ||= "#{name}_id".to_sym
    @class_name ||= name.to_s.capitalize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @primary_key = options[:primary_key]
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key ||= :id
    @foreign_key ||= "#{self_class_name}_id".downcase.to_sym
    @class_name ||= name.to_s.capitalize.singularize
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      foreign_key = self.attributes["#{options.foreign_key}".to_sym]
      mclass = options.model_class
      mclass.where(id: foreign_key).first
    end
    self.assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    define_method("#{name}") do
      primary_key = self.attributes[:id]
      mclass = options.model_class
      mclass.where(options.foreign_key => primary_key)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
