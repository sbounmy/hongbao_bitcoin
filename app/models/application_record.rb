class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # By default, make all attributes searchable
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  # By default, make all associations searchable
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s } + _ransackers.keys
  end
end
