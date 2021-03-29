require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer'
module RemoteLinkPaginationHelper
  #class LinkRenderer < WillPaginate::ActionView::LinkRenderer
  class LinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
    def link(text, target, attributes = {})
      attributes['data-remote'] = true
      super
    end
  end
end
