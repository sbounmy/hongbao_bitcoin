class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Rails.logger.info("INSIDE APPLICATION RECORD"); # You can keep or remove this logger
  self.abstract_class = true

  # By default, make all attributes searchable
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  # By default, make all associations searchable
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s } + _ransackers.keys
  end
end
