
class Task < ActiveRecord::Base
  PROP_SOURCE = 131
  PROP_RASHI = 121
  PROP_INSTRUCTIONS = 61
  include ActsAsAuditable
  acts_as_auditable :name, :state, :creator_id, :editor_id, :assignee_id, :kind_id, :difficulty, :full_nikkud,
    :conversions => {
      :creator_id => proc { |v| v ? (User.find_by_id(v).try(:name)) : "" },
      :editor_id => proc { |v| v ? (User.find_by_id(v).try(:name)) : "" },
      :assignee_id => proc { |v| v ? (User.find_by_id(v).try(:name)) : "" },
      :kind_id => proc {|v| v ? TaskKind.find_by_id(v).try(:name) : "" },
      :difficulty => proc {|v| Task.textify_difficulty(v) },
      :task_state_id => proc {|v| v ? Task.textify_state(TaskState.find_by_id(v).try(:name)) : "" },
      :full_nikkud => proc {|v| v ? _("true") : _("false")},
      :default_title => N_("auditable|Task"),
      :attributes => proc { |a|
        case a
        when :name
          _("Name")
        when :state
          _("State")
        when :creator_id
          _("Creater")
        when :editor_id
          _("Editor")
        when :assignee_id
          _("Assignee")
        when :kind_id
          _("Kind")
        when :difficulty
          _("Difficulty")
        when :full_nikkud
          _("Full Nikkud")
        end
      }
    }

  belongs_to :creator, :class_name => "User"
  belongs_to :editor, :class_name => "User"
  belongs_to :assignee, :class_name => "User"

  belongs_to :parent, :class_name => "Task"
  has_many   :children, :class_name => "Task", :foreign_key => "parent_id"

  has_many :task_audits, :class_name => "Audit", :dependent => :destroy

  has_many :assignment_histories, :dependent => :destroy

  include CustomProperties
  has_many_custom_properties :task # task_properties

  include CommentWithReason
  include Task::States
  include Task::Notifications

  belongs_to :kind, :class_name => 'TaskKind'

  DIFFICULTIES = {
    "easy" => N_("task difficulty|easy"),
    "normal" => N_("task difficulty|normal"),
    "hard" => N_("task difficulty|hard")
  }
  validates :difficulty, :inclusion => {:in => DIFFICULTIES.keys, :message => "not included in the list"}
  validates :creator_id, :name, :kind_id, :difficulty, :presence => true
  validate :parent_task_updated

  attr_accessible :name, :kind_id, :difficulty, :full_nikkud, :comments_attributes

  #belongs_to :state, :class_name => "TaskState", :foreign_key => :
  has_many :comments, :order => "comments.task_id, comments.created_at"
  accepts_nested_attributes_for :comments, :allow_destroy => false, :reject_if => proc {|c| c["message"].blank?}
  # validates_associated :comments, :on => :create

  include DefaultAttributes
  default_attribute :kind_id, TaskKind.find_by_name("typing").try(:id)
  default_attribute :difficulty, "normal"

  has_many :documents, :dependent => :destroy, :conditions => "documents.deleted_at IS NULL"

  scope :order_by_state, proc { |dir|
    joins("left join task_states on tasks.state = task_states.name").joins("left join translation_keys on translation_keys.key = task_states.value").joins("left join translation_texts on translation_keys.id = translation_texts.translation_key_id").where("translation_texts.locale = '#{FastGettext.locale}'").order("translation_texts.text #{dir}")
  }

  scope :order_by, proc { |included_assoc, property, dir| includes(included_assoc).order("#{property} #{dir}") }

  after_save :update_assignments_history
  def update_assignments_history    
    assignee.assignment_histories.create(:task_id => self.id, :role => "assignee") if assignee_id_changed? && !assignee.blank?

    editor.assignment_histories.create(:task_id => self.id, :role => "editor") if editor_id_changed? && !editor.blank?

    creator.assignment_histories.create(:task_id => self.id, :role => "creator") if creator_id_changed? && !creator.blank?
  end

  define_index do
    indexes :name, :sortable => true
    has :created_at
    has :updated_at
    has :full_nikkud, :type => :boolean
    indexes :difficulty, :sortable => true
    indexes kind.name, :sortable => true, :as => :kind
    indexes :state, :sortable => true
    has :documents_count, :type => :integer
  end

  SEARCH_INCLUDES = {
    :include => [:creator, :assignee, :editor, :kind]
  }

  TASK_LENGTH = {
    "short" => 0..7,
    "medium" => 8..24,
  }
  TASK_LENGTH.default = 25..100000

  SEARCH_KEYS = ["state", "difficulty", "kind", "full_nikkud", "query", "length"]
  def self.filter(opts)
    return self.all.paginate(:page => opts[:page], :per_page => opts[:per_page]) if (opts.keys & SEARCH_KEYS).blank?
    search_opts = {:conditions => {}, :with => {}}
    unless opts[:state].blank?
      if opts[:invert_state].blank? or opts[:invert_state] == "false"
        puts "DEBUG: no invert_state" # TODO
        search_opts[:conditions][:state] = opts[:state] 
      else
        puts "DEBUG: invert_state is #{opts[:invert_state]}" # TODO
        states = Task.aasm_states.collect(&:name).collect(&:to_s)
        states.delete(opts[:state]) # all states except the specified one
        search_opts[:conditions][:state] = states
        puts "DEBUG: search_opts[:conditions][:state] = #{search_opts[:conditions][:state].to_s}"
      end
    end
    search_opts[:conditions][:difficulty] = opts[:difficulty] unless opts[:difficulty].blank?
    search_opts[:with][:full_nikkud] = ("true" == opts[:full_nikkud]) unless opts[:full_nikkud].blank?
    search_opts[:with][:documents_count] = TASK_LENGTH[opts[:length]] unless opts[:length].blank?
    if opts[:query].blank?
      search_opts[:conditions][:task_kinds] = {:name => opts[:kind]} unless opts[:kind].blank?
      ret = self.find(:all, SEARCH_INCLUDES.merge(:order => "tasks.updated_at DESC").merge(:conditions => search_opts[:conditions].merge(search_opts[:with]))).paginate(:page => opts[:page], :per_page => opts[:per_page])
    else
      search_opts[:conditions][:kind] = opts[:kind] unless opts[:kind].blank?
      ret = self.search fixed_Riddle_escape(opts[:query]), search_opts.merge(SEARCH_INCLUDES).merge(:order => :updated_at, :sort_mode => :desc, :page => opts[:page], :per_page => opts[:per_page])
    end
  end

  def parent_task_updated
    errors.add(:base, _("task cannot be updated")) if @parent_task_cannot_be_updated
  end

  def participant?(user)
    return false unless user
    [creator_id, editor_id, assignee_id].member?(user.id)
  end

  def assignee?(user)
    return assignee && user && user.id == assignee.id
  end

  def editor?(user)
    return editor && user && user.id == editor.id
  end

  def prepare_document(uploader, opts)
    doc = self.documents.build(opts)
    doc.user_id = uploader.id
    doc
  end
  
  def files_todo
    todo = self.documents_by_extensions(['pdf', 'jpg'])
    return todo.length
  end
  def files_done
    self.documents.where("done" => true).length
  end
  def files_left
    return files_todo - files_done
  end
  def percent_done
    total = files_todo
    return 0 if total.nil? or total == 0
    done = files_done || 0
    return (files_done.to_f / files_todo * 100).round
  end
  # convenience method for custom prop
  def source
    self.task_properties.each {|p|
      return p.custom_value if p.property_id == PROP_SOURCE
    }
    return ""
  end
  def rashi
    self.task_properties.each{|p|
      return p.custom_value if p.property_id == PROP_RASHI
    }
    return ""
  end
  def instructions
    self.task_properties.each{|p|
      return p.custom_value if p.property_id == PROP_INSTRUCTIONS
    }
    return ""
  end
  def self.textify_difficulty(dif)
    s_(DIFFICULTIES[dif]) if DIFFICULTIES[dif]
  end

  def self.textify_state(state)
    s_(TaskState.find_by_name(state.to_s).value)
  end
  protected
  def documents_by_extensions(exts)
    ret = []
    self.documents.each { |f|
      pos = f.file_file_name.rindex('.')
      next if pos.nil?
      ret << f if exts.include?(f.file_file_name[pos+1..-1])
    }
    return ret
  end
  def self.fixed_Riddle_escape(s)
    # Riddle.escape was incorrectly escaping minus signs, used as 'makaf' in Hebrew concatenated words.
    #string.gsub(/[\(\)\|\-!@~\/"\/\^\$\\><&=]/) { |match| "\\#{match}" }
    s.gsub(/[\(\)\|!@~\/"\/\^\$\\><&=]/) { |match| "\\#{match}" }
  end
end
