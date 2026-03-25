# encoding: utf-8
# Tests for task kind behavior using the kind_id enum on Task.
# These tests cover the same observable behavior that existed when
# kind was stored in a separate task_kinds table.
require 'rails_helper'

RSpec.describe 'Task kind behavior', type: :model do
  let(:admin) { create(:user, :admin) }

  # ── canonical enum values / IDs ───────────────────────────────────────────

  describe 'canonical kind IDs' do
    it 'הקלדה has id 1'               do expect(Task.kind_ids[:הקלדה]).to eq(1)  end
    it 'הגהה has id 21'               do expect(Task.kind_ids[:הגהה]).to eq(21) end
    it 'עריכה_טכנית has id 61'        do expect(Task.kind_ids[:עריכה_טכנית]).to eq(61) end
    it 'סריקה has id 71'              do expect(Task.kind_ids[:סריקה]).to eq(71) end
    it 'חיפוש_ביבליוגרפי has id 31'  do expect(Task.kind_ids[:חיפוש_ביבליוגרפי]).to eq(31) end
    it 'אחר has id 11'               do expect(Task.kind_ids[:אחר]).to eq(11) end
  end

  # ── all expected kinds are present ────────────────────────────────────────

  describe 'enum definition' do
    it 'defines all ten kinds' do
      expected_keys = %i[הקלדה אחר הגהה חיפוש_ביבליוגרפי גיוס_כספים
                         רשות_פרסום עריכה_טכנית סריקה חקיקה פרסים]
      expect(Task.kind_ids.keys.map(&:to_sym)).to match_array(expected_keys)
    end
  end

  # ── task.kind (backward-compat proxy) ────────────────────────────────────

  describe 'task.kind' do
    let(:task) { create(:task, kind_id: :הקלדה, creator: admin) }

    it 'returns an object with a name method' do
      expect(task.kind).not_to be_nil
    end

    it 'kind.name returns the Hebrew display name' do
      expect(task.kind.name).to eq('הקלדה')
    end

    it 'kind.try(:name) returns the kind name string' do
      expect(task.kind.try(:name)).to eq('הקלדה')
    end

    it 'kind.name reflects multi-word names correctly (underscores → spaces)' do
      task2 = create(:task, kind_id: :עריכה_טכנית, creator: admin)
      expect(task2.kind.name).to eq('עריכה טכנית')
    end

    it 'kind.name reflects הגהה' do
      task2 = create(:task, kind_id: :הגהה, creator: admin)
      expect(task2.kind.name).to eq('הגהה')
    end

    it 'returns nil when kind_id is nil' do
      task = build(:task, creator: admin, difficulty: 'normal')
      task.kind_id = nil
      expect(task.kind).to be_nil
    end
  end

  # ── task.kind_id ─────────────────────────────────────────────────────────

  describe 'task.kind_id' do
    it 'returns the enum key string for הקלדה' do
      task = build(:task, kind_id: :הקלדה, creator: admin, difficulty: 'normal')
      expect(task.kind_id).to eq('הקלדה')
    end

    it 'returns the enum key string for הגהה' do
      task = build(:task, kind_id: :הגהה, creator: admin, difficulty: 'normal')
      expect(task.kind_id).to eq('הגהה')
    end

    it 'returns the enum key string for עריכה_טכנית' do
      task = build(:task, kind_id: :עריכה_טכנית, creator: admin, difficulty: 'normal')
      expect(task.kind_id).to eq('עריכה_טכנית')
    end

    it 'persists correctly: kind_id round-trips through DB as enum string' do
      task = create(:task, kind_id: :הגהה, creator: admin)
      expect(task.reload.kind_id).to eq('הגהה')
    end
  end

  # ── enum predicate methods ────────────────────────────────────────────────

  describe 'predicate methods' do
    it 'task.הגהה? is true for a הגהה task' do
      task = create(:task, kind_id: :הגהה, creator: admin)
      expect(task.הגהה?).to be true
      expect(task.הקלדה?).to be false
    end

    it 'task.עריכה_טכנית? is true for a עריכה טכנית task' do
      task = create(:task, kind_id: :עריכה_טכנית, creator: admin)
      expect(task.עריכה_טכנית?).to be true
    end

    it 'task.סריקה? is true for a סריקה task' do
      task = create(:task, kind_id: :סריקה, creator: admin)
      expect(task.סריקה?).to be true
    end
  end

  # ── validation ────────────────────────────────────────────────────────────

  describe 'validation' do
    it 'requires kind_id to be present' do
      task = build(:task, creator: admin, difficulty: 'normal')
      task.kind_id = nil
      expect(task).not_to be_valid
      expect(task.errors[:kind_id]).not_to be_empty
    end

    it 'is valid with a known kind' do
      task = build(:task, kind_id: :הקלדה, creator: admin, difficulty: 'normal')
      expect(task).to be_valid
    end

    it 'raises ArgumentError for an unknown kind value' do
      expect { build(:task, kind_id: :bogus) }.to raise_error(ArgumentError)
    end
  end

  # ── default kind ─────────────────────────────────────────────────────────

  describe 'default kind' do
    it 'defaults to הקלדה' do
      task = Task.new
      expect(task.kind_id).to eq('הקלדה')
    end
  end

  # ── name_with_kind ────────────────────────────────────────────────────────

  describe '#name_with_kind' do
    it 'combines task name and kind display name' do
      task = create(:task, name: 'ביאליק / שירים', kind_id: :הקלדה, creator: admin)
      expect(task.name_with_kind).to eq('ביאליק / שירים (הקלדה)')
    end

    it 'renders multi-word kind names without underscores' do
      task = create(:task, name: 'ביאליק', kind_id: :עריכה_טכנית, creator: admin)
      expect(task.name_with_kind).to include('עריכה טכנית')
    end

    it 'handles a nil kind_id gracefully (no exception)' do
      task = build(:task, name: 'foo', creator: admin, difficulty: 'normal')
      task.kind_id = nil
      expect { task.name_with_kind }.not_to raise_error
    end
  end

  # ── estimate_hours ────────────────────────────────────────────────────────

  describe '#estimate_hours' do
    def task_with_doc_count(kind_key, count)
      task = create(:task, kind_id: kind_key, creator: admin)
      allow(task.documents).to receive(:count).and_return(count)
      task
    end

    it 'uses 0.5 factor for הקלדה' do
      expect(task_with_doc_count(:הקלדה, 10).estimate_hours)
        .to eq((10 * 0.5 + 10 * 0.05).round)
    end

    it 'uses 0.5 factor for הגהה' do
      expect(task_with_doc_count(:הגהה, 10).estimate_hours)
        .to eq((10 * 0.5 + 10 * 0.05).round)
    end

    it 'uses 0.2 factor for עריכה_טכנית' do
      expect(task_with_doc_count(:עריכה_טכנית, 10).estimate_hours)
        .to eq((10 * 0.2 + 10 * 0.05).round)
    end

    it 'uses 1.0 factor for חיפוש_ביבליוגרפי' do
      expect(task_with_doc_count(:חיפוש_ביבליוגרפי, 10).estimate_hours)
        .to eq((10 * 1 + 10 * 0.05).round)
    end

    it 'uses 0.05 factor for סריקה' do
      expect(task_with_doc_count(:סריקה, 10).estimate_hours)
        .to eq((10 * 0.05 + 10 * 0.05).round)
    end

    it 'uses 0.5 default factor for אחר' do
      expect(task_with_doc_count(:אחר, 10).estimate_hours)
        .to eq((10 * 0.5 + 10 * 0.05).round)
    end
  end

  # ── querying by kind ─────────────────────────────────────────────────────

  describe 'querying by kind' do
    let!(:typing_task)   { create(:task, kind_id: :הקלדה, creator: admin) }
    let!(:proofing_task) { create(:task, kind_id: :הגהה,  creator: admin) }

    it 'can filter tasks by enum key string' do
      results = Task.where(kind_id: :הקלדה)
      expect(results).to include(typing_task)
      expect(results).not_to include(proofing_task)
    end

    it 'can filter tasks by integer value' do
      results = Task.where(kind_id: 1)
      expect(results).to include(typing_task)
      expect(results).not_to include(proofing_task)
    end

    it 'can filter with an array of enum keys' do
      results = Task.where(kind_id: %i[הקלדה הגהה])
      expect(results).to include(typing_task, proofing_task)
    end
  end
end
