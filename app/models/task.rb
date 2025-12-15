class Task < ActiveRecord::Base
  enum genre: %i[שירה פרוזה מחזות משלים מאמרים זכרונות מכתבים עיון מעורב]
  PROP_SOURCE = 131
  PROP_ORIGLANG = 132 # horrible hard-coding against production DB values!
  PROP_RASHI = 121
  PROP_INSTRUCTIONS = 61
  include ActsAsAuditable
  acts_as_auditable :name, :state, :creator_id, :editor_id, :assignee_id, :kind_id, :difficulty, :full_nikkud, :priority,
                    conversions: {
                      creator_id: proc { |v| v ? User.find_by_id(v).try(:name) : '' },
                      editor_id: proc { |v| v ? User.find_by_id(v).try(:name) : '' },
                      assignee_id: proc { |v| v ? User.find_by_id(v).try(:name) : '' },
                      kind_id: proc { |v| v ? TaskKind.find_by_id(v).try(:name) : '' },
                      difficulty: proc { |v| Task.textify_difficulty(v) },
                      priority: proc { |v| Task.textify_priority(v) },
                      task_state_id: proc { |v| v ? Task.textify_state(TaskState.find_by_id(v).try(:name)) : '' },
                      full_nikkud: proc { |v| v ? _('true') : _('false') },
                      default_title: N_('auditable|Task'),
                      attributes: proc { |a|
                        case a
                        when :name
                          _('Name')
                        when :state
                          _('State')
                        when :creator_id
                          _('Creater')
                        when :editor_id
                          _('Editor')
                        when :assignee_id
                          _('Assignee')
                        when :kind_id
                          _('Kind')
                        when :difficulty
                          _('Difficulty')
                        when :priority
                          _('Priority')
                        when :full_nikkud
                          _('Full Nikkud')
                        end
                      }
                    }

  belongs_to :creator, class_name: 'User'
  belongs_to :editor, class_name: 'User'
  belongs_to :assignee, class_name: 'User'
  belongs_to :project
  belongs_to :parent, class_name: 'Task'
  has_many   :children, class_name: 'Task', foreign_key: 'parent_id'

  has_many :task_audits, class_name: 'Audit', dependent: :destroy

  has_many :assignment_histories, dependent: :destroy
  has_and_belongs_to_many :teams, join_table: :task_teams
  has_many :task_teams, dependent: :destroy

  include CustomProperties
  has_many_custom_properties :task # task_properties

  include CommentWithReason
  include States
  include TaskNotifications

  belongs_to :kind, class_name: 'TaskKind'

  DIFFICULTIES = {
    'easy' => N_('task difficulty|easy'),
    'normal' => N_('task difficulty|normal'),
    'hard' => N_('task difficulty|hard')
  }
  PRIORITIES = {
    'first' => N_('First task of new volunteer'),
    'very_old' => N_('Very old task'),
    'expiry' => N_('Copyright expiring'),
    'permission' => N_('Given permission'),
    'completing' => N_('Completing an author')
  }

  validates :difficulty, inclusion: { in: DIFFICULTIES.keys, message: 'not included in the list' }
  # validates :priority, :inclusion => {:in => PRIORITIES.keys, :message => "not included in the list"}
  validates :creator_id, :name, :kind_id, :difficulty, presence: true
  validate :parent_task_updated

  #  attr_accessible :name, :kind_id, :priority, :difficulty, :full_nikkud, :comments_attributes, :independent, :include_images, :genre, :source, :project_id, :hours

  # belongs_to :state, :class_name => "TaskState", :foreign_key => :
  has_many :comments, -> { order('comments.task_id, comments.created_at') }
  accepts_nested_attributes_for :comments, allow_destroy: false, reject_if: proc { |c| c['message'].blank? }
  # validates_associated :comments, :on => :create

  include DefaultAttributes
  default_attribute :kind_id, TaskKind.find_by_name('typing').try(:id)
  default_attribute :difficulty, 'normal'

  has_many :documents, -> { where('documents.deleted_at IS NULL') }, dependent: :destroy

  scope :order_by_state, proc { |dir|
    joins('left join task_states on tasks.state = task_states.name').joins('left join translation_keys on translation_keys.key = task_states.value').joins('left join translation_texts on translation_keys.id = translation_texts.translation_key_id').where("translation_texts.locale = '#{FastGettext.locale}'").order("translation_texts.text #{dir}")
  }

  scope :order_by, proc { |included_assoc, property, dir| includes(included_assoc).order("#{property} #{dir}") }

  scope :order_by_updated_at, proc { |dir| order("updated_at #{dir}") }

  after_save :update_assignments_history
  @@index_name = ENV['is_staging'] == 'true' ? 'staging_task' : 'task'

  def update_assignments_history
    assignee.assignment_histories.create(task_id: id, role: 'assignee') unless assignee.blank?

    # editor.assignment_histories.create(:task_id => self.id, :role => "editor") if !editor.blank?

    # creator.assignment_histories.create(:task_id => self.id, :role => "creator") if !creator.blank?
  end

  SEARCH_INCLUDES = {
    include: %i[creator assignee editor kind documents]
  }

  TASK_LENGTH = {
    'short' => 0..9,
    'medium' => 10..45
  }
  TASK_LENGTH.default = 46..100_000

  SEARCH_KEYS = %w[state difficulty kind full_nikkud query length priority independent
                   include_images genre source invert_state project team]
  def self.filter(opts)
    return all.paginate(page: opts[:page], per_page: opts[:per_page]) if (opts.keys & SEARCH_KEYS).blank?

    search_opts = { conditions: {}, with: {} }
    unless opts[:state].blank?
      if opts[:invert_state].blank? or opts[:invert_state] == 'false'
        search_opts[:conditions][:state] = opts[:state]
      else
        states = Task.aasm.states.collect(&:name).collect(&:to_s)
        states.delete(opts[:state]) # all states except the specified one
        search_opts[:conditions][:state] = states
      end
    end
    search_opts[:conditions][:difficulty] = opts[:difficulty] unless opts[:difficulty].blank?
    search_opts[:with][:genre] = Task.genres[opts[:genre]] unless opts[:genre].blank?
    search_opts[:with][:full_nikkud] = ('true' == opts[:full_nikkud]) unless opts[:full_nikkud].blank?
    search_opts[:with][:independent] = ('true' == opts[:independent]) unless opts[:independent].blank?
    search_opts[:with][:include_images] = ('true' == opts[:include_images]) unless opts[:include_images].blank?
    search_opts[:conditions][:priority] = opts[:priority] unless opts[:priority].blank?
    search_opts[:conditions][:project] = opts[:project] unless opts[:project].blank?
    search_opts[:conditions][:teams] = opts[:team] unless opts[:team].blank?

    search_opts[:with][:documents_count] = TASK_LENGTH[opts[:length]] unless opts[:length].blank?

    # Handle ordering with proper table aliasing for user associations
    ord = 'tasks.updated_at DESC'
    user_association_alias = nil

    if opts[:order_by].present?
      # Check if we're ordering by a user-related field
      if opts[:order_by][:property] == 'users.name' && opts[:order_by][:includes].present?
        # Determine which user association we're sorting by
        user_association = opts[:order_by][:includes]
        case user_association
        when 'assignee'
          user_association_alias = 'assignee_users'
          ord = "#{user_association_alias}.name #{opts[:order_by][:dir]}"
        when 'editor'
          user_association_alias = 'editor_users'
          ord = "#{user_association_alias}.name #{opts[:order_by][:dir]}"
        when 'creator'
          user_association_alias = 'creator_users'
          ord = "#{user_association_alias}.name #{opts[:order_by][:dir]}"
        else
          ord = "#{opts[:order_by][:property]} #{opts[:order_by][:dir]}"
        end
      else
        ord = "#{opts[:order_by][:property]} #{opts[:order_by][:dir]}"
      end
    end

    if opts[:query].blank?
      joins = []
      joins << :teams if opts[:team].present?

      # Add explicit join with alias if sorting by a user association
      if user_association_alias
        user_association = opts[:order_by][:includes]
        joins << "LEFT JOIN users AS #{user_association_alias} ON tasks.#{user_association}_id = #{user_association_alias}.id"
      end

      search_opts[:conditions][:task_kinds] = { name: opts[:kind] } unless opts[:kind].blank?
      ret = self.joins(joins).includes(%i[creator assignee editor kind teams]).where(search_opts[:conditions].merge(search_opts[:with])).order(ord).paginate(
        page: opts[:page], per_page: opts[:per_page]
      )
    else
      search_opts[:conditions][:kind] = opts[:kind] unless opts[:kind].blank?
      if search_opts[:conditions][:state].class == Array
        search_opts[:conditions][:state] = search_opts[:conditions][:state].join(' | ')
      end # Sphinx doesn't handle arrays; it wants pipe-separated values
      ord.gsub!('tasks.', '') # the Sphinx config aliases tasks fields
      ord.gsub!('assignee_users.name', 'assignee')
      ord.gsub!('editor_users.name', 'editor')
      ord.gsub!('creator_users.name', 'creator')
      ret = search fixed_Riddle_escape(opts[:query]),
                   search_opts.merge(sql: SEARCH_INCLUDES).merge(order: ord, page: opts[:page],
                                                                 per_page: opts[:per_page]).merge(indices: [@@index_name])
    end
  end

  def name_with_kind
    "#{name} (#{kind.try(:name)})"
  end

  def parent_task_updated
    errors.add(:base, _('task cannot be updated')) if @parent_task_cannot_be_updated
  end

  def participant?(user)
    return false unless user

    [creator_id, editor_id, assignee_id].member?(user.id)
  end

  def assignee?(user)
    assignee && user && user.id == assignee.id
  end

  def editor?(user)
    editor && user && user.id == editor.id
  end

  def prepare_document(uploader, opts)
    doc = documents.build
    doc.file = opts.tempfile
    doc.file_file_name = opts.original_filename
    doc.user_id = uploader.id
    doc.document_type = 'maintext' # default
    doc
  end

  def files_todo
    todo = documents_by_extensions(%w[pdf jpg png jpeg])
    todo.length
  end

  def files_done
    documents.where('done' => true).length
  end

  def files_left
    files_todo - files_done
  end

  def percent_done
    total = files_todo
    return 0 if total.nil? or total == 0

    done = files_done || 0
    (files_done.to_f / files_todo * 100).round
  end

  # convenience method for custom prop
  def orig_lang
    task_properties.each do |p|
      return p.custom_value if p.property_id == PROP_ORIGLANG
    end
    ''
  end

  def legacy_source
    task_properties.each do |p|
      return p.custom_value if p.property_id == PROP_SOURCE
    end
    ''
  end

  def rashi
    task_properties.each do |p|
      return p.custom_value if p.property_id == PROP_RASHI
    end
    false
  end

  def instructions=(buf)
    tp = task_properties.where(property_id: PROP_INSTRUCTIONS).first
    if tp.nil?
      tp = CustomProperty.new(property_id: PROP_INSTRUCTIONS)
      task_properties << tp
    end
    tp.custom_value = buf
    tp.save!
  end

  def instructions
    task_properties.each do |p|
      return p.custom_value if p.property_id == PROP_INSTRUCTIONS
    end
    ''
  end

  def document_uploaders
    ret = documents.select { |d| d.text? }.collect { |d| d.user.name }
    children.each do |c|
      ret += c.document_uploaders
    end
    ret
  end

  # reach ultimate parent task, then traverse all children, gathering every uploader of a document
  def gather_all_involved
    t = self
    t = t.parent while t.parent
    t.document_uploaders.uniq
  end

  def self.textify_priority(p)
    s_(PRIORITIES[p]) if PRIORITIES[p]
  end

  def self.textify_difficulty(dif)
    s_(DIFFICULTIES[dif]) if DIFFICULTIES[dif]
  end

  def self.textify_state(state)
    s_(TaskState.find_by_name(state.to_s).value)
  end

  def possibly_related_tasks
    ret = []
    children.each { |c| ret << c }
    ret << parent unless parent.nil?
    slashpos = name.index(' /')
    unless slashpos.nil? or slashpos < 5
      possibly = Task.where('name like ?', name[0..5] + '%' + name[slashpos..-1])
      possibly.each { |t| ret << t unless t.id == id }
    end
    ret
  end

  def estimate_hours
    kindname = kind.try(:name)

    factor = case kindname
             when 'הקלדה' then 0.5
             when 'הגהה' then 0.5
             when 'עריכה טכנית' then 0.2
             when 'חיפוש ביבליוגרפי' then 1
             when 'סריקה' then 0.05
             else 0.5
             end
    (documents.count * factor + documents.count * 0.05).round
  end

  protected

  def documents_by_extensions(exts)
    ret = []
    documents.each do |f|
      pos = f.file_file_name.rindex('.')
      next if pos.nil?

      ret << f if exts.include?(f.file_file_name[pos + 1..-1])
    end
    ret
  end

  def self.fixed_Riddle_escape(s)
    # Riddle.escape was incorrectly escaping minus signs, used as 'makaf' in Hebrew concatenated words.
    # string.gsub(/[\(\)\|\-!@~\/"\/\^\$\\><&=]/) { |match| "\\#{match}" }
    ret = s.gsub(%r{[()|!@~/"/\^$\\><&=]}) { |match| "\\#{match}" }
    ret.gsub(' -', ' \\-') # allow to search for "something - something else" without escaping *every* minus used as a hyphen
  end
end
