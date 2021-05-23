class Project < ActiveRecord::Base
  enum status: %i(פעיל הסתיים)
end
