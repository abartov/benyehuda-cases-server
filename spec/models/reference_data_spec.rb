require 'rails_helper'

# Guards the reference data seeded from db/seeds/reference_data.rb. These are the
# checks that would have caught the two defects this data was extracted to fix:
# a task state declared in the model but missing from the table, and a property
# id drifting away from the constant that hardcodes it.
RSpec.describe 'Reference data', type: :model do
  describe 'task states' do
    it 'has a row for every state the model declares' do
      declared = Task.aasm.states.map { |state| state.name.to_s }

      expect(TaskState.pluck(:name)).to match_array(declared)
    end

    it 'lets Task.textify_state render every state without blowing up' do
      Task.aasm.states.map { |state| state.name.to_s }.each do |state|
        expect { Task.textify_state(state) }.not_to raise_error
      end
    end
  end

  describe 'properties' do
    it 'keeps the volunteer-preferences property at the id User hardcodes' do
      property = Property.find_by(id: User::PROP_VOL_PREFERENCES)

      expect(property).to be_present
      expect(property.parent_type).to eq('Volunteer')
      expect(property.property_type).to eq('text')
    end

    it 'only uses parent types the model recognises' do
      expect(Property.distinct.pluck(:parent_type) - Property::PARENTS).to be_empty
    end

    it 'only uses property types the model recognises' do
      expect(Property.distinct.pluck(:property_type) - Property::TYPES).to be_empty
    end
  end

  describe 'volunteer kinds' do
    it 'is populated, so the kind dropdowns are not empty' do
      expect(VolunteerKind.count).to be_positive
    end
  end
end
