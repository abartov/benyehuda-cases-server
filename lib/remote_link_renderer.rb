require "will_paginate"
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'
class RemoteLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
#class RemoteLinkRenderer < WillPaginate::ActionView::LinkRenderer
  def prepare(collection, options, template)
    @remote = options.delete(:remote) || {}
    super
  end

  protected

  def page_link_or_span(page, span_class, text = nil)
    text ||= page.to_s
    classnames = Array[*span_class]

    if page and page != current_page
      @template.link_to text.html_safe, url_for(page), :rel => rel_value(page), :class => classnames.join(' '), 'data-remote' => true
    else
      @template.content_tag :span, text.html_safe, :class => classnames.join(' ')
    end
  end
end
