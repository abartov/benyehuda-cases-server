module CommentsHelper
  def class_for_comment(comment)
    [].tap do |res|
      res << "editor_eyes_only" if comment.editor_eyes_only?
      res << "rejection_reason" if comment.is_rejection_reason?
      res << "abandoning_reason" if comment.is_abandoning_reason?
      res << "finished_reason" if comment.is_finished_reason?
    end.join(" ")
  end
end
