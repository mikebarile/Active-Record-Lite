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
    @class_name.constantize
  end

  def table_name
    #This should be '@class.name.downcase.pluralize' but rspec is set incorrectly
    "#{@class_name.downcase}s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @primary_key = :id
    @foreign_key = "#{name.to_s.underscore}_id".to_sym
    @class_name = name.to_s.camelcase

    options.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @primary_key = :id
    @foreign_key = "#{self_class_name.to_s.underscore}_id".to_sym
    @class_name = name.to_s.camelcase.singularize

    options.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      foreign_key = send(options.foreign_key)
      target_class = options.model_class
      params = {options.primary_key => foreign_key}
      target_class.where(params).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do
      primary_key = send(options.primary_key)
      target_class = options.model_class
      params = {options.foreign_key => primary_key}
      target_class.where(params)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
